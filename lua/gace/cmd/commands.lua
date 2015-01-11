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
            return ErrorNoHalt(tostring(caller) .. " is not player!")
        end

        local r, err = gace.ParseArguments(opts.args, ...)
        if not r then
            return ErrorNoHalt("invalid argument: " .. err)
        end

        return opts.func(caller, unpack(r))
    end
end

function gace.RegisterCommand(cmd, opts)
    opts.callback = gace.CreateCommandCallback(cmd, opts)
    gace.cmd.Commands[cmd] = opts
end

function gace.ParseArguments(target_args, ...)
    local args = {...}
    local parsed_args = {}

    local function fail(i, msg)
        return false, string.format("Invalid '%s' (#%d): %s", target_args[i].name, i, msg)
    end

    for i=1, #target_args do
        local t_arg = target_args[i]
        local p_arg = args[i]

        if not p_arg then
            if t_arg.default then
                p_arg = t_arg.default
            else
                return fail(i, "missing")
            end
        end

        if t_arg.type == "player" and type(p_arg) ~= "Player" then
            if type(p_arg) ~= "string" then return fail(i, "type is not string or player?") end

            local low_p_arg = p_arg:lower()
            local found_ply
            for _,ply in pairs(player.GetAll()) do
                if ply:Nick():lower():find(low_p_arg) then
                    found_ply = ply
                    break
                end
            end

            if not found_ply then
                return fail(i, "player not found")
            end

            p_arg = found_ply
        end

        parsed_args[i] = p_arg
    end

    return parsed_args
end

gace.RegisterCommand("help", {
    name = "Help",
    help = "Shows available commands",
    args = {},
    func = function(caller)
        caller:GAce_Msg(Color(170, 255, 255), "=== G-Ace Command System Help ===")

        for name, cmd in pairs(gace.cmd.Commands) do
            caller:GAce_Msg(Color(127, 255, 255), string.format("%-12s - %s", name, cmd.help))
        end
    end,
})

concommand.Add("gace", function(ply, cmd, args)
    local gace_cmd = table.remove(args, 1) or "help"
    local gace_cmdfunc = gace.cmd[gace_cmd] or gace.cmd.help

    gace_cmdfunc(ply, unpack(args))
end)
