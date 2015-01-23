-- Small utility functions
-- Note: name has two underscores because we want to be sure we're loaded before any other gace related files

function gace.Map(tbl, fn)
	local t = {}
	for k,v in pairs(tbl) do
		t[k] = fn(v, k)
	end
	return t
end

function gace.Filter(tbl, fn)
	local t = {}
	for k,v in pairs(tbl) do
		if fn(v, k) then t[k] = v end
	end
	return t
end

-- Filter for sequential tables
function gace.FilterSeq(tbl, fn)
	local t = {}
	for k,v in pairs(tbl) do
		if fn(v, k) then t[#t+1] = v end
	end
	return t
end

function gace.SortedTable(tbl, fn)
	local c = table.Copy(tbl)
	table.sort(c, fn)
	return c
end

local norm_eq_tester = function(a, b) return a == b end

function gace.Equals(f, s, deep)
	if type(f) ~= "table" or type(s) ~= "table" then return f == s end

	local eq_tester = deep and function(a, b) return gace.Equals(a, b, deep) end
						   or norm_eq_tester

	for kf, vf in pairs(f) do
		local vs = s[kf]

		if not eq_tester(vf, vs) then return false end
	end

	for ks, vs in pairs(s) do
		local vf = f[ks]

		if not eq_tester(vf, vs) then return false end
	end

	return true
end

function gace.ShallowEquals(f, s)
	return gace.Equals(f, s)
end

function gace.DeepEquals(f, s)
	return gace.Equals(f, s, true)
end

function gace.TableKeysToList(tbl)
	local keys = {}
	for k,v in pairs(tbl) do table.insert(keys, k) end
	return keys
end

gace.TableKeys = gace.TableKeysToList -- alias

function gace.JSEscape(str)
	return str:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\'", "\\'"):gsub("\r", "\\r"):gsub("\n", "\\n")
end
