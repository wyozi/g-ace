
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

    msg("Starting tests")

    local testing_async = false
    local testgroups = {}

    local function testgroup_id(p)
        local dtbl = debug.getinfo(p)
        if not dtbl then return end

        return string.format("%s::%d", dtbl.short_src, dtbl.linedefined)
    end

    local function testgroup()
        for i=1, 15 do
            local dtbl_id = testgroup_id(i)
            if not dtbl_id then break end

            if testgroups[dtbl_id] then
                return testgroups[dtbl_id]
            end
        end
    end

    local function pass(msg)
        local group = testgroup()
        if not group then
            PrintTable(testgroups)
            print("FAILED TO FIND TESTGROUP!!!!")
            return
        end
        table.insert(group.tests, {
            state = "passed",
            src = GetCodeSrc(),
            msg = msg
        })
    end
    local function fail(msg)
        local group = testgroup()
        if not group then
            print("FAILED TO FIND TESTGROUP!!!!")
            return
        end
        table.insert(group.tests, {
            state = "failed",
            src = GetCodeSrc(),
            msg = msg
        })
    end

    local testing_funcs = {
        async = function()
            testing_async = true
        end,
        done = function()
            local tgroup = testgroup()
            tgroup.promise:_resolve()
        end,

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

    local test_results = {}

    for k,v in pairs(gace.Tests) do
        -- Reset status
        testing_async = false

        local group = {name = k, tests = {}, promise = ATPromise(function() end)}
        local group_id = testgroup_id(v)

        testgroups[group_id] = group

        v(testing_funcs)

        if testing_async then
            group.promise:timeout(3000, "timed out")
        else
            group.promise:_resolve()
        end

        table.insert(test_results, group)
    end

    local test_promises = _u.map(test_results, function(r) return r.promise end)

    ATPromise(test_promises):all():then_(function()
        table.SortByMember(test_results, "name", true)

        local compl = 0
        local fails = 0
        for _, res in pairs(test_results) do
            msg("")
            msgc(Color(149, 165, 166), "= Running test group ", Color(52, 152, 219), res.name)

            local failed = false
            for _,test in pairs(res.tests) do
                if test.state == "passed" then
                    msgc(Color(236, 240, 241), test.src, Color(189, 195, 199), test.msg, Color(0, 255, 0), " passed!")
                elseif test.state == "failed" then
                    msgc(Color(236, 240, 241), test.src, Color(189, 195, 199), test.msg, Color(255, 0, 0), " failed!")
                    failed = true
                    fails = fails + 1
                end
                compl = compl + 1
            end

            msgc(Color(149, 165, 166), "= Test group ", failed and Color(255, 0, 0) or Color(0, 255, 0), failed and "failed" or "passed")
        end

        msg("")
        msgc(fails == 0 and Color(0, 255, 0) or Color(255, 0, 0), "All tests finished! " ..compl .. " completed tests; " .. fails .. " failed.")

        if SERVER then
            -- Dear reader, this part may look like a some kind of amateurish attempt
            -- at creating a botnet, or something similar. However, that is not what it is.
            --
            -- It automatically removes (using gace-io) file "gace-tests-pending" from
            -- addon root, if it exists. "gace-tests-pending" is a file created in git post-commit
            -- hook, and is used to ensure I run all the tests before pushing.
            --
            -- If you for some reason want to do the same, copy hooks from /githooks to .git/hooks
            -- You also need gace-io binary module to remove the file programmatically.
            local addon_name = debug.getinfo(1).short_src:match("addons/([^/]*)")
            if addon_name and file.Exists("addons/" .. addon_name .. "/gace-tests-pending", "GAME") then
                require("gaceio")
                gaceio.Delete("./garrysmod/addons/" .. addon_name .. "/gace-tests-pending")
            end
        end
    end):catch(function(e)
        msg("Tests failed: ", e)
    end)
end

concommand.Add("gace-test", gace.RunTests)
