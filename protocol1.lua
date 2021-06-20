
local log = require "runtime.log"

local split = require "mini.string.split"
local plainsplit1 = require "plainsplit1"

local STATES={
	"new",
	"CAP_PRE_USER", -- mainly: CAP LS
	"PASS",
	"NICK",
	"USER",
	"CAP_POST_USER", -- full CAP negociation (LS/REQ/ACK/NAK/NEW/DEL/END)
	"registered",
}
for i,k in ipairs(STATES) do STATES[k]=i end

local protocol_cap = require "protocol_cap"
assert(protocol_cap.pre_user)
assert(protocol_cap.post_user)

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
	cli.state=assert(STATES.new)
	cli.states=STATES
	cli.protocol=protocol1
	cli.protocolnum=1
	--cli.protocolnext=2
	return cli
end

function protocol1.finished(cli)
	cli:send(nil, "001", cli.nick, "Welcome to the Internet Relay Network")
	cli.protocolnext=2
end
function protocol1.unkown(cli)
	log.server("# unknow command '"..cmd.."' for prefix='"..prefix.."' data='"..(data or "").."'")
end

function protocol1.CAP(cli,data, parsed)
	assert(cli.state <= STATES.CAP_PRE_USER or cli.state == STATES.CAP_POST_USER)
	local cmd2
	cmd2,data = plainsplit1(data, " ")
	parsed.cmd2 = cmd

	local f
	if cli.state <= STATES.CAP_PRE_USER then
		assert(protocol_cap.pre_user.unknown)
		f = protocol_cap.pre_user[cmd2] or protocol_cap.pre_user.unknown
	elseif cli.state == STATES.CAP_POST_USER then
		assert(protocol_cap.post_user.unknown)
		f = protocol_cap.post_user[cmd2] or protocol_cap.post_user.unknown
	end
	if f then
		f(cli, data or "", parsed)
	end
end
function protocol1.PASS(cli,data, parsed)
	assert(cli.state <= STATES.CAP_PRE_USER, "PASS protocol error")
	cli.pass = data
	cli.state=STATES.PASS
end
function protocol1.NICK(cli,data)
	print(cli.state)
	print(STATES.NICK)
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
	elseif arg2 == "0" then
		cli.user_want_invisible = false
	end
	cli.user = p[1]
	cli.realname = realname
	cli.state=STATES.USER
	if not cli.cap_used then -- CAP client
		--return register(cli)
		return cli.NEXT_PROTOCOL
	end
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
