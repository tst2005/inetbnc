local find,sub=string.find,string.sub

return function(str, pat)
        assert(type(str)=="string")
        assert(type(pat)=="string")
        local pos1, pos2 = find(str, pat, 1, true)
	if not pos1 then
		return str, nil
	end
        return sub(str, 1, pos1-1), sub(str, pos2+1)
end
