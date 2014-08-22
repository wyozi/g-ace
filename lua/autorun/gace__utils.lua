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

local gat = gace.AddTest
gat("Utils", function(t)
	t.assertEquals({1,2,3}, {1,2,3}, "sequentical table equality")
	t.assertEquals({a=1}, {a=1}, "string indexed table equality")
	t.assertNonEqual({1,2,3}, {1,2,3,4}, "sequentical table nonequality")
	t.assertNonEqual({a=1}, {a=2}, "string indexed table nonequality")

	t.assertEquals({}, {}, "empty table equality")
	t.assertNonEqual({{}}, {{}}, "empty subtable nonequality")

	t.assertDeepEquals({}, {}, "empty table deep equality")
	t.assertNonDeepEqual({}, {{}}, "subtable deep nonequality")
	t.assertDeepEquals({{}}, {{}}, "subtable deep equality")
	t.assertNonDeepEqual({1}, {}, "deep nonequality")
	t.assertDeepEquals({1, 2, 3}, {1, 2, 3}, "single-dim table equality")
	t.assertDeepEquals({1, {2, 3}}, {1, {2, 3}}, "multi-dim table equality")
	t.assertDeepEquals({a={b={c="hi"}}}, {a={b={c="hi"}}}, "string-key table equality")
	
	t.assertEquals(gace.TableKeys({"a", "b"}), {1, 2}, "simple TableKeys")
	t.assertEquals(gace.TableKeys({"a", c="b"}), {1, "c"}, "string-key TableKeys")

	t.assertEquals(gace.Filter({a=1,b=2,c=4}, function(v) return v%2 == 0 end), {b=2,c=4}, "string-key filter")
	t.assertEquals(gace.FilterSeq({1,2,3,4}, function(v) return v%2 == 0 end), {2, 4}, "sequential filter")

	t.assertEquals(gace.Map({"1","2","3"}, function(x)return tonumber(x)end), {1,2,3}, "map")
end)

-- Hook system used by gace extensions.

local hooks = {}
gace.Hooks = hooks

function gace.CallHook(name, ...)
	if not hooks[name] then return end
	local hks = hooks[name]
	for i=1,#hks do
		local val = hks[i].fn(...)
		if val ~= nil then return val end
	end
end
function gace.AddHook(name, id, fn)
	if not hooks[name] then hooks[name] = {} end

	-- If hook id already exists, let's replace that hook with our new one
	local old_hook_key
	for k,hk in pairs(hooks[name]) do
		if hk.id == id then
			old_hook_key = k
		end
	end
	hooks[name][old_hook_key or (#hooks[name]+1)] = {id=id, fn=fn}
end