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

-- Returns [first path component], [(first+1=>last) path comps concatenated]
function gace.path.head(path)
    local head, rest = string.match(path, "([^/]*)/(.*)")
    return (head or path), rest
end

-- Returns [last path component], [(first=>last-1) path comps concatenated]
function gace.path.tail(path)
    local rest, tail = string.match(path, "(.*)/([^/]*)")
    return (tail or path), rest
end

local validator_pattern = "[^%a%d%_%- %./]"
function gace.path.validate(path)
    if string.find(path, validator_pattern) then
        return false
    end
    return true
end

function gace.path.validate_comp(comp)
    if string.find(comp, "/") then return false end
    return gace.path.validate(comp)
end
