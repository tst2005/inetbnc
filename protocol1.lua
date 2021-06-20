
local log = require "runtime.log"

local split = require "mini.string.split"
local plainsplit1 = require "plainsplit1"

local STATES={
	"new",
	"CAP_LS",
	"PASS",
	"NICK",
	"USER",
	"CAP_REQ",
	"CAP_END",
	"registered",
}
for i,k in ipairs(STATES) do STATES[k]=i end

local protocol_cap = require "protocol_cap"

-- short name --

local tconcat=table.concat
local tinsert=table.insert

--[[
rfc1459: rfc2812

PASS <password>
NICK <nickname> [ <hopcount> ]
USER <username> <hostname*ign> <servername*ign> <[:]realname>

*: Note that hostname and servername are normally ignored by the IRC server

USER guest tolmoon tolsun :Ronnie Reagan
]]--


local protocol1 = {}
function protocol1.init(cli)
	cli.state=STATES.new
	cli.states=STATES
	cli.protocol=protocol1
	cli.protocolnum=1
	return cli
end

local function register(cli)
	cli:send(nil, "001", cli.nick, "Welcome to the Internet Relay Network")
	cli.protocol.finished(cli)
end

function protocol1.finished(cli)
	return cli.protocols[2].init(cli)
end
function protocol1.unkown(cli)
	log.server("# unknow command '"..cmd.."' for prefix='"..prefix.."' data='"..(data or "").."'")
end

function protocol1.CAP(cli,data)
	local cmd2,z = plainsplit1(data, " ")
	local f = protocol_cap[cmd2]
	if not f then
		-- protocol error or unsupported
		-- just drop it
	else
		f(cli, z or "")
	end
end
function protocol1.PASS(cli,data)
	assert(cli.state <= STATES.CAP_LS, "PASS protocol error")
	cli.pass = data
	cli.state=STATES.PASS
end
function protocol1.NICK(cli,data)
	assert(cli.state < STATES.NICK, "NICK protocol error")
	local nick,z = plainsplit1(data, " ")
	cli.nick = nick
	cli.state=STATES.NICK
end
function protocol1.USER(cli,data)
	assert(cli.state == STATES.NICK or cli.state == STATES.USER, "USER protocol error")
	local p = split(data, " ", true, 3)
	assert(#p<=4)
	local realname = p[4] or ""
	if realname and realname:sub(1,1)==":" then
		realname = realname:sub(2)
	end
	local arg2 = p[2]
	if arg2 == "8" then
		-- USER guest 0 * :Ronnie Reagan   ; User registering themselves with a username of "guest" and real name "Ronnie Reagan".
		-- USER guest 8 * :Ronnie Reagan   ; User registering themselves with a username of "guest" and real name "Ronnie Reagan", and asking to be set invisible.
		cli.user_want_invisible = true
	end
	cli.user = p[1]
	cli.realname = realname
	cli.state=STATES.USER
--	if cli.capls==false then -- non CAP client
	return register(cli)
--	end
end

function protocol1.PING(cli,data)
	cli:send(nil, "PONG", tostring(data))
end
function protocol1.PONG(cli,data) end
function protocol1.QUIT(cli,data)
	if not data then
		data=""
	else
		if data:sub(1,1)==":" then
			data=data:sub(2)
		else
			local params
			params,data = plainsplit1(data, " :")
		end
	end
	log.server("# he quit with reason:"..data)
	return cli.EXIT
end

return protocol1
