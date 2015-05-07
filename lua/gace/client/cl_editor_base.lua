-- TODO all this cache stuff probably shouldnt be here
gace.ClientCache = gace.SimpleCache:new()

local filesync = gace.CacheSyncFS:new("gace-clientcache.txt")
filesync:updateCache(gace.ClientCache)
gace.ClientCache:addChangeListener(filesync)

local gace_editorurl = CreateConVar("gace_editorurl", "")

local function UpdateDefaultOpts()
	gace.Debug("Updating default editor opts")

	local editorurl = gace_editorurl:GetString():Trim()

	gace.DefaultEditorOptions = {
		editor_url = editorurl == "" and "http://wyozi.github.io/g-ace/editor_refactored.html" or editorurl,
		root_path = ""
	}
end

UpdateDefaultOpts()

cvars.AddChangeCallback("gace_editorurl", UpdateDefaultOpts)

function gace.GetOption(opt)
	if gace.EditorOptions and gace.EditorOptions[opt] then
		return gace.EditorOptions[opt]
	end
	return gace.DefaultEditorOptions[opt]
end

function gace.ShowEditor()
	if gace.Frame:IsVisible() then return end
	gace.Frame:Show()
end
function gace.HideEditor()
	if not gace.Frame:IsVisible() then return end
	gace.Frame:Hide()
end

function gace.AddBasePanels(frame)
	local basepnl = frame.BasePanel

	-- The actual editor
	do
		local editorpnl = basepnl:AddSubPanel("EditorPanel", FILL)
		local html = vgui.Create("DHTML")

		editorpnl:AddDocked("Editor", html, FILL)

		gace.CallHook("SetupHTMLPanel", html)

		local url = string.format("%s?refresh=%d", gace.GetOption("editor_url"), os.time())
		html:OpenURL(url)
	end

	-- Tabs
	do
		local tabs = gace.CreateTabPanel()
		basepnl:AddDocked("Tabs", tabs, TOP)
	end

end
function gace.CreateEditor()
	local frame = gace.CreateFrame()
	gace.Frame = frame

	frame.BasePanel = vgui.Create("DDynPanel", frame)
	frame.BasePanel.DynPanelId = "Base"
	frame.BasePanel:Dock(FILL)

	gace.AddBasePanels(frame)

	gace.CallHook("AddPanels", frame, frame.BasePanel)
	gace.CallHook("PostEditorCreated")
end
function gace.OpenEditor(opts)
	gace.EditorOptions = opts

	-- If instance of Frame exists, just show it
	if IsValid(gace.Frame) and not gace.GetOption("force_recreate") then
		gace.ShowEditor()
	else
		if IsValid(gace.Frame) then
			gace.Frame:Remove()
			gace.CallHook("ClearGAceVariables")
		end

		gace.CreateEditor()
		gace.Frame:MakePopup()
	end
end

concommand.Add("gace-open", function() gace.OpenEditor() end)
concommand.Add("gace-reopen", function()
	gace.OpenEditor({
		force_recreate = true
	})
end)
