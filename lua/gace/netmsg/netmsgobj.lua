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

AccessorFunc(netmsg_meta, "response", "IsResponse")

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

function netmsg_out_meta:ListenToResponse(callback)
    if not gace.reqid.validate(self:GetReqId()) then
        self:SetReqId(gace.reqid.generate())
    end
    self.protocol.Listen(self, callback)

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

    self.protocol.Send(self)
end

function netmsg_out_meta:Clone()
    local cloned = gace.NetMessageOut(self:GetOpcode(), self:GetPayload(), self.protocol)
    cloned:SetReqId(self:GetReqId())
    if SERVER then cloned:SetTarget(self:GetTarget()) end
    return cloned
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

function netmsg_in_meta:CreateResponseMessage(op, payload)
    if not gace.reqid.validate(self:GetReqId()) then return error("creating a response message with invalid reqid") end
    local netmsg = gace.NetMessageOut(op or self:GetOpcode(), payload)
    netmsg:SetReqId(self:GetReqId())
    netmsg:SetIsResponse(true)

    if SERVER then netmsg:SetTarget(self:GetSender()) end

    return netmsg
end

function netmsg_in_meta:Clone()
    local cloned = gace.NetMessageIn(self:GetOpcode(), self:GetReqId(), self:GetPayload(), self.protocol)
    if SERVER then cloned:SetSender(self:GetSender()) end
    return cloned
end

netmsg_in_meta.CreateResponsePacket = netmsg_in_meta.CreateResponseMessage

--[[
Constructors
]]
gace.NetMessageIn = function(op, reqid, payload, protocol)
    reqid = reqid or ""
    payload = payload or {}
    if not op then
        return error("opcode required!")
    end

    local msg = {reqid = reqid, op = op, payload = payload, protocol = protocol or gace.NetMessageDefaultProtocol}
    setmetatable(msg, netmsg_in_meta)
    return msg
end
gace.NetMessageOut = function(op, payload, protocol)
    payload = payload or {}
    if not op then
        return error("opcode required!")
    end

    local msg = {op = op, payload = payload, protocol = protocol or gace.NetMessageDefaultProtocol}
    setmetatable(msg, netmsg_out_meta)
    return msg
end
