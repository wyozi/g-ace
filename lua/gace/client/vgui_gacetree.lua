local function TreeCompSorter(a, b)
    if a.name == b.name then -- why does this happen
        return false
    end

    local a_comps = a.name:Split("/")
    local b_comps = b.name:Split("/")

    -- We get the deepest common component
    for i=1, math.max(#a_comps, #b_comps) do
        local a_comp = a_comps[i]
        local b_comp = b_comps[i]

        if a_comp ~= b_comp then
            if b_comp and not a_comp then
                return true
            end
            if a_comp and not b_comp then
                return false
            end

            local last_acomp = i == #a_comps
            local last_bcomp = i == #b_comps

            local acomp_type = last_acomp and a.item.type or "folder"
            local bcomp_type = last_bcomp and b.item.type or "folder"

            if acomp_type ~= bcomp_type then
                if acomp_type == "folder" then
                    return true
                end
                if bcomp_type == "folder" then
                    return false
                end
            end
            --print(a.name, " v ", b.name, " (", a_comp < b_comp, ")")

            return a_comp < b_comp
        end
    end

    error("We got outside for loop in GAce Tree sort. '" .. a.name .. "' vs '" .. b.name .. "'")
end
gace.GAceTreeSorter = TreeCompSorter

local function last_comp(str)
    return str:match("/?([^/]*)$")
end
local function par_comp(str)
    return str:match("(.*)/[^/]*$")
end

local VGUI_GACETREE = {
	QueryColor = function(self, clrid)
		local colors = self.Colors
		local clr = colors and colors[clrid]
		return clr or gace.UIColors[clrid]
	end,
	SetColorOverride = function(self, clrid, clr)
		self.Colors = self.Colors or {}
		self.Colors[clrid] = clr
	end,

    Init = function(self)
        self.ExpandedItems = {}

        self.Items = {}
        self.ItemComponents = {}

        self.IsDirty = true
    end,

    VerifyHasParent = function(self, id)
        local parid = id:match("(.*)/[^/]*$")
        if parid and not self.Items[parid] then
            self:VerifyHasParent(parid)

            print(id, " is missing parent. Adding ", parid)
            self.Items[parid] = {}
        end
    end,

    AddItem = function(self, id, type, userobj)
        self:VerifyHasParent(id)

        self.Items[id] = {type = type or "file", userobj = userobj}
        self:RelayoutItems()
        self.IsDirty = true
    end,

    RemoveItem = function(self, id)
        if self.Items[id] then
            self.Items[id] = nil
        end

        self:RelayoutItems()
        self.IsDirty = true
    end,

    QueryItemChildren = function(self, id)
        local id_pattern = id .. "/[^/]*$"
        local ret = {}
        for nm,_ in pairs(self.Items) do
            if nm:match(id_pattern) then
                ret[#ret+1] = nm
            end
        end
        return ret
    end,

    QueryItemComponent = function(self, id)
        return self.ItemComponents[id]
    end,

    RelayoutItems = function(self)
        -- Figure out what items were removed and remove their components
        for nm,comp in pairs(self.ItemComponents) do
            if IsValid(comp) and not self.Items[nm] then
                comp:Remove()
            end
        end

        -- Add items to numerically indexed list
        local items = {}
        for nm,item in pairs(self.Items) do
            table.insert(items, {name = nm, item = item})
        end

        -- Sort items in order we want them to be in the treeview
        table.sort(items, TreeCompSorter)

        local ordered_children = {}

        -- Verify each item has a component
        for idx,item in pairs(items) do
            local itemname = item.name
            local comp = self.ItemComponents[itemname]

            if not IsValid(comp) then
                local node = vgui.Create("GAceTreeNode")
                self.ItemComponents[item.name] = node
                comp = node
                node:SetupNode(self, item.name)
                node.TableConfig = {FillX = true}
                node.Item = item.item
                node.UserObject = item.item.userobj

                self:Add(node)
            end

            comp.Order = idx
            table.insert(ordered_children, comp)
        end

        self.OrderedChildren = ordered_children
    end,

    Think = function(self)
        if self.IsDirty then
            self:PerformLayout()
        end
    end,

    PerformLayout = function(self)
        local y = 0
        for _,c in pairs(self.OrderedChildren or {}) do
            if not c:ShouldBeVisible() then
                c:SetPos(0, -100)
            else
                c:SetPos(0, y)
                c:SetSize(self:GetWide(), 22)

                y = y + 22
            end
        end

        self:SetTall(y)
    end,

    CheckRecursiveVisibility = function(self, id)
        local parid = par_comp(id)
        if parid and not self:CheckRecursiveVisibility(parid) then return false end

        if self.ExpandedItems[id] == nil then return true end

        return self:IsExpanded(id)
    end,

    IsIdVisible = function(self, id)
        local parid = par_comp(id)
        if not parid then return true end
        return self:CheckRecursiveVisibility(parid)
    end,

    IsExpanded = function(self, id)
        return self.ExpandedItems[id] == true
    end,

    SetExpanded = function(self, id, b)
        self.ExpandedItems[id] = b
    end
}

derma.DefineControl( "GAceTree", "File/Item tree for G-Ace", VGUI_GACETREE, "DPanel" )

local mat_folder = Material("icon16/folder.png")
local mat_file = Material("icon16/page.png")

local mat_arrow = Material("icon16/bullet_go.png")

local VGUI_GACETREENODE = {
    Init = function(self)
        self:SetText("")
    end,

    DoClick = function(self)
        self.Tree:SetExpanded(self.NodeId, not self.Tree:IsExpanded(self.NodeId))

        self.Tree.IsDirty = true

        if self.OnClick then self:OnClick() end
    end,

    DoRightClick = function(self)
        if self.OnRightClick then self:OnRightClick() end
    end,

    Paint = function(self, w, h)
        local vars = {
            bg_hover = gace.UIColors.tab_bg_hover,
            bg = gace.UIColors.tab_bg,

            fg = gace.UIColors.tab_fg,

            mat_arrow = mat_arrow,
            mat_folder = mat_folder,
            mat_file = mat_file
        }

        gace.CallHook("FileTreeFileNodePrePaint", self, vars)

		if self.Hovered then
			surface.SetDrawColor(vars.bg_hover)
		else
			surface.SetDrawColor(vars.bg)
		end
        surface.DrawRect(0, 0, w, h)

        local x = 5 + ((self.Depth or 0) * 15)

        draw.SimpleText(last_comp(self.NodeId or ""), "DermaDefaultBold", x+45, h/2, vars.fg, nil, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(255, 255, 255)

        if self.Item.type == "folder" then
            local is_expanded = self.Tree:IsExpanded(self.NodeId)

            surface.SetMaterial(vars.mat_arrow)
            surface.DrawTexturedRectRotated(x+8, h/2, 16, 16, is_expanded and 270 or 0)

            surface.SetMaterial(vars.mat_folder)
        else
            surface.SetMaterial(vars.mat_file)
        end
        surface.DrawTexturedRect(x + 20, h/2 - 8, 16, 16)
    end,

    Think = function(self)
        gace.CallHook("FileTreeFileNodeThink", self)
    end,

    SetupNode = function(self, tree, id)
        self.Tree = tree
        self.NodeId = id

        self.Depth = #id:Split("/") - 1
    end,

    ShouldBeVisible = function(self)
        return self.Tree:IsIdVisible(self.NodeId)
    end
}
derma.DefineControl( "GAceTreeNode", "Tree item for GAceTree", VGUI_GACETREENODE, "DButton" )

concommand.Add("gace_testtree", function()
    local frame = vgui.Create("DFrame")
    frame:SetSize(800, 600)
    frame:SetPos(0, 0)

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)

    local tree = vgui.Create("GAceTree")
    tree:Dock(TOP)
    scroll:AddItem(tree)

    GACETREE = tree

    tree:AddItem("root", "")
    tree:AddItem("root/kappa", "")
    tree:AddItem("root/kappa/potatis", "")
    tree:AddItem("root/kappa/abc", "")
    for i=1,100 do
        tree:AddItem("root/aay/" .. i, "")
    end

    frame:MakePopup()
end)
