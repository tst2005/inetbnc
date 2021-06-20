
local split = require "mini.string.split"
local plainsplit1 = require "plainsplit1"

--[[
Client: CAP LS 302
Client: NICK dan
Client: USER d * 0 :This is a really good name
Server: CAP * LS :multi-prefix sasl
Client: CAP REQ :multi-prefix
Server: CAP * ACK multi-prefix
Client: CAP END
Server: 001 dan :Welcome to the Internet Relay Network dan
...
]]--

local protocol_cap = {}
function protocol_cap.LS(cli, z)
	local states=cli.states
	if cli.state==states.new then
		cli.capls=z -- "" or "302" or "307" ...
		cli.state=states.CAP_LS
	else
		-- for now: allow CAP LS only at the beginning
	end
end
protocol_cap.LIST = protocol_cap.LS
protocol_cap.REQ  = function() end
protocol_cap.END  = function() end

return protocol_cap
