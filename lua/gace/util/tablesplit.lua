-- Table split library is in charge of dividing a table into specifically sized
-- "chunks". Chunks themselves are tables. Table split library is also able to
-- weave these chunks back together.

gace.tablesplit = {}

--- Computes estimated size of given object in bytes.
-- Tries to be somewhat equal to what net.WriteTable would send.
-- If object is a table, typeHeaderSize amount of bytes is added to each key & value
function gace.tablesplit.ComputeSize(obj, typeHeaderSize, checkedTables)
    if obj == nil then return 1 end

    local t = type(obj)
    if t == "number" then return 8 end
    if t == "string" then return #obj + 2 end
    if t == "boolean" then return 1 end

    if t == "Player" then return 4 end
    if t == "Entity" then return 4 end

    if t == "table" then
        local size = 0

        checkedTables = checkedTables or {}
        checkedTables[obj] = true

        typeHeaderSize = typeHeaderSize or 0
        for k,v in pairs(obj) do
            size = size + typeHeaderSize
            size = size + (checkedTables[k] and 0 or gace.tablesplit.ComputeSize(k, typeHeaderSize, checkedTables))

            size = size + typeHeaderSize
            size = size + (checkedTables[v] and 0 or gace.tablesplit.ComputeSize(v, typeHeaderSize, checkedTables))
        end

        return size
    end

    if t == "function" then return 0 end -- functions are skipped

    MsgN("Trying to compute size of unknown object (type:".. t .. "): " .. tostring(obj))
    return 4 -- whatever
end

-- A recursive depth-first pairs
local function DFSpairs(t, path)
    path = path or {}

    local subfunc
    local lastk

    local function innerNext()
        if subfunc then
            local k, v = subfunc()
            if k then
                return k, v
            end
            subfunc = nil
        end

        local k, v = next(t, lastk)
        if not k then return end

        local kpath = table.Copy(path)
        kpath[#kpath+1] = k

        lastk = k

        if type(v) == "table" then
            subfunc = DFSpairs(v, kpath)
        end

        return kpath, v
    end

    return innerNext
end

-- maxChunkSize is in bytes
function gace.tablesplit.Split(tbl, maxChunkSize)
    local chunks = {}

    local chunk, chunkSize

    local function newchunk()
        chunk = {}
        chunks[#chunks+1] = chunk
        chunkSize = 0
        return chunk
    end

    local function set(path, val)
        local t = chunk

        for i=1, #path do
            local comp = path[i]
            if i == #path then
                t[comp] = val
            elseif t[comp] then
                t = t[comp]
            else
                local ntbl = {}
                t[comp] = ntbl
                t = ntbl
            end
        end
    end

    newchunk()

    local function SplitKV(k, v)
        local newSize = chunkSize + gace.tablesplit.ComputeSize(v)
        if newSize > maxChunkSize then
            if type(v) == "string" then
                -- Strings we can split in two
                local overflowSize = newSize - maxChunkSize

                local firstChunkStr = v:sub(1, -overflowSize-1)
                set(k, firstChunkStr)

                local secondChunkStr = v:sub(-overflowSize) -- second chunk str
                newchunk()

                return SplitKV(k, secondChunkStr)
            else
                -- Other types not so much, so we'll create a new chunk for them
                newchunk()
            end
        end

        -- Tables should not be set directly, as they are references
        if type(v) == "table" then
            v = table.Copy(v)
        end
        set(k, v)
    end

    for k,v in DFSpairs(tbl) do
        SplitKV(k, v)
    end

    return chunks
end

function gace.tablesplit.MergeInto(tbl, chunk)
    for k,v in pairs(chunk) do
        if type(v) == "table" then
            tbl[k] = tbl[k] or {}
            gace.tablesplit.MergeInto(tbl[k], v)
        elseif type(v) == "string" then
            tbl[k] = table.concat({tbl[k] or "", v}, "")
        else
            tbl[k] = v
        end
    end
end
