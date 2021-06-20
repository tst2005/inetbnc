
local split = require "mini.string.split"
local plainsplit1 = require "plainsplit1"

--[[
# (PRE_USER)
Client: CAP LS 302
Client: PASS 1234
Client: NICK dan
Client: USER d * 0 :This is a really good name
# (POST_USER)
Server: CAP * LS :multi-prefix sasl
Client: CAP REQ :multi-prefix
Server: CAP * ACK multi-prefix
Client: CAP END
Server: 001 dan :Welcome to the Internet Relay Network dan
...
]]--

local protocol_cap = {pre_user={},post_user={}}
function protocol_cap.pre_user.LS(cli, data, parsed)
	local states=cli.states
	cli.cap_used=z -- "" or "302" or "307" ...
end
protocol_cap.pre_user.LIST = protocol_cap.pre_user.LS
function protocol_cap.pre_user.REQ(cli, data, parsed)
	-- bufferize or drop or ERROR-KILL
	return cli.EXIT
end
function protocol_cap.pre_user.END(cli, data, parsed)
	-- ERROR-KILL
	return cli.EXIT
end
function protocol_cap.pre_user.unknown(cli, data, parsed)
	log.server("# ERROR: protocol.pre_user.unknown CAP"..tostring(parsed.cmd2))
	return cli.EXIT
end

function protocol_cap.post_user.LS(cli, data, parsed)
	local nick = "*" -- "*" or cli.nick ?
	cli:send(nil, "CAP", nick, "LS", "")
end
protocol_cap.post_user.LIST = protocol_cap.post_user.LS
function protocol_cap.post_user.REQ(cli, data, parsed)
	--Client: CAP REQ :multi-prefix sasl ex3
	--Server: CAP * NAK :multi-prefix sasl ex3
	cli:send(nil, "CAP * NAK "..data)
end
function protocol_cap.post_user.END(cli, data, parsed)
	return cli.NEXT_PROTOCOL
end

function protocol_cap.post_user.unknown(cli, data, parsed)
	local nick = "*" -- cli.nick or "*" ? 
	local cmd2 = assert(parsed.cmd2)
	cli:send("example.org", "410", nick.." "..parsed.cmd2, "Invalid CAP command")
end
return protocol_cap
