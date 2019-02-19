gace.CollabPositions = gace.CollabPositions or {}

local _avatarPanels = setmetatable({}, {__mode = "k"})

gace.AddHook("FileTreeFileNodePostPaint", "FileTree_DrawCollaboratorAvatars", function(self, vars)
	local collabs = {}
	for k,v in pairs(gace.CollabPositions) do
		if IsValid(k) and v == self.NodeId then
			table.insert(collabs, k)
		end
	end

	for idx,ply in pairs(collabs) do
		local avatar = _avatarPanels[ply]
		if not IsValid(avatar) then
			avatar = vgui.Create("AvatarImage")
			avatar:SetPlayer(ply, 16)
			avatar:SetToolTip(ply:Nick())
			avatar:SetPaintedManually(true)
			
			_avatarPanels[ply] = avatar
		end
		
		local x = vars.draw_x - (idx-1)*18
		
		avatar:SetParent(self)
		avatar:SetPos(x, 2)
		avatar:SetSize(16, 16)
		avatar:PaintManual()
		
		draw.SimpleTextOutlined(ply:Nick():sub(1,1), "DermaDefaultBold", x + 8, 9, Color(197, 239, 247), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
	end
end)

local hasSentNotifyListenRequest = false
gace.AddHook("OnSessionOpened", "HandleCollaboratorNotifications", function(id)
	-- this is quite ghetto but keeps all code neatly here
	if not hasSentNotifyListenRequest then
		local msg = gace.NetMessageOut("collab-notify-listen")
		msg:Send()
		hasSentNotifyListenRequest = true
	end
	
	local msg = gace.NetMessageOut("collab-notify-open", { path = id })
	msg:Send()
end)

gace.AddHook("HandleNetMessage", "HandleCollaboratorNotifications", function(netmsg)
    local op = netmsg:GetOpcode()
    local reqid = netmsg:GetReqId()
    local payload = netmsg:GetPayload()

    if op == "collab-notify-open" then
    	gace.CollabPositions[payload.player] = payload.path
    end
end)
