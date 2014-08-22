
-- A VGui panel that makes creating dynamic layouts fairly easy

local PANEL = {}

PANEL.IsDynPanel = true

function PANEL:Init()
	self:SetDrawBackground(false)

	self.DynIdMappings = {}
	self.DockedPanels = {
		[LEFT] = {},
		[TOP] = {},
		[RIGHT] = {},
		[BOTTOM] = {},
		[FILL] = nil
	}
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

	dockpos = dockpos or FILL

	if dockpos == FILL then
		self.DockedPanels[FILL] = pnl
	else
		table.insert(self.DockedPanels[dockpos], pnl)
	end

	return self
end

-- Reversed ipairs. From http://lua-users.org/wiki/IteratorsTutorial
local function ripairs(t)
  local function ripairs_it(t,i)
    i=i-1
    local v=t[i]
    if v==nil then return v end
    return i,v
  end
  return ripairs_it, t, #t+1
end

function PANEL:PerformLayout()
	-- First set all children to basically invisible. We re-set properly configured children later
	--[[for _,child in pairs(self:GetChildren()) do
		child:SetPos(0, 0)
		child:SetSize(0, 0)
	end]]

	local par_width, par_height = self:GetSize()

	local off_left, off_right, off_top, off_bottom = 0, 0, 0, 0

	-- TOP and BOTTOM are first because they are prioritized over LEFT and RIGHT
	-- So ex. a TOP bar is shown over a LEFT sidebar 

	do
		for idx, pnl in ipairs(self.DockedPanels[TOP]) do
			pnl:StretchToParent(0, off_top, 0, nil)
			pnl:InvalidateLayout()
			off_top = off_top + pnl:GetTall()
		end
	end

	do
		for idx, pnl in ipairs(self.DockedPanels[BOTTOM]) do
			pnl:StretchToParent(0, par_height-pnl:GetTall()-off_bottom, 0, off_bottom)
			pnl:InvalidateLayout()

			off_bottom = off_bottom + pnl:GetTall()
		end
	end

	do
		for idx, pnl in ipairs(self.DockedPanels[LEFT]) do
			pnl:StretchToParent(off_left, off_top, nil, off_bottom)
			pnl:InvalidateLayout()
			off_left = off_left + pnl:GetWide()
		end
	end

	do
		for idx, pnl in ipairs(self.DockedPanels[RIGHT]) do
			pnl:StretchToParent(par_width - pnl:GetWide()-off_right, off_top, off_right, off_bottom)
			pnl:InvalidateLayout()
			off_right = off_right + pnl:GetWide()
		end
	end

	--print(self.DynPanelId, off_left, off_right, off_top, off_bottom)

	if IsValid(self.DockedPanels[FILL]) then
		local pnl = self.DockedPanels[FILL]

		pnl:StretchToParent(off_left, off_top, off_right, off_bottom)
		pnl:InvalidateLayout()
		--pnl:SetSize((par_width - off_right)-off_left, (par_height - off_bottom)-off_top)
		--print("pos: ", pnl:GetPos())
		--print("size: ", pnl:GetSize())
	end
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