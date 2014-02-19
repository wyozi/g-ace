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
	local function msgc(...)
		MsgC(Color(243, 156, 18), "[G-Ace tests] ")
		local clr
		for i,v in pairs{...} do
			if i % 2 == 1 then
				clr = v
			else
				MsgC(clr, v)
			end
		end
		MsgN("")
	end
	local function msg(...)
		MsgC(Color(243, 156, 18), "[G-Ace tests] ")
		Msg(...)
		MsgN("")
	end

	local compl, fails = 0, 0

	local function GetDetails()
		local dtbl = debug.getinfo(4)
		return string.format("[%s LINE#%d] ", dtbl.short_src:Split("autorun/")[2], dtbl.currentline)
	end

	local function pass(msg)
		msgc(Color(189, 195, 199), GetDetails(), Color(189, 195, 199), msg, Color(0, 255, 0), " passed!")
		compl = compl + 1
	end
	local function fail(msg)
		msgc(Color(189, 195, 199), GetDetails(), Color(189, 195, 199), msg, Color(255, 0, 0), " failed!")
		fails = fails + 1
	end

	msg("Starting tests")

	local testing_funcs = {
		assertTrue = function(b, msg)
			if b then pass(msg) else fail(msg) end
		end,
		-- Equality check
		assertEquals = function(a, b, msg)
			if gace.Equals(a, b) then pass(msg) else fail(msg) end
		end,
		assertNonEqual = function(a, b, msg)
			if not gace.Equals then pass(msg) else fail(msg) end
		end,
		assertDeepEquals = function(a, b, msg)
			if gace.DeepEquals(a, b) then pass(msg) else fail(msg) end
		end,
	}

	for k,v in pairs(gace.Tests) do
		msg("")
		msg("= Running test group ", k)

		local runner = v

		if type(v) == "table" then
			runner = v.runner
			if v.before then v.before() end
		end

		runner(testing_funcs)

		if type(v) == "table" then
			if v.after then v.after() end
		end
		
		msg("= Test group ", k, " completed")
	end

	msg("")
	MsgC(fails == 0 and Color(0, 255, 0) or Color(255, 0, 0), "All tests finished! ", compl, " completed tests; ", fails, " failed.") MsgN("")
end
