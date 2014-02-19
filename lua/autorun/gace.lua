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

function gace.ShallowEquals(f, s)
	-- Two fors because one of them might have less/different indices than the other
	for k,v in pairs(f) do
		if f[k] ~= s[k] then return false end
	end
	for k,v in pairs(s) do
		if f[k] ~= s[k] then return false end
	end
	return true
end

local gat = gace.AddTest
gat("Utils", function()
	assert(gace.ShallowEquals({1,2,3}, {1,2,3}))
	assert(not gace.ShallowEquals({1,2,3}, {1,2,3,4}))
	assert(not gace.ShallowEquals({a=1}, {a=2}))
	assert(gace.ShallowEquals({a=1}, {a=1}))

	assert(gace.ShallowEquals(gace.Map({"1","2","3"}, function(x)return tonumber(x)end), {1,2,3}), "Map giving wrong result")
end)