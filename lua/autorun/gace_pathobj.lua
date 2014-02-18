
local path_meta = {
	Set = function(self, str)
		table.Empty(self.Parts)
		local spl = str:Split("/")

		for i,s in pairs(spl) do
			if s == "" then
				-- If not last part of the path there's something wrong
				if i ~= #spl then error("Path contains empty part") end
				break
			end
			table.insert(self.Parts, s)
		end
	end,
	GetPart = function(self, idx)
		if idx < 0 then
			-- If negative (e.g. -1) we should start from the end (-1 -> #parts)
			idx = #self.Parts - (math.abs(idx)-1)
		end
		return self.Parts[idx]
	end,
	GetVFolder = function(self)
		return self:GetPart(1)
	end,
	GetFile = function(self)
		return self:GetPart(-1)
	end,
	ToString = function(self, str)
		return table.concat(self.Parts, "/")
	end
}
path_meta.__index = path_meta
path_meta.__tostring = path_meta.ToString

function gace.NewPath(s)
	local tbl = {Parts={}}
	setmetatable(tbl, path_meta)
	if s then tbl:Set(s) end
	return tbl
end