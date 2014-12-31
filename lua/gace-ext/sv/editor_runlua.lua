-- Running newly created unsaved files requires a gace.VFS.Permission.EXECUTE
-- on the root folder

gace.luarun = {}

function gace.luarun.test_compile(code, code_id)
    local fn = CompileString(code, code_id, false)
    if type(fn) == "string" then
        return false, ("Compilation error: " .. fn)
    end
    return true, fn
end

function gace.luarun.server(code, code_id)
    local status, ret = gace.luarun.test_compile(code, code_id)
    if not status then
        return status, ret
    end

    ret()

    return true
end
function gace.luarun.client(cl, code, code_id)
    local status, ret = gace.luarun.test_compile(code, code_id)
    if not status then
        return status, ret
    end

    gace.NetMessageOut(0, "lua-runclient", {code = code, code_id = code_id}):Send(cl)

    return true
end
function gace.luarun.clients(code, code_id)
    local status, ret = gace.luarun.test_compile(code, code_id)
    if not status then
        return status, ret
    end

    for _,ply in pairs(player.GetAll()) do
        gace.NetMessageOut(0, "lua-runclient", {code = code, code_id = code_id}):Send(ply)
    end

    return true
end
function gace.luarun.shared(code, code_id)
    local status, ret = gace.luarun.server(code, code_id)
    if not status then
        return status, ret
    end

    local status, ret = gace.luarun.clients(code, code_id)
    if not status then
        return status, ret
    end

    return true
end

gace.AddHook("HandleNetMessage", "HandleLuaRun", function(netmsg)
	local ply = netmsg:GetSender()
	local op = netmsg:GetOpcode()
	local reqid = netmsg:GetReqId()
	local payload = netmsg:GetPayload()

    local function CheckPermission()
        return gace.fs.resolve(""):then_(function(node)
            return node:checkPermission(ply, gace.VFS.Permission.EXECUTE)
        end)
    end

    local function HandleOp(callback)
        local code_id = string.format("%s by %s (%s)", op, ply:Nick(), ply:SteamID())

        CheckPermission():then_(function()
            local r, e = callback(payload.code or "", code_id)
            if not r then
                return gace.RejectedPromise(e)
            end

            netmsg:CreateResponsePacket(op, {}):Send()
        end):catch(function(e)
            netmsg:CreateResponsePacket(op, {err = e}):Send()
		end)
    end

	-- Git integration
	if op == "lua-runsv" then
        HandleOp(function(code, code_id)
            return gace.luarun.server(code, code_id)
        end)
	elseif op == "lua-runsh" then
        HandleOp(function(code, code_id)
            return gace.luarun.shared(code, code_id)
        end)
	elseif op == "lua-runcl" then
        HandleOp(function(code, code_id)
            return gace.luarun.clients(code, code_id)
        end)
	elseif op == "lua-runself" then
        HandleOp(function(code, code_id)
            return gace.luarun.client(ply, code, code_id)
        end)
	end
end)
