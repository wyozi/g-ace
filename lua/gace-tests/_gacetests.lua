
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

    local function GetCodeSrc()
        local dtbl = debug.getinfo(4)
        local path = dtbl.short_src
        path = path:match(".*lua/(.*)$") or path

        return string.format("[%s LINE#%03d] ", path, dtbl.currentline)
    end

    local function pass(msg)
        msgc(Color(236, 240, 241), GetCodeSrc(), Color(189, 195, 199), msg, Color(0, 255, 0), " passed!")
        compl = compl + 1
    end
    local function fail(msg)
        msgc(Color(236, 240, 241), GetCodeSrc(), Color(189, 195, 199), msg, Color(255, 0, 0), " failed!")
        fails = fails + 1
    end

    msg("Starting tests")

    local testing_funcs = {
        assertTrue = function(b, msg)
            if b == true then pass(msg) else fail(msg) end
        end,
        assertFalse = function(b, msg)
            if b == false then pass(msg) else fail(msg) end
        end,

        assertNonNil = function(b, msg)
            if b ~= nil then pass(msg) else fail(msg) end
        end,
        assertNil = function(b, msg)
            if b == nil then pass(msg) else fail(msg) end
        end,

        -- Equality check
        assertEquals = function(a, b, msg)
            if gace.Equals(a, b) then pass(msg) else fail(msg) end
        end,
        assertNonEqual = function(a, b, msg)
            if not gace.Equals(a, b) then pass(msg) else fail(msg) end
        end,
        assertDeepEquals = function(a, b, msg)
            if gace.DeepEquals(a, b) then pass(msg) else fail(msg) end
        end,
        assertNonDeepEqual = function(a, b, msg)
            if not gace.DeepEquals(a, b) then pass(msg) else fail(msg) end
        end,

        -- Error catching
        assertError = function(func, msg, ...)
            local status, err = pcall(func, ...)
            if not status then
                local errmsg = type(err) == "table" and table.ToString(err) or tostring(err)

                pass(string.format("%s (err: %s)", msg, errmsg))
            else
                fail(msg)
            end
        end,
        assertNoError = function(func, msg, ...)
            local status, err = pcall(func, ...)
            if status then
                pass(msg)
            else
                local errmsg = type(err) == "table" and table.ToString(err) or tostring(err)

                fail(string.format("%s (err: %s)", msg, errmsg))
            end
        end,
    }

    for k,v in pairs(gace.Tests) do
        msg("")
        msgc(Color(149, 165, 166), "= Running test group ", Color(52, 152, 219), k)

        local startfails = fails

        local runner = v

        if type(v) == "table" then
            runner = v.runner
            if v.before then v.before() end
        end

        runner(testing_funcs)

        if type(v) == "table" then
            if v.after then v.after() end
        end

        msgc(Color(149, 165, 166), "= Test group ", (fails == startfails) and Color(0, 255, 0) or Color(255, 0, 0), (fails == startfails) and "passed" or "failed")
    end

    msg("")
    msgc(fails == 0 and Color(0, 255, 0) or Color(255, 0, 0), "All tests finished! " ..compl .. " completed tests; " .. fails .. " failed.")

    if SERVER then
        -- Dear reader, this part may look like a some kind of amateurish attempt
        -- at creating a botnet, or something similar. However, that is not what it is.
        -- Instead, it automatically removes (using gace-io) file "gace-tests-pending" from
        -- addon root, if it exists. "gace-tests-pending" is a file created in git post-commit
        -- hook, and is used to ensure I run all the tests before pushing.
        local addon_name = debug.getinfo(1).short_src:match("addons/([^/]*)")
        if addon_name and file.Exists("addons/" .. addon_name .. "/gace-tests-pending", "GAME") then
            require("gaceio")
            gaceio.Delete("./garrysmod/addons/" .. addon_name .. "/gace-tests-pending")
        end
    end
end

concommand.Add("gace-test", gace.RunTests)
