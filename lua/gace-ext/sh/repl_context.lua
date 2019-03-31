gace.repl = gace.repl or {}
gace.repl.implicitGlobals = {
    me = "player.GetByUniqueID('$UNIQID')",
    wep = "me:GetActiveWeapon()",
    tr = "me:GetEyeTrace()",
    that = "tr.Entity",
    here = "me:EyePos()",
    there = "tr.HitPos"
}
local globalOrder = {"me", "wep", "tr", "that", "here", "there"}

local upvals = {}
upvals[#upvals+1] = "local " .. table.concat(table.GetKeys(gace.repl.implicitGlobals), ", ")
upvals[#upvals+1] = "do"
for _, key in pairs(globalOrder) do
    local val = gace.repl.implicitGlobals[key]
    upvals[#upvals+1] = string.format("%s = %s", key, val)
end
upvals[#upvals+1] = "end"
upvals = table.concat(upvals, " ")
print(upvals)

gace.repl.contextSrc = upvals


