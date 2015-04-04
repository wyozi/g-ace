gace.cmd = gace.cmd or {}
gace.cmd.Commands = gace.cmd.Commands or {}

setmetatable(gace.cmd, {
    __index = function(tbl, key)
        local thecmd = gace.cmd.Commands[key]
        if thecmd then
            return thecmd.callback
        end
    end
})

local server_caller = {
    IsValid = function() return false end,
    GAce_Msg = function(...) MsgC(...) MsgN() end
}

local plymeta = FindMetaTable("Player")
function plymeta:GAce_Msg(...)
    if CLIENT then
        MsgC(...)
        MsgN()
        gace.Log(...)
    end
    if SERVER then
        net.Start("gace_cmd_msg")
        net.WriteTable({...})
        net.Send(self)
    end
end

if SERVER then
    util.AddNetworkString("gace_cmd_msg")
end
if CLIENT then
    net.Receive("gace_cmd_msg", function()
        LocalPlayer():GAce_Msg(unpack(net.ReadTable()))
    end)
end

function gace.CreateCommandCallback(cmd, opts)
    return function(caller, ...)
        if not IsValid(caller) then
            caller = server_caller
        elseif type(caller) ~= "Player" then
            return error(tostring(caller) .. " is not player!")
        end

        local r, err = gace.ParseArguments(opts.args, ...)
        if not r then
            return error("invalid argument: " .. err)
        end

        local hookret = gace.CallHook("PreCommandCall", cmd, opts, caller, r)
        if hookret then
            return hookret, caller
        end

        local ret = opts.func(caller, unpack(r))

        local hookret = gace.CallHook("PostCommandCall", cmd, opts, caller, ret, r)
        if hookret then
            return hookret, caller
        end

        return ret, caller
    end
end

function gace.RegisterCommand(cmd, opts)
    opts.callback = gace.CreateCommandCallback(cmd, opts)
    opts.callback_tostring = function(caller, ...)
        local ret, caller = opts.callback(caller, ...)
        if opts.func_tostring then
            opts.func_tostring(caller, ret)
        end
    end
    opts.callback_ipc = function(caller, request, ...)
        local ret, caller = opts.callback(caller, ...)
        opts.func_ipc(caller, request, ret)
    end
    gace.cmd.Commands[cmd] = opts
end

function gace.ParseArguments(target_args, ...)
    local args = {...}
    local parsed_args = {}

    local function fail(i, msg)
        return false, string.format("Invalid '%s' (#%d): %s", target_args[i].name, i, msg)
    end

    local i_target = 1
    local i_arg = 1

    while i_target <= #target_args do
        local t_arg = target_args[i_target]
        local p_arg = args[i_arg]

        local incr_iarg = true

        if p_arg == nil then
            if parsed_args[i_target] and t_arg.take_rest then
                break
            elseif t_arg.default then
                p_arg = t_arg.default
            elseif t_arg.optional then
                break -- TODO I'd rather continue just because, but it is not vanilla lua..
            else
                return fail(i_target, "missing")
            end
        end

        if t_arg.type == "player" and type(p_arg) ~= "Player" then
            if type(p_arg) ~= "string" then return fail(i_target, "type is not string or player?") end

            local low_p_arg = p_arg:lower()
            local found_ply
            for _,ply in pairs(player.GetAll()) do
                if ply:Nick():lower():find(low_p_arg) then
                    found_ply = ply
                    break
                end
            end

            if not found_ply then
                return fail(i_target, "player not found")
            end

            p_arg = found_ply
        end

        if t_arg.type == "string" and t_arg.take_rest then
            incr_iarg = false
            p_arg = (parsed_args[i_target] or "") .. p_arg
        end

        if t_arg.type == "bool" then
            p_arg = p_arg == true or (type(p_arg) == "string" and string.lower(string.Trim(p_arg)) == "true")
        end

        parsed_args[i_target] = p_arg

        i_target = i_target + 1
        if incr_iarg then
            i_arg = i_arg + 1
        end
    end

    return parsed_args
end

gace.RegisterCommand("inexistentcmd", {
    nohelp = true,
    args = {},
    func = function(caller)
        caller:GAce_Msg(gace.LOG_WARN, "Inexistent command. Use 'help' to see all available commands.")
    end,
})
gace.RegisterCommand("help", {
    name = "Help",
    help = "Shows available commands",
    args = {},
    func = function(caller)
        caller:GAce_Msg(gace.LOG_INFO, "=== G-Ace Command System Help ===")

        for name, cmd in pairs(gace.cmd.Commands) do
            if not cmd.nohelp then
                caller:GAce_Msg(string.format("%-12s - %s", name, cmd.help))
            end
        end
    end,
})

if SERVER then
    local gace_cb = function(ply, cmd, args)
        local gace_cmd = table.remove(args, 1) or "help"
        local gace_cmdopts = gace.cmd.Commands[gace_cmd] or gace.cmd.Commands.inexistentcmd

        local ret, err = pcall(gace_cmdopts.callback_tostring, ply, unpack(args))
        if not ret then
            ply:GAce_Msg(gace.LOG_ERROR, err)
        end
    end
    concommand.Add("_gace", gace_cb)
    concommand.Add("gace", gace_cb)

    concommand.Add("_gacecmd", gace_cb)
end

if CLIENT then
    concommand.Add("gace", function(ply, cmd, args, fullline)
        RunConsoleCommand("_gacecmd", unpack(args))
    end)
end
