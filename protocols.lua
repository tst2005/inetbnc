local protocol1 = require "protocol1"
local protocol2 = require "protocol2"
local protocols = {}
protocols[1] = protocol1 -- before registration (PASS/NICK/USER)
protocols[2] = protocol2 -- after registration (JOIN/PART/...)
return protocols
