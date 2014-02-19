gace = gace or {}
gace.RequestCallbacks = gace.RequestCallbacks or {}

function gace.AddRequestCallback(reqid, fn)
	gace.RequestCallbacks[reqid] = fn
end

function gace.GenReqId(id)
	return util.CRC(id .. os.time() .. math.random())
end

function gace.Debug(...)
	--MsgN("GACE DEBUG: ", ...)
end

-- Testing

gace.Tests = gace.Tests or {}
function gace.AddTest(nm, fn)
	gace.Tests[nm] = fn
end

function gace.RunTests()
	local function msg(...)
		MsgN("[G-Ace tests] ", ...)
	end

	msg("Starting tests")

	local compl, fails = 0, 0

	-- A table to store random crap in
	local test_platform = {}

	for k,v in pairs(gace.Tests) do
		msg("")
		msg("= Running test ", k)

		local runner = v

		if type(v) == "table" then
			runner = v.runner
			if v.before then v.before(test_platform) end
		end

		local stat, err = pcall(runner, test_platform)
		if not stat then
			msg("= Test failed: ", err)
			fails = fails + 1
		end

		if type(v) == "table" then
			if v.after then v.after(test_platform) end
		end
		
		compl = compl + 1
		msg("= Test ", k, " completed")
	end

	msg("")
	MsgC(fails == 0 and Color(0, 255, 0) or Color(255, 0, 0), "All tests finished! ", compl, " completed tests; ", fails, " failed.") MsgN("")
end

-- Small utility functions

function gace.Map(tbl, fn)
	local t = {}
	for k,v in pairs(tbl) do
		t[k] = fn(v, k)
	end
	return t
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


local gat = gace.AddTest
gat("Utils", function()
	assert(gace.ShallowEquals({1,2,3}, {1,2,3}))
	assert(not gace.ShallowEquals({1,2,3}, {1,2,3,4}))
	assert(not gace.ShallowEquals({a=1}, {a=2}))
	assert(gace.ShallowEquals({a=1}, {a=1}))

	assert(gace.ShallowEquals(gace.TableKeysToList({"a", "b"}), {1, 2}))
	assert(gace.ShallowEquals(gace.TableKeysToList({"a", c="b"}), {1, "c"}))

	assert(gace.DeepEquals({1, 2, 3}, {1, 2, 3}))
	assert(gace.DeepEquals({1, {2, 3}}, {1, {2, 3}}))

	assert(gace.ShallowEquals(gace.Map({"1","2","3"}, function(x)return tonumber(x)end), {1,2,3}), "Map giving wrong result")
end)