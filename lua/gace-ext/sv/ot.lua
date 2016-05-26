-- A lot of code here from https://github.com/Operational-Transformation/ot.lua
-- Cheers to them


-- Receives operations from clients, transforms them against all
-- concurrent operations and sends them back to all clients.
local Server = {}
Server.__index = Server

function Server.new(document, backend)
    return setmetatable({ document = document, backend = backend }, Server)
end

-- Transforms an operation coming from a client against all concurrent
-- operation, applies it to the current document and returns the operation to
-- send to the clients.
function Server:receiveOperation(revision, operation)
    local Operation = getmetatable(operation)

    local concurrentOperations = self.backend:getOperations(revision)
    for i=1, #concurrentOperations do
        operation = Operation.transform(operation, concurrentOperations[i])
    end

    self.document = operation(self.document)
    self.backend:saveOperation(operation)
    return operation
end

-- Simple backend that saves all operations in the server's memory. This
-- causes the processe's heap to grow indefinitely.
local MemoryBackend = {}
MemoryBackend.__index = MemoryBackend

function MemoryBackend.new(operations)
    return setmetatable({ operations = operations or {}}, MemoryBackend)
end

-- Save an operation in the database
function MemoryBackend:saveOperation(operation)
    table.insert(self.operations, operation)
end

-- Return operations in a given range. Note that the first operation has the
-- revision 0 and the end revision is exclusive.
function MemoryBackend:getOperations(start, last)
    if last == nil then
        last = #self.operations
    else
        last = last - 1
    end

    local operations = {}
    for i=start + 1, last do
        table.insert(operations, self.operations[i])
    end
    return operations
end

function MemoryBackend:getRevision()
    return #self.operations
end

local TextOperation = {}
TextOperation.__index = TextOperation

-- Operation are essentially lists of ops. There are three types of ops:
--
-- * Retain ops: Advance the cursor position by a given number of characters.
--   Represented by positive ints.
-- * Insert ops: Insert a given string at the current cursor position.
--   Represented by strings.
-- * Delete ops: Delete the next n characters. Represented by negative ints.

local function isRetain(op)
    return type(op) == "number" and op > 0
end

local function isDelete(op)
    return type(op) == "number" and op < 0
end

local function isInsert(op)
    return type(op) == "string"
end

-- This polyfill can be removed when garrysmod#1183 is merged
utf8.sub = utf8.sub or function( str, startPos, endPos )
	local startOffset = utf8.offset( str, startPos - 1 )
	
	local endOffset
	if endPos then
		-- convert negative endPos to a absolute positive position
		endPos = ( endPos > 0 ) and endPos or ( utf8.len( str ) + 1 + endPos )
		
		-- utf8.offset returns the start byte for given position, so due to
		-- endPos being exclusive we can subtract one to get end-byte of last 
		-- utf8 character
		endOffset = utf8.offset( str, endPos ) - 1
	end
	
	return string.sub( str, startOffset, endOffset )
end

local function opLen(op)
    if type(op) == "string" then
        return utf8.len(op)
    elseif op < 0 then
        return -op
    else
        return op
    end
end
TextOperation.opLen = opLen

-- Shortens an op by the given number of characters
local function shorten(op, by)
    if type(op) == "string" then
        return utf8.sub(op, 1 + by)
    elseif op < 0 then
        return op + by
    else
        return op - by
    end
end

-- Shortens a pair of ops. The result will be a tuple where the shorter of the
-- both ops is replaced by null and the longer one is shorted by the length of
-- the shorter one.
local function shortenOps(a, b)
    local lenA = opLen(a)
    local lenB = opLen(b)
    if lenA == lenB then
        return nil, nil
    elseif lenA > lenB then
        return shorten(a, lenB), nil
    else
        return nil, shorten(b, lenA)
    end
end

-- Constructs an empty operation
--
-- When an operation is applied to an input string, you can think of this as
-- if an imaginary cursor runs over the entire string and skips over some
-- parts, deletes some parts and inserts characters at some positions. These
-- actions (skip/delete/insert) are stored as an array in the "ops" property.
function TextOperation.new(ops)
    return setmetatable({ ops = ops or {} }, TextOperation)
end

setmetatable(TextOperation, {
    __call = function(_, ...)
        return TextOperation.new(...)
    end
})

