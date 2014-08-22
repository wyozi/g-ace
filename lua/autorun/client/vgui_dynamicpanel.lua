
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
	if id then
		self:StorePanelId(id, pnl)
		pnl.DynPanelId = id
	end

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

	if self.TargetWide and self:GetWide() ~= self.TargetWide then
		self:SetWide(self.TargetWide)
	end

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

	if IsValid(self.DockedPanels[FILL]) then
		local pnl = self.DockedPanels[FILL]

		pnl:StretchToParent(off_left, off_top, off_right, off_bottom)
		pnl:InvalidateLayout()
	end
end

function PANEL:AddDivider(dockpos)
	if dockpos ~= LEFT and
		dockpos ~= RIGHT and
		dockpos ~= TOP and
		dockpos ~= BOTTOM then
		return
	end

	-- We need to reverse dockpos
	if dockpos == LEFT then
		dockpos = RIGHT
	elseif dockpos == RIGHT then
		dockpos = LEFT
	elseif dockpos == TOP then
		dockpos = BOTTOM
	elseif dockpos == BOTTOM then
		dockpos = TOP
	end

	local bar = vgui.Create("DDynPanelDividerBar")
	bar:Setup(dockpos)

	bar:SetSize(8, 8)

	self:AddDocked(nil, bar, dockpos)
end

function PANEL:AddSubPanel(id, dockpos)
	local v = vgui.Create("DDynPanel")
	self:AddDocked(id, v, dockpos)
	v:AddDivider(dockpos)
	return v
end

function PANEL:OnChildRemoved(child)
	if not child.DynPanelId then return end
	self:RemovePanelId(child.DynPanelId)
end

function PANEL:OnCursorMoved( x, y )
	if (self.Dragging ~= self) then return end
	self.DragPos = x - self.HoldPos[1]
	self.TargetWide = self.DragPos
	self:InvalidateLayout(true)
end

function PANEL:OnMouseReleased( mcode )
	if (mcode == MOUSE_LEFT) then
		self:SetCursor("none")
		self.Dragging = false
		self:MouseCapture(false)
	end
end

derma.DefineControl( "DDynPanel", "", PANEL, "DPanel" )

local PANEL = {}

function PANEL:Init()
	self:SetPaintBackground( false )
end

function PANEL:Setup(docking)
	if docking == LEFT or docking == RIGHT then
		self:SetCursor("sizewe")
	else
		self:SetCursor("sizens")
	end
end

function PANEL:OnMousePressed( mcode )
	if ( mcode == MOUSE_LEFT ) then
		self:GetParent().Dragging =  self:GetParent()
		self:GetParent().HoldPos = {self:CursorPos()}
		self:GetParent():MouseCapture(true)
	end
end

function PANEL:Paint(w, h)
	surface.SetMaterial(Material("phoenix_storms/metalfloor_2-3.vmt"))
	surface.DrawTexturedRect(0, 0, w, h)
end

derma.DefineControl( "DDynPanelDividerBar", "", PANEL, "DPanel" )