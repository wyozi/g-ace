-- A wrapper object for a net message
--
-- Usually constructed internally (see client/cl_networking.lua and server/networking.lua)
-- but is used in net message handling hooks ("HandleNetMessage")
--
-- Net message object uses inheritance pattern:
--  netmsg_meta is the base for all net message objects
--  netmsg_out_meta is the metatable of outgoing packets
--  netmsg_in_meta is the metatable of incoming packets

-- The base class of all net messages
local netmsg_meta = {}
netmsg_meta.__index = netmsg_meta

AccessorFunc(netmsg_meta, "reqid", "ReqId")
AccessorFunc(netmsg_meta, "op", "Opcode")

function netmsg_meta:IsOpcode(op)
    return self:GetOpcode() == op
end

AccessorFunc(netmsg_meta, "payload", "Payload")

--[[
Outgoing packet metatable
]]
local netmsg_out_meta = {}
netmsg_out_meta.__index = netmsg_out_meta
setmetatable(netmsg_out_meta, netmsg_meta)

if SERVER then
    AccessorFunc(netmsg_out_meta, "target", "Target")
end

gace.NetMsgListeners = {}
gace.AddHook("HandleNetMessage", "_ResponseToListeners", function(packet)
    local listener = gace.NetMsgListeners[packet:GetReqId()]
    if listener then
        listener(packet:GetReqId(), packet:GetOpcode(), packet:GetPayload())
    end
end)

function netmsg_out_meta:ListenToResponse(callback)
    gace.NetMsgListeners[self:GetReqId()] = callback

    return self
end

function netmsg_out_meta:Send(targ)
    if self.sent then return error("trying to send the same net message twice") end
    self.sent = true

    if SERVER and not IsValid(self:GetTarget()) then
        if IsValid(targ) then
            self:SetTarget(targ)
        else
            return error("trying to send serverside netmsg without a valid target")
        end
    end

    gace.SendNetMessage(self)
end

--[[
Incoming packet metatable
]]
local netmsg_in_meta = {}
netmsg_in_meta.__index = netmsg_in_meta
setmetatable(netmsg_in_meta, netmsg_meta)

if SERVER then
    AccessorFunc(netmsg_in_meta, "sender", "Sender")
end

function netmsg_in_meta:CreateResponsePacket(op, payload)
    if not self:GetReqId() or self:GetReqId() == "" then return error("trying to response to packet with no req id") end
    local netmsg = gace.NetMessageOut(self:GetReqId(), op, payload)

    if SERVER then netmsg:SetTarget(self:GetSender()) end

    return netmsg
end

--[[
Constructors
]]
gace.NetMessageIn = function(reqid, op, payload)
    reqid = reqid or ""
    payload = payload or {}
    if not op then
        return error("reqid and/or opcode required!")
    end

    local msg = {reqid = reqid, op = op, payload = payload}
    setmetatable(msg, netmsg_in_meta)
    return msg
end
gace.NetMessageOut = function(reqid, op, payload)
    reqid = reqid or ""
    payload = payload or {}
    if not op then
        return error("reqid and/or opcode required!")
    end

    local msg = {reqid = reqid, op = op, payload = payload}
    setmetatable(msg, netmsg_out_meta)
    return msg
end
