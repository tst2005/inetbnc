local plainsplit1 = require "plainsplit1"

local function test(a,b)
	t={plainsplit1(a,b)}
	print("(@1@)"..t[1].."(/@1@)"..type(t[1]))
	print("(@2@)"..(t[2] or "").."(/@2@)"..type(t[2]))
end

test("PASS <password>"," ")
test("NICK <nickname> [ <hopcount> ]", " ")
test("USER <username> <hostname*ign> <servername*ign> <[:]realname>", " :")

