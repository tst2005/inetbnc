#!/usr/bin/env luajit

local protocol1 = require "protocol1"
local log = require "runtime.log"

local split = require "mini.string.split"
local plainsplit1 = require "plainsplit1"

local format = string.format

local function server_welcome(cli)
	cli:console(format("You are connected as %s", cli:realnuh()))
	cli:console(format("Visible on the network as %s", cli:nuh()))
	cli:console(format("Password used: %s", (cli.pass) and "yes" or "no"))
	cli:console(format("CAP LS used: %s", (cli.capls) and "yes" or "no"))
	cli:console("")
end

local protocol2 = {}
function protocol2.init(cli)
	cli.state=nil
	cli.states=nil
	cli.protocol=protocol2
	cli.protocolnum=2 -- useless ?
	cli.protocolnext=nil -- no change
        server_welcome(cli)
	return cli
end
function protocol2.finished(cli)
	error("not implemented yet")
	return cli
end

protocol2.PING = protocol1.PING
protocol2.PONG = protocol1.PONG
protocol2.QUIT = protocol1.QUIT
protocol2.unkown = protocol1.unknown

function protocol2.PRIVMSG(cli,data)
end
function protocol2.NOTICE(cli,data)
end
function protocol2.MODE(cli,data,parsed)
end
function protocol2.JOIN(cli,data,parsed)
-- JOIN #foo,#bar fubar,foobar                 (format envoyé par le client au server ?)
-- JOIN #foo,&bar fubar                        #foo key fubar ; &bar no key
-- :WiZ!jto@tolsun.oulu.fi JOIN #Twilight_zon  (format emit par le server vers le client ?)

	if data:sub(1,1)==":" then
		log.server("# unsupported JOIN format! data="..data)
		return
	end

	local channels,keys = plainsplit1(data, " ")
	local channels = split(channels, ",", true, nil)
	if keys then
		keys=split(keys, ",", true, nil)
	end

	for _i,chan in ipairs(channels) do
		cli:send(cli:nuh(), "JOIN", chan)
	end
end
function protocol2.PART(cli,data)
	--? supposed syntax ?: PART #foo,#bar [:]?reason
	local channels,reason = plainsplit1(data, " ")
	local channels = split(channels, ",", true, nil)
	for _i,chan in ipairs(channels) do
		cli:send(cli:nuh(), "PART", chan)
	end
end
function protocol2.WHO(cli,data)
end
return protocol2
