
local VGUI_GACETREE = {
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

    AddItem = function(self, id, item)
        self:VerifyHasParent(id)

        self.Items[id] = {item = item}
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
            table.insert(items, {name = nm, val = item})
        end

        -- Sort items in order we want them to be in the treeview
        table.sort(items, function(a, b)
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
                    --print(a.name, " v ", b.name, " (", a_comp < b_comp, ")")

                    return a_comp < b_comp
                end
            end

            error("We got outside for loop in GAce Tree sort. '" .. a.name .. "' vs '" .. b.name .. "'")
        end)

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

                node.DoClick = function()
                    if table.HasValue(self.ExpandedItems, item.name) then
                        table.RemoveByValue(self.ExpandedItems, item.name)
                    else
                        table.insert(self.ExpandedItems, item.name)
                    end

                    self.IsDirty = true
                end

                self:Add(node)
            end

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
                c:SetSize(self:GetWide(), 25)

                y = y + 25
            end
        end

        self:SetTall(y)
    end,

    ShouldIdBeVisible = function(self, id)
        if not id then return true end -- root?

        local parid = id:match("(.*)/[^/]*$")
        if not parid then return true end -- on root level
        if not self:ShouldIdBeVisible(parid) then return false end

        for _,ei in pairs(self.ExpandedItems) do
            if id:match(ei .. "/[^/]*$") then
                return true
            end
        end

        return false
    end
}

derma.DefineControl( "GAceTree", "File/Item tree for G-Ace", VGUI_GACETREE, "DPanel" )

local VGUI_GACETREENODE = {
    Init = function(self)
        self:SetText("")
    end,

    Paint = function(self, w, h)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(0, 0, 0)
        surface.DrawOutlinedRect(0, 0, w, h)

        local x = 5 + ((self.Depth or 0) * 15)

        draw.SimpleText(self.NodeId or "", "DermaDefaultBold", x+20, h/2, Color(0, 0, 0), nil, TEXT_ALIGN_CENTER)

        surface.SetMaterial(Material(table.HasValue(self.Tree.ExpandedItems, self.NodeId) and "icon16/tick.png" or "icon16/cross.png"))
        surface.SetDrawColor(255, 255, 255)
        surface.DrawTexturedRect(x, h/2 - 8, 16, 16)
    end,

    SetupNode = function(self, tree, id)
        self.Tree = tree
        self.NodeId = id

        self.Depth = #id:Split("/") - 1
    end,

    ShouldBeVisible = function(self)
        return self.Tree:ShouldIdBeVisible(self.NodeId)
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

--[[
local t = "root"
local m = "(.*)/[^/]*$"
print(t:match(m))
]]
