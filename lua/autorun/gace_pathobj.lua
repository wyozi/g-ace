-- A wrapper object for GAce virtual filesystem path

-- TODO refactor functions from inside path_meta to "path_meta.Func = function()...end" format to improve clarity
local path_meta = {
	Set = function(self, str)
		table.Empty(self.Parts)
		local spl = str:Split("/")

		for i,s in pairs(spl) do
			-- Replace especially bad characters
			s = s:Replace("..", "")
			s = s:Replace("\\", "")

			-- Skip empty parts
			if s ~= "" then
				table.insert(self.Parts, s)
			end
		end

		return self
	end,
	SetTable = function(self, tbl)
		self.Parts = tbl
		return self
	end,
	GetPart = function(self, idx)
		if idx < 0 then
			-- If negative (e.g. -1) we should start from the end (-1 -> #parts)
			idx = #self.Parts - (math.abs(idx)-1)
		end
		return self.Parts[idx]
	end,

	IsRoot = function(self)
		return #self.Parts == 0
	end,

	GetVFolder = function(self)
		return self:GetPart(1)
	end,
	GetFile = function(self)
		return self:GetPart(-1)
	end,

	Add = function(self, f)
		if type(f) == "table" then -- Assume another path
			return gace.NewPath(self:ToString() .. "/" .. f:ToString())
		end
		-- Assume a string
		return self:Add(gace.NewPath(f))
	end,

	-- Adds together and converts into a string
	Concat = function(self, f)
		return self:Add(f):ToString()
	end,

	Equals = function(self, f)
		return self:ToString() == f:ToString()
	end,

	-- Strips first part
	WithoutVFolder = function(self, f)
		return gace.NewPath(""):SetTable({unpack(self.Parts, 2)})
	end,

	-- Basically gets path one layer up
	WithoutFile = function(self, f)
		return gace.NewPath(""):SetTable({unpack(self.Parts, 1, #self.Parts-1)})
	end,

	ToString = function(self, str)
		return table.concat(self.Parts, "/")
	end
}
path_meta.__index = path_meta
path_meta.__tostring = path_meta.ToString
path_meta.__add = path_meta.Add
path_meta.__concat = path_meta.Concat
path_meta.__eq = path_meta.Equals

function gace.NewPath(s)
	local tbl = {Parts={}}
	setmetatable(tbl, path_meta)
	tbl:Set(s)
	return tbl
end
gace.Path = gace.NewPath -- alias
