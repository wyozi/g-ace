if SERVER then util.AddNetworkString("gace_net") end

local NETMSG_SPLIT_THRESHOLD = 58000

local NETMSG_FLAG_CHUNKED = 1 -- if sent in multiple parts
local NETMSG_FLAG_LASTCHUNK = 2 -- if this is the last part

local NETMSG_FLAG_RESPONSE = 4 -- if this is a response

--- Stores incomplete chunks
-- On CLIENT this is a simple key value map of reqid and incomplete chunks
-- On SERVER this is a map where key is player and value is a k-v map
local chunk_buffer = {}
if SERVER then
	-- dc'd or otherwise removed players' keys should disappear
	setmetatable(chunk_buffer, {__mode = "k"})
end

local function GetChunkBuffer(cl, reqid)
	if SERVER then
		chunk_buffer[cl] = chunk_buffer[cl] or {}
		chunk_buffer[cl][reqid] = chunk_buffer[cl][reqid] or {}
		return chunk_buffer[cl][reqid]
	end
	if CLIENT then
		chunk_buffer[reqid] = chunk_buffer[reqid] or {}
		return chunk_buffer[reqid]
	end
end

net.Receive("gace_net", function(len, cl)
	local reqid = net.ReadString()
	local op = net.ReadString()
	local flags = net.ReadUInt(32)

	-- Responses should not have opcodes
	if bit.band(flags, NETMSG_FLAG_RESPONSE) == NETMSG_FLAG_RESPONSE then
		op = ""
	end

	local payload = gace.netschemas.Read(op)

	gace.Debug("Received net message ", op, " with reqid: ", reqid, "; length: ", len, "; ", (bit.band(flags, NETMSG_FLAG_CHUNKED) == NETMSG_FLAG_CHUNKED) and "CHUNKED" or "")
	-- TODO this should be shown if another cvar is on? or maybe written to a file
	--if gace.IsDebug() then
	--	gace.Debug("Payload: ")
	--	PrintTable(payload)
	--end

	if bit.band(flags, NETMSG_FLAG_CHUNKED) == NETMSG_FLAG_CHUNKED then
		if not gace.reqid.validate(reqid) then
			gace.Log(gace.LOG_ERROR, "Received chunked netmsg with no reqid!")
			return
		end

		local buffer = GetChunkBuffer(cl, reqid)
		gace.tablesplit.MergeInto(buffer, payload)

		-- If it's not the last chunk, return from the whole function
		if bit.band(flags, NETMSG_FLAG_LASTCHUNK) ~= NETMSG_FLAG_LASTCHUNK then
			return
		end

		-- Otherwise reset flags and set payload to buffer
		flags = 0
		payload = buffer
	end

	local netmsg = gace.NetMessageIn(op, reqid, payload)

	if SERVER then
		netmsg:SetSender(cl)
	end

	gace.CallHook("HandleNetMessage", netmsg)
end)

function gace.SendNetMessage(netmsg, flags)
	local reqid = netmsg:GetReqId() or ""
	local op = netmsg:GetOpcode()
	local flags = flags or 0
	local payload = netmsg:GetPayload()

	if netmsg:GetIsResponse() then
		op = ""
		flags = bit.bor(flags, NETMSG_FLAG_RESPONSE)
	end

	-- See if we need to split this netmsg
	local estsize = gace.tablesplit.ComputeSize(payload, 1)

	-- If we're close to the magical 64kB limit, should split into multiple packets
	if estsize >= NETMSG_SPLIT_THRESHOLD then
		-- Chunked messages need reqid; it is used to figure out which net packets
		-- are part of the same message
		if not gace.reqid.validate(reqid) then
			netmsg:SetReqId(gace.reqid.generate())
		end

		local chunks = gace.tablesplit.Split(payload, NETMSG_SPLIT_THRESHOLD - 1000)

		gace.Debug("NetMsg ", netmsg:GetOpcode(), " with reqid ", netmsg:GetReqId(), " is above split threshold. Sending it in ", #chunks, " chunks")

		for i=1, #chunks do
			local chunk = chunks[i]
			local is_last = i == #chunks

			local clone = netmsg:Clone()
			clone:SetPayload(chunk)

			local flags = NETMSG_FLAG_CHUNKED
			if is_last then flags = bit.bor(flags, NETMSG_FLAG_LASTCHUNK) end

			gace.SendNetMessage(clone, flags)
		end

		return
	end

	net.Start("gace_net")

	net.WriteString(reqid)
	net.WriteString(op)
	net.WriteUInt(flags, 32)
	gace.netschemas.Write(op, payload)

	gace.Debug("Sending net message ", netmsg:GetOpcode(), " with reqid ", netmsg:GetReqId(), "; estimated size: ", estsize, "; actual size: ", net.BytesWritten())

	if SERVER then
		net.Send(netmsg:GetTarget())
	else
		net.SendToServer()
	end
end
