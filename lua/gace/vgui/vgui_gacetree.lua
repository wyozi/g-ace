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

local last_comp, par_comp = gace.path.last, gace.path.parent

local VGUI_GACETREE = {
    GetParentComponent = function(_, path) return par_comp(path) end,

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

        self.VisFilteredItems = {}

        self.IsDirty = true
    end,

    HasItem = function(self, id)
        return self.Items[id] ~= nil
    end,

    VerifyHasParent = function(self, id)
        local parid = id:match("(.*)/[^/]*$")
        if parid and not self:HasItem(parid) then
            self:VerifyHasParent(parid)

            print(id, " is missing parent. Adding ", parid)
            self:AddItem(parid, "folder")
            return false
        end
        return true
    end,

    AddItem = function(self, id, type, userobj)
        self:VerifyHasParent(id)

        self.Items[id] = {type = type or "file", userobj = userobj}

        -- Unexpand newly added item
        self:SetExpanded(id, false)
        -- But expand all the parents..
        local s = par_comp(id)
        while s do
            self:SetExpanded(s, true)
            s = par_comp(s)
        end

        self:RelayoutItems()

        return self:QueryItemComponent(id)
    end,

    RemoveItem = function(self, id, noRelayout)
        local children = self:QueryItemChildren(id, true)
        for _,c in pairs(children) do
            self:RemoveItem(c, true)
        end

        if self.Items[id] then
            self.Items[id] = nil
        end

        if not noRelayout then
            self:RelayoutItems()
        end
    end,

    QueryItemChildren = function(self, id, includeGrandChildren)
        local id_pattern = "^"

        -- If not querying root we need to add some stuff
        if id ~= "" then
            id_pattern = id_pattern .. id .. "/"
        end

        if includeGrandChildren then
            id_pattern = id_pattern .. "(.*)$"
        else
            id_pattern = id_pattern .. "([^/]*)$"
        end

        local ret = {}
        for nm,_ in pairs(self.Items) do
            if string.match(nm, id_pattern) then
                ret[#ret+1] = nm
            end
        end
        return ret
    end,

    QueryItem = function(self, path)
        return self.Items[path]
    end,
    QueryItemComponent = function(self, id)
        return self.ItemComponents[id]
    end,

    RelayoutItems = function(self)
        self.VisFilteredItems = {}

        -- Figure out what items were removed and remove their components
        for nm,comp in pairs(self.ItemComponents) do
            -- remove components that do not exist or are filtered out
            if IsValid(comp) and (not self.Items[nm] or not self:CheckPathFilterVisibility(nm)) then
                comp:Remove()
                self.ItemComponents[nm] = nil
            end
        end

        -- Add items to numerically indexed list
        local items = {}
        for nm,item in pairs(self.Items) do
            if self:CheckPathFilterVisibility(nm) then
                table.insert(items, {name = nm, item = item})
            else
                self.VisFilteredItems[nm] = true
            end
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

        -- Mark as dirty; need to hide/show on next Think
        self.IsDirty = true
    end,

    Think = function(self)
        if self.IsDirty then
            self:PerformLayout()

            self.IsDirty = false
        end
    end,

    PerformLayout = function(self)
        local y = 0
        for _,c in pairs(self.OrderedChildren or {}) do
            if not c:ShouldBeVisible() then
                c:SetPos(0, -100)
            else
                c:SetPos(0, y)
                c:SetSize(self:GetWide(), c:GetTall())

                y = y + c:GetTall()
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
    end,

    ExpandedItemDump = function(self, checkParentVisiblity)
        local dump = {}

        for id, _ in pairs(self.Items) do
            local vis = self:IsExpanded(id)

            -- If true, we need to check for visibility as well
            if checkParentVisiblity then 
                vis = vis and self:IsIdVisible(id)
            end

            if vis then
                table.insert(dump, id)
            end
        end

        return dump
    end,


    -- check if path should be visible according to node visibility filter
    CheckPathFilterVisibility = function(self, path)
        local filter = self._nodeVisFilter
        local b = not filter or filter(path, self)
        return b
    end,

    -- Whether given path is not visible due to path filter
    WasPathVisFiltered = function(self, path)
        return self.VisFilteredItems[path]
    end,

    -- Sets node visibility filter. Filter is called with (path, filetree) args
    SetNodeVisibilityFilter = function(self, filter)
        self._nodeVisFilter = filter
        self:RelayoutItems()
    end
}

derma.DefineControl( "GAceTree", "File/Item tree for G-Ace", VGUI_GACETREE, "DPanel" )

local mat_folder = Material("icon16/folder.png")
local mat_file = Material("icon16/page.png")

local mat_arrow = Material("icon16/bullet_go.png")

local VGUI_GACETREENODE = {
    Init = function(self)
        self:SetText("")
        self:SetTall(20)
    end,

    DoClick = function(self)
        if self.Item.type == "folder" then
            self.Tree:SetExpanded(self.NodeId, not self.Tree:IsExpanded(self.NodeId))
            self.Tree.IsDirty = true
        end

        if self.OnClick then self:OnClick() end
    end,

    DoRightClick = function(self)
        if self.OnRightClick then self:OnRightClick() end
    end,

    Paint = function(self, w, h)
        local x = 5 + ((self.Depth or 0) * 15)

        local vars = {
            bg_hover = gace.UIColors.treenode_bg_hover,
            bg = gace.UIColors.tab_bg,

            fg = gace.UIColors.tab_fg,

            mat_arrow = mat_arrow,
            mat_folder = mat_folder,
            mat_file = mat_file,

            draw_x = x
        }

        gace.CallHook("FileTreeFileNodePrePaint", self, vars)

		if self.Hovered then
			surface.SetDrawColor(vars.bg_hover)
		else
			surface.SetDrawColor(vars.bg)
		end
        surface.DrawRect(0, 0, w, h)

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

        gace.CallHook("FileTreeFileNodePostPaint", self, vars)
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
