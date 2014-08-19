gace.AddHook("FileTreeNodePaint", "FileTree_DrawCollaboratorAvatars", function(self, w, h)
	-- TODO collaborator stuff

	local collabs = {}
	--for k,v in pairs(gace.CollabPositions) do
	--	if IsValid(k) and v == self.Path then
	--		table.insert(collabs, k)
	--	end
	--end

	for idx,c in pairs(collabs) do
		if not IsValid(c.CollabAvatar) then
			c.CollabAvatar = vgui.Create("AvatarImage")
			c.CollabAvatar:SetPlayer(c, 16)
			c.CollabAvatar:SetToolTip(c:Nick())
			c.CollabAvatar.Think = function(self)
				if not IsValid(c) or self:GetParent().Path ~= gace.CollabPositions[c] then
					self:SetParent(nil)
					self:SetVisible(false)
				end
			end
		end
		c.CollabAvatar:SetVisible(true)
		c.CollabAvatar:SetParent(self)
		c.CollabAvatar:SetPos(w-idx*16, 0)
		c.CollabAvatar:SetSize(16, 16)
		--draw.SimpleText(c:Nick():sub(1,1), "DermaDefaultBold", w-idx*10, 2, Color(0, 0, 0))
	end
end)