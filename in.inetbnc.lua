#!/usr/bin/env luajit

local os = require"os"

-- ENVIRONMENT --
local PWD=os.getenv"PWD"
local CLIENTIP=tostring(os.getenv"REMOTE_HOST" or "unknown") -- no REMOTE_HOST happens outside of inetd (called buy command line during dev)

-- workaround to load module -- FIXME: xinetd env LUA_PATH=... ?
package.path=PWD.."/?.lua;"..PWD.."/?/init.lua;"..package.path

-- LOG --
local log = require "log_system"({PWD=PWD,CLIENTIP=CLIENTIP})
package.loaded["runtime.log"] = log

-- PROTOCOLS --

local split = require "mini.string.split"
local plainsplit1 = require "plainsplit1"
local protocols = require "protocols"

-- short name --

local tconcat=table.concat
local tinsert=table.insert

-- CLIENT --

local function send(self, prefix, cmd, target, params)
	local line={}
	if prefix then
		tinsert(line, ":")
		tinsert(line, prefix)
		tinsert(line, " ")
	end
	tinsert(line,cmd)
	tinsert(line," ")
	tinsert(line, target)
	if params then
		tinsert(line," :")
		tinsert(line,params)
	end
	log.server(tconcat(line))
	print(tconcat(line))
end

local const_EXIT={}
local const_NEXT_PROTOCOL={}

local client={
	EXIT=const_EXIT,
	NEXT_PROTOCOL=const_NEXT_PROTOCOL,
	send=send,
--	state=STATES.new,	-- current state for protocol1
--	states=STATES,		-- all states of protocol1
--	protocol=...		-- current protocol handler (protocol1, protocol2, ...)
	protocols=protocols,	-- all protocols
	host="hidden.irc-client.example.net",
}
protocols[1].init(client)
assert(client.state==1)

function client:sendNOTICE (target, msg) self:send(nil,  "NOTICE", target, msg) end
function client:sendPRIVMSG(target, msg) self:send(nil, "PRIVMSG", target, msg) end
function client:console(msg)             self:sendNOTICE(self.nick, msg) end

local format=string.format
function client:nuh()
	return format("%s!~%s@%s", self.nick, self.user, self.host)
end
function client:realnuh()
	return format("%s!%s@%s", self.nick, self.user, CLIENTIP)
end


local function processline(cli, data)
	local prefix = ''
	if data:sub(1,1)==":" then
		prefix,data = painsplit1(data:sub(2), " ")
	end
	local cmd; cmd,data = plainsplit1(data, " ")
	local proto = cli.protocol
	local f = proto[cmd] or proto.unknown
	if f then
		local parsed = {
			prefix=assert(prefix),
			cmd=assert(cmd),
		}
		return f(cli, data, parsed)
	end
end

local function input_readline(fdin)
	local line=nil
	while line==nil do
		line = fdin:read("*l")
		if not line then return false end
		if line:sub(-1,-1)=="\r" then
			line=line:sub(1,-2)
		end
		if line=="\0" then
log.server("# workaround line zero")
			line=nil
		end
	end
	return line
end

local function main(client)
	local fdin = io.stdin
	while true do
		io.stdout:flush()
		local line = input_readline(fdin)
		if not line then break end
		log.client(line)
		local r = processline(client,line)
		if r == client.EXIT then break end
		if r == client.NEXT_PROTOCOL then
print("NEXT_PROTOCOL")
			client.protocol.finished(client)
			client.protocol=client.protocols[client.protocolnext]
			client.protocolnext=nil
			client.protocol.init(client)
		end
	end
end
main(client)
log.close()
