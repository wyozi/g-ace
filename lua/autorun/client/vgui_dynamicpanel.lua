
-- A VGui panel that makes creating dynamic layouts fairly easy

local PANEL = {}

PANEL.IsDynPanel = true

function PANEL:Init()
	self:SetDrawBackground(false)
	self.DynIdMappings = {}
end

function PANEL:StorePanelId(id, pnl)
	local par = self:GetParent()
	if IsValid(par) and par.IsDynPanel then
		par:StorePanelId(id, pnl)
	end

	self.DynIdMappings[id] = pnl
end
function PANEL:RemovePanelId(id)
	local par = self:GetParent()
	if IsValid(par) and par.IsDynPanel then
		par:RemovePanelId(id)
	end

	self.DynIdMappings[id] = nil
end

function PANEL:GetById(id)
	return self.DynIdMappings[id]
end

function PANEL:AddRaw(id, pnl)
	self:StorePanelId(id, pnl)

	pnl.DynPanelId = id
	self:Add(pnl)

	return self
end
function PANEL:AddDocked(id, pnl, dockpos)
	self:AddRaw(id, pnl)
	pnl:Dock(dockpos or FILL)

	return self
end


function PANEL:AddSubPanel(id, dockpos)
	local v = vgui.Create("DDynPanel")
	self:AddDocked(id, v, dockpos)
	return v
end

function PANEL:OnChildRemoved(child)
	if not child.DynPanelId then return end
	self:RemovePanelId(child.DynPanelId)
end

derma.DefineControl( "DDynPanel", "", PANEL, "DPanel" )