-- MoonScript support
-- Code that starts with "--!moon" is translated to moonscript
-- Depends on https://github.com/wyozi/gmod-moonscript

gace.AddHook("GAceTransformLua", "MoonScript", function(code)

    if code:StartWith("--!moon") then
        if not loadmodule then return false, "MoonScript module not installed!" end

        local moonscript = loadmodule("moonscript.base")
        if not moonscript then return false, "MoonScript module not installed!" end

        local res, err = moonscript.to_lua(code)
        if res then return true, res end

        return false, "MoonScript error: " .. tostring(err)
    end
end)
