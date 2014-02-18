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
		msg("= Running tests ", k)

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

	msg("Tests finished! ", compl, " completed tests; ", fails, " failed.")
end