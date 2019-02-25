function gace.RunJavascript(js)
	local html = gace.GetPanel("Editor")
	html:QueueJavascript(js)
end
function gace.JSBridge()
	return gace.GetPanel("Editor").Bridge
end

function gace.SetHTMLSession(id, content, requestDataIfNotCached, mode)
	local js_data = {}

	if requestDataIfNotCached then
		js_data.requestDataIfNotCached = true
	end
	if mode then
		js_data.mode = mode
	end

	if content then
		js_data.content = content
	end

	local js_table = {}
	for k,v in pairs(js_data) do
		table.insert(js_table, k .. ": \"" .. tostring(v) .. "\"")
	end

	gace.JSBridge().gaceSessions.setSession(id, js_data)
end

gace.AvailableThemes = {
	"ambiance", "chaos", "chrome", "clouds", "clouds_midnight", "cobalt",
	"crimson_editor", "dawn", "dreamweaver", "eclipse", "github", "idle_fingers",
	"katzenmilch", "kr", "kuroir", "merbivore", "merbivore_soft", "mono_industrial",
	"monokai", "pastel_on_dark", "solarized_dark", "solarized_light", "terminal",
	"textmate", "tomorrow", "tomorrow_night", "tomorrow_night_blue",
	"tomorrow_night_bright", "tomorrow_night_eighties", "twilight",
	"vibrant_ink", "xcode",
}

gace.AddHook("SetupHTMLPanel", "Editor_SetupHTMLFunctions", function(html)
	-- Session related functions
	html:AddFunction("gace", "UpdateSessionContent", function(content)
		local sess = gace.GetOpenSession()
		if not sess then return end

		sess.Content = content

		gace.CallHook("OnSessionContentUpdated", gace.GetSessionId(), content)
	end)
	html:AddFunction("gace", "SaveSession", function()
		gace.Log("Saving session")

		local sess = gace.GetOpenSession()
		local content = sess.Content

		local initial_osi = gace.GetSessionId()

		local function SaveTo(path)
			gace.cmd.write(LocalPlayer(), path, content):then_(function()
				sess.SavedContent = content
				gace.CallHook("OnRemoteSessionSaved", path)

				if path ~= initial_osi then
					gace.CloseSession(initial_osi)
					gace.OpenSession(path, {content=content})
				end

				gace.filetree.RefreshPath(gace.Path(path):WithoutFile():ToString())
			end):catch(function(e)
				gace.Log(gace.LOG_ERROR, "File save failed: ", e)
			end)

			gace.CallHook("OnLocalSessionSaved", path)
		end

		if gace.Path(initial_osi):WithoutVFolder():IsRoot() then
			gace.ext.ShowTextInputPrompt("Where to save?", function(txt)
				SaveTo(txt)
			end)
			return
		end
		SaveTo(initial_osi)
	end)
	html:AddFunction("gace", "NewSession", function(id, line, column)
		local freeIndex
		for i=1,999 do
			local filename = string.format("scratch %d", i)
			if not gace.Sessions[filename] then
				freeIndex = i
				break
			end
		end
		gace.OpenSession(string.format("scratch %d", freeIndex), {content="", mark_unsaved = true})
	end)
	html:AddFunction("gace", "OpenSession", function(id, line, column)
		gace.Log("Opening session '", id, "' at line ", line, " column ", column)
		gace.OpenSession(id, {callback = function()
			if not line and not column then return end

			gace.JSBridge().editor.moveCursorTo(line, column or 0)
		end})
	end)
	html:AddFunction("gace", "CloseSession", function(force)
		gace.Log("Closing session (force=", force, ")")

		if force then
			gace.CloseSession(gace.GetSessionId())
		else
			local tab = gace.GetTabFor(gace.GetSessionId() or "")
			if tab then tab:CloseTab() end
		end
	end)

	html:AddFunction("gace", "RequestSessionContent", function()
		local sess, id = gace.GetOpenSession()
		gace.SetHTMLSession(id, sess.Content)
	end)


	-- General editor related functions

	html:AddFunction("gace", "ContextMenu", function(str)
		local tbl = util.JSONToTable(str)

		local menu = DermaMenu()
		gace.CallHook("EditorContextMenu", menu, tbl)
		menu:Open()
	end)

	html:AddFunction("gace", "EditorReady", function()
		local c_theme = cookie.GetString("gace-theme", "ace/theme/tomorrow_night") or "ace/theme/tomorrow_night"
		local the_theme = "ace/theme/tomorrow_night"
		if table.HasValue(gace.AvailableThemes, c_theme:Split("/")[3]) then
			the_theme = c_theme
		end
		gace.JSBridge().editor.setTheme(the_theme)

		local c_font = cookie.GetString("gace-font", "")
		local c_fontSize = tonumber(cookie.GetString("gace-fontSize", "14"))

		gace.JSBridge().setCustomEditorFont(c_font)
		gace.JSBridge().setCustomEditorFontSize(c_fontSize)
	end)

	local function RGBStringToColor(str)
		local r, g, b = string.match(str, "(%d+):(%d+):(%d+)")
		return Color(tonumber(r), tonumber(g), tonumber(b))
	end
	html:AddFunction("gace", "ThemeChanged", function(theme, bgColor, fgColor, gutterBgColor)
		local oldTheme = cookie.GetString("gace-theme")
		gace.UIColors.frame_bg = RGBStringToColor(bgColor)
		gace.UIColors.frame_fg = RGBStringToColor(fgColor)

		gace.UIColors.tab_bg = RGBStringToColor(gutterBgColor)
		gace.UIColors.tab_fg = RGBStringToColor(fgColor)

		cookie.Set("gace-theme", theme)

		gace.CallHook("EditorThemeChanged", theme, oldTheme)
	end)

	html:AddFunction("gace", "ModeChanged", function(mode)
		local sess = gace.GetOpenSession()
		if sess then sess.mode = mode end
	end)
end)
