	
return function(env)
	local PWD,CLIENTIP=env.PWD,env.CLIENTIP
	local logcount = 0
	local clientlog = io.open(PWD.."/log/"..CLIENTIP..".c.log","w")
	local serverlog = io.open(PWD.."/log/"..CLIENTIP..".s.log","w")
	clientlog:setvbuf("line")
	serverlog:setvbuf("line")

	local log = {}
	function log.client(line) logcount=logcount+1 clientlog:write(logcount..":Client: "..line.."\n") end
	function log.server(line) logcount=logcount+1 serverlog:write(logcount..":Server: "..line.."\n") end
	function log.close() clientlog:flush() serverlog:flush() clientlog:close() serverlog:close() end
	return log
end
