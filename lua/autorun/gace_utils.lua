
-- Small utility functions

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

	local eq_tester = deep and gace.Equals or norm_eq_tester

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

local gat = gace.AddTest
gat("Utils", function(t)
	t.assertEquals({1,2,3}, {1,2,3})
	t.assertTrue(not gace.ShallowEquals({1,2,3}, {1,2,3,4}))
	t.assertTrue(not gace.ShallowEquals({a=1}, {a=2}))
	t.assertEquals({a=1}, {a=1})

	t.assertEquals({}, {})
	t.assertTrue(not gace.ShallowEquals({{}}, {{}}))
	t.assertTrue(not gace.ShallowEquals({1}, {}))

	t.assertTrue(gace.DeepEquals({}, {}))
	t.assertTrue(not gace.DeepEquals({}, {{}}))
	t.assertTrue(gace.DeepEquals({{}}, {{}}))
	t.assertTrue(not gace.DeepEquals({1}, {}))
	t.assertTrue(gace.DeepEquals({1, 2, 3}, {1, 2, 3}))
	t.assertTrue(gace.DeepEquals({1, {2, 3}}, {1, {2, 3}}))
	
	t.assertEquals(gace.TableKeys({"a", "b"}), {1, 2})
	t.assertEquals(gace.TableKeys({"a", c="b"}), {1, "c"})

	t.assertEquals(gace.Filter({a=1,b=2,c=4}, function(v) return v%2 == 0 end), {b=2,c=4})
	t.assertEquals(gace.FilterSeq({1,2,3,4}, function(v) return v%2 == 0 end), {2, 4})

	t.assertEquals(gace.Map({"1","2","3"}, function(x)return tonumber(x)end), {1,2,3}, "Map giving wrong result")
end)