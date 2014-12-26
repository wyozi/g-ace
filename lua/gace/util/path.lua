gace.path = {}

function gace.path.normalize(path)
    local finalPathComps = {}

    local comps = path:Split("/")
    for _,comp in pairs(comps) do
        comp = comp:Trim()

        if comp == ".." then
            finalPathComps[#finalPathComps] = nil
        elseif not (comp == "" or comp == ".") then
            table.insert(finalPathComps, comp)
        end
    end

    return table.concat(finalPathComps, "/")
end

local validator_pattern = "[^%a%d_- %./]"
function gace.path.validate(comp)
    if string.find(comp, validator_pattern) then
        return false
    end
    return true
end