-- Constructs a TextOperation from a JSON document.
function TextOperation.fromJSON(jsonOps)
    local operation = TextOperation.new()
    for i=1, #jsonOps do
        local jsonOp = jsonOps[i]
        if isRetain(jsonOp) then
            operation:retain(jsonOp)
        elseif isDelete(jsonOp) then
            operation:delete(jsonOp)
        else
            operation:insert(jsonOp)
        end
    end
    return operation
end

-- Encode a TextOperation as a JSON object. For example, the operation
-- `TextOperation.new():retain(3):insert("Lorem"):delete(5)` is encoded as the
-- JSON object `[3, "Lorem", -5]` (or `{ 3, "Lorem", -5 }` in Lua)
function TextOperation:toJSON()
    return self.ops
end

-- Tests two operations for equality.
function TextOperation.__eq(self, other)
    if #self.ops ~= #other.ops then
        return false
    end

    for i=1, #self.ops do
        if self.ops[i] ~= other.ops[i] then
            return false
        end
    end

    return true
end

-- Skip over a given number of characters.
function TextOperation:retain(n)
    local ops = self.ops
    if n ~= 0 then
        if isRetain(ops[#ops]) then
            ops[#ops] = ops[#ops] + n
        else
            table.insert(ops, n)
        end
    end
    return self
end

-- Insert a string at the current position.
function TextOperation:insert(s)
    local ops = self.ops
    if utf8.len(s) ~= 0 then
        if isInsert(ops[#ops]) then
            ops[#ops] = ops[#ops] .. s
        elseif isDelete(ops[#ops]) then
            -- It doesn't matter when an operation is applied whether the operation
            -- is delete(3), insert("something") or insert("something"), delete(3).
            -- Here we enforce that in this case, the insert op always comes first.
            -- This makes all operations that have the same effect when applied to
            -- a document of the right length equal in respect to the `equals` method.
            if isInsert(ops[#ops-1]) then
                ops[#ops-1] = ops[#ops-1] .. s
            else
                table.insert(ops, ops[#ops])
                ops[#ops-1] = s
            end
        else
            table.insert(ops, s)
        end
    end
    return self
end

-- Delete a string at the current position.
function TextOperation:delete(n)
    local ops = self.ops
    if n ~= 0 then
        if n > 0 then
            n = -n
        end
        if isDelete(ops[#ops]) then
            ops[#ops] = ops[#ops] + n
        else
            table.insert(ops, n)
        end
    end
    return self
end

-- How many characters were added by the operations vs. deleted?
function TextOperation:lenDifference()
    local s = 0
    for i=1, #self.ops do
        local op = self.ops[i]
        if type(op) == "string" then
            s = s + utf8.len(op)
        elseif op < 0 then
            s = s + op
        end
    end
    return s
end

-- Apply an operation to a string, returning a new string. Throws an error if
-- there's a mismatch between the input string and the operation length.
function TextOperation:__call(doc)
    local parts = {}
    local len = 1

    for i=1, #self.ops do
        local op = self.ops[i]
        if isRetain(op) then
            if len + op > utf8.len(doc) + 1 then
                error("Cannot apply retain operation: operation is too long")
            end
            table.insert(parts, utf8.sub(doc, len, len + op - 1))
            len = len + op
        elseif isInsert(op) then
            table.insert(parts, op)
        else
            len = len - op
            if len > utf8.len(doc) + 1 then
                error("Cannot apply delete operation: operation is too long")
            end
        end
    end

    if len ~= utf8.len(doc) + 1 then
        error("Cannot apply operation: operation is too short")
    end

    return table.concat(parts, '')
end

-- Computes the inverse of an operation. The inverse of an operation is the
-- operation that reverts the effects of the operation, e.g. when you have an
-- operation 'insert("hello "); skip(6);' then the inverse is 'delete("hello ");
-- skip(6);'. The inverse should be used for implementing undo.
function TextOperation:invert(doc)
    local len = 1
    local inverse = TextOperation()

    for i=1, #self.ops do
        local op = self.ops[i]
        if isRetain(op) then
            inverse:retain(op)
            len = len + op
        elseif isInsert(op) then
            inverse:delete(utf8.len(op))
        else
            inverse:insert(utf8.sub(doc, len, len - op - 1))
            len = len - op
        end
    end

    return inverse
end

-- Compose merges two consecutive operations into one operation, that
-- preserves the changes of both. Or, in other words, for each input string S
-- and a pair of consecutive operations A and B,
-- apply(apply(S, A), B) = apply(S, compose(A, B)) must hold.
function TextOperation:compose(other)
    local ia = 1
    local ib = 1
    local operation = TextOperation()

    local a = nil
    local b = nil
    while true do
        if a == nil then
            a = self.ops[ia]
            ia = ia + 1
        end
        if b == nil then
            b = other.ops[ib]
            ib = ib + 1
        end

        if a == nil and b == nil then
            -- end condition: both operations have been processed
            break
        end

        if isDelete(a) then
            operation:delete(a)
            a = nil
        elseif isInsert(b) then
            operation:insert(b)
            b = nil
        elseif a == nil then
            error("Cannot compose operations: first operation is too short")
        elseif b == nil then
            error("Cannot compose operations: first operation is too long")
        else
            local minLen = math.min(opLen(a), opLen(b))
            if isRetain(a) and isRetain(b) then
                operation:retain(minLen)
            elseif isInsert(a) and isRetain(b) then
                operation:insert(utf8.sub(a, 1, minLen))
            elseif isRetain(a) and isDelete(b) then
                operation:delete(minLen)
            end
            -- remaining case: isInsert(a) and isDelete(b)
            -- in this case the delete op deletes the text that has been added
            -- by the insert operation and we don't need to do anything

            a, b = shortenOps(a, b)
        end
    end

    return operation
end

-- a .. b is a synonym for a:compose(b).
function TextOperation.__concat(a, b)
    return a:compose(b)
end

-- Transform takes two operations A and B that happened concurrently and
-- returns two operations A' and B' such that
-- apply(apply(S, A), B') = apply(apply(S, B), A'). This function is the heart
-- of OT.
function TextOperation.transform(operationA, operationB)
    local ia = 1
    local ib = 1
    local aPrime = TextOperation()
    local bPrime = TextOperation()
    local a = nil
    local b = nil

    while true do
        if a == nil then
            a = operationA.ops[ia]
            ia = ia + 1
        end
        if b == nil then
            b = operationB.ops[ib]
            ib = ib + 1
        end

        if a == nil and b == nil then
            -- end condition: both operations have been processed
            break
        end

        if isInsert(a) then
            aPrime:insert(a)
            bPrime:retain(utf8.len(a))
            a = nil
        elseif isInsert(b) then
            aPrime:retain(utf8.len(b))
            bPrime:insert(b)
            b = nil
        elseif a == nil then
            error("Cannot compose operations (" .. operationA .. ", " .. operationB .. "): first operation is too short")
        elseif b == nil then
            error("Cannot compose operations (" .. operationA .. ", " .. operationB .. "): first operation is too long")
        else
            local minLen = math.min(opLen(a), opLen(b))
            if isRetain(a) and isRetain(b) then
                aPrime:retain(minLen)
                bPrime:retain(minLen)
            elseif isDelete(a) and isRetain(b) then
                aPrime:delete(minLen)
            elseif isRetain(a) and isDelete(b) then
                bPrime:delete(minLen)
            end
            -- remaining case: _is_delete(a) and _is_delete(b)
            -- in this case both operations delete the same string and we don't
            -- need to do anything

            a, b = shortenOps(a, b)
        end
    end

    return aPrime, bPrime
end

function TextOperation:__tostring()
    local t = {"TextOperation: "}
    for _,op in pairs(self.ops) do
        local type
        if isRetain(op) then type = "retain"
        elseif isInsert(op) then type = "insert"
        else type = "delete" end

        table.insert(t, "(" .. type .. " " .. op .. ")")
    end

    return table.concat(t, "")
end

gace.ot = {}
gace.ot.TextOperation = TextOperation

gace.ot.Sessions = {}

local function SessionExists(id)
    return gace.ot.Sessions[id] ~= nil
end

local function GetSession(id)
    return gace.ot.Sessions[id]
end

local function CreateSession(id, ply)
    if SessionExists(id) then
        return gace.RejectedATPromise(id .. " otsess already exists")
    end

    local promise = ATPromise()

    if id:EndsWith(".ot") then
        promise = promise:then_(function()
            local path = id:sub(1, -4)
            return gace.cmd.cat(ply, path)
        end)
    end

    return promise:then_(function(doc)
        local s = {
            srv = Server.new(doc or "", MemoryBackend.new()),
            id = id,

            clients = {},
            cursors = {}
        }
        gace.ot.Sessions[id] = s

        return s
    end)
end

gace.AddHook("PreSaveMeta", "OT_OverwriteOriginalsWithOT", function(event)
    if not event.path:EndsWith(".ot") then return end

    -- TODO add check:
    --      if non-.ot file exists and .ot doesn't: overwrite
    --      if neither exist: overwrite
    --      if non-.ot doesn't exist and .ot does:  don't overwrite
    --      if both exist: don't overwrite

    -- remove .ot extension
    event.path = event.path:sub(1, -4)
end)

gace.AddHook("HandleNetMessage", "HandleOT", function(netmsg)
    local ply = netmsg:GetSender()
    local op = netmsg:GetOpcode()
    local reqid = netmsg:GetReqId()
    local payload = netmsg:GetPayload()

    local function CheckPath(normpath)
        if not gace.path.validate(normpath) then return gace.RejectedATPromise(gace.VFS.ErrorCode.INVALID_NAME) end

        local _, normpath_folder = gace.path.tail(normpath)
        return gace.fs.resolve(normpath_folder):then_(function(node)
            if not node:hasPermission(ply, gace.VFS.Permission.READ) or not node:hasPermission(ply, gace.VFS.Permission.WRITE) then
                return error(gace.VFS.ErrorCode.ACCESS_DENIED)
            end
            return
        end)
    end

    if op == "ot-sub" then
        local normpath = gace.path.normalize(payload.id)
        CheckPath(payload.id):then_(function()
            local function Subscribe(sess)
                if not table.HasValue(sess.clients, ply) then
                    table.insert(sess.clients, ply)
                end

                netmsg:CreateResponseMessage("ot-sub", {
                    rev = sess.srv.backend:getRevision(),
                    doc = sess.srv.document,
                    cursors = sess.cursors
                }):Send()
            end

            local sess = GetSession(normpath)
            if sess then
                Subscribe(sess)
            else
                return CreateSession(normpath, ply):then_(function(createdSess)
                    Subscribe(createdSess)
                end)
            end
        end):catch(function(e)
            netmsg:CreateResponseMessage("ot-sub", {err = e}):Send()
        end)
    elseif op == "ot-unsub" then
        local normpath = gace.path.normalize(payload.id)
        if not SessionExists(normpath) then
            return
        end

        local sess = GetSession(normpath)
        if sess then
            table.RemoveByValue(sess.clients, ply)

            if _u.reduce(sess.clients, 0, function(o, i) return o + (IsValid(i) and 1 or 0) end) == 0 then
                gace.Debug("Removing OT session due to all valid clients unsubscribing")
                gace.ot.Sessions[payload.id] = nil
            end
        end
    elseif op == "ot-cursor" then
        local normpath = gace.path.normalize(payload.id)
        CheckPath(payload.id):then_(function()
            local sess = GetSession(normpath)
            if not sess then return end

            if not table.HasValue(sess.clients, ply) then
                return
            end

            sess.cursors[ply:UserID()] = {start = payload.start, ["end"] = payload["end"]}

            gace.Debug("OT: ", normpath, " ", ply, " new cursor pos: ", table.ToString(sess.cursors[ply:UserID()]))

            local filtered = _u.filter(sess.clients, function(cl) return IsValid(cl) and cl ~= ply end)
            _u.each(filtered, function(cl)
                gace.NetMessageOut("ot-cursorsv", {
                    cursorid = ply:UserID(),
                    id = normpath,
                    cursor = sess.cursors[ply:UserID()]
                }):Send(cl)
            end)
        end):catch(function(e)
            netmsg:CreateResponseMessage("ot-cursor", {err = e}):Send()
        end)

    elseif op == "ot-apply" then
        local normpath = gace.path.normalize(payload.id)
        CheckPath(payload.id):then_(function()
            if not SessionExists(normpath) then
                error("session doesn't exist")
                return
            end

            local sess = GetSession(normpath)
            if not table.HasValue(sess.clients, ply) then
                netmsg:CreateResponseMessage("ot-apply", {err = "not subscribed"}):Send()
                return
            end

            local recv_op = TextOperation.fromJSON(payload.op)
            local new_op = sess.srv:receiveOperation(payload.rev, recv_op)

            gace.Debug("OT: ", normpath, "server state: rev", sess.srv.backend:getRevision(), " doc", sess.srv.document)

            local pl = {
                user = ply,
                id = normpath,
                op = new_op:toJSON()
            }

            local filtered = _u.filter(sess.clients, function(cl) return IsValid(cl) end)
            _u.each(filtered, function(cl)
                gace.NetMessageOut("ot-applysv", pl):Send(cl)
            end)
        end):catch(function(e)
            gace.Log(gace.LOG_ERROR, "ot-apply failed: ", e)
        end)
    end

end)
