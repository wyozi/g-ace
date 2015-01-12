gace.path = {}

function gace.path.normalize(path)
    local finalPathComps = {}

    path = path:Replace("\\", "/")

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

function gace.path.head(path)
    local comps = path:Split("/", 2)
    local first = comps[1]
    table.remove(comps, 1)
    return first, table.concat(comps, "/")
end

function gace.path.tail(path)
    local comps = path:Split("/", 2)
    local last = comps[#comps]
    table.remove(comps, #comps)
    return table.concat(comps, "/"), last
end

local validator_pattern = "[^%a%d%_%- %./]"
function gace.path.validate(comp)
    if string.find(comp, validator_pattern) then
        return false
    end
    return true
end
