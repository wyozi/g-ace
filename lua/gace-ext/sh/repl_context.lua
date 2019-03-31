gace.repl = gace.repl or {}
gace.repl.implicitGlobals = {
    me = "player.GetByUniqueID('$UNIQID')",
    wep = "me:GetActiveWeapon()",
    tr = "me:GetEyeTrace()",
    that = "tr.Entity",
    here = "me:EyePos()",
    there = "tr.HitPos",
    each = "function(t,f) for k,v in pairs(t) do f(v, k) end end",
    filter = string.gsub([[function(t,f)
        local out={}
        local seq = table.IsSequential(t)
        for k,v in pairs(t) do
            if f(v, k) then
                if seq then
                    out[#out+1] = v
                else
                    out[k] = v
                end
            end
        end
        return out
    end]], "\n", " "),
    map = string.gsub([[function(t,f)
        local out={}
        local seq = table.IsSequential(t)
        for k,v in pairs(t) do
            if seq then
                out[#out+1] = f(v, k)
            else
                out[k] = f(v, k)
            end
        end
        return out
    end]], "\n", " ")
}
local globalOrder = {"me", "wep", "tr", "that", "here", "there", "each", "filter", "map"}

local upvals = {}
upvals[#upvals+1] = "local " .. table.concat(table.GetKeys(gace.repl.implicitGlobals), ", ")
upvals[#upvals+1] = "local _ents = ents; local ents"
upvals[#upvals+1] = "do"
for _, key in pairs(globalOrder) do
    local val = gace.repl.implicitGlobals[key]
    upvals[#upvals+1] = string.format("%s = %s", key, val)
end
upvals[#upvals+1] = "local dynamicEnts = function(self, val, param)"
upvals[#upvals+1] = [[if type(val) == "string" then return ents.FindByClass(val) end]]
upvals[#upvals+1] = [[if isvector(val) then return ents.FindInSphere(val, param or 64) end]]
upvals[#upvals+1] = [[if isentity(val) then return ents.FindByClass(val:GetClass()) end]]
upvals[#upvals+1] = "end"
upvals[#upvals+1] = "ents = setmetatable({}, {__index = _ents, __call = dynamicEnts})"
upvals[#upvals+1] = "end"
upvals = table.concat(upvals, " ")

gace.repl.contextSrc = upvals