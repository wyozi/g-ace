function gace.RunJavascript(js)
	local html = gace.GetPanel("Editor")
	html:RunJavascript(js)
end

function gace.SetHTMLSession(id, content, requestDataIfNotCached)
	local js_data = {}

	if requestDataIfNotCached then
		js_data.requestDataIfNotCached = true
	end
	if content then
		content = (util.Base64Encode(content) or ""):Replace("\n", "")
		js_data.contentb = content
	end

	local js_table = {}
	for k,v in pairs(js_data) do
		table.insert(js_table, k .. ": \"" .. tostring(v) .. "\"")
	end

	gace.RunJavascript([[
		gaceSessions.setSession(
			"]] .. id ..[[",
			{]] .. table.concat(js_table, ", ") .. [[}
		);]])
	
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
		sess.Content = content

		gace.CallHook("OnSessionContentUpdated", gace.GetSessionId(), content)
	end)
	html:AddFunction("gace", "SaveSession", function()
		gace.Log("Saving session")

		local sess = gace.GetOpenSession()
		local content = sess.Content

		local initial_osi = gace.GetSessionId()

		local function SaveTo(path)
			sess.SavedContent = content
			gace.Save(path, content, function(_, _, pl)
				if pl.err then
					local better_err = pl.err
					if better_err == "Inexistent virtual folder" then
						better_err = "Trying to save to root. Try to save inside a folder instead."
					end
					return gace.Log(gace.LOG_ERROR, "Unable to save: ", better_err)
				end

				if path ~= initial_osi then
					gace.CloseSession(initial_osi)
					gace.OpenSession(path, {content=content})
				end

				gace.filetree.RefreshPath(filetree, gace.Path(path):WithoutFile():ToString())
			end)
		end

		if gace.Path(initial_osi):WithoutVFolder():IsRoot() then
			gace.AskForInput("Where to save? Must be absolute path (e.g. EpicJB/folder/file.txt) and must end in .txt", function(txt)
				SaveTo(txt)
			end)
			return
		end
		SaveTo(initial_osi)
	end)
	html:AddFunction("gace", "NewSession", function(id, line, column)
		gace.OpenSession("newfile" .. os.time() .. ".txt")
	end)
	html:AddFunction("gace", "OpenSession", function(id, line, column)
		gace.Log("Opening session '", id, "' at line ", line, " column ", column)
		gace.OpenSession(id, {callback = function()
			if not line and not column then return end

			gace.RunJavascript("editor.moveCursorTo(" .. line .. ", " .. (column or 0) .. ");")
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

	-- General editor related functions (such as updating theme)
	html:AddFunction("gace", "EditorReady", function()
		local c_theme = cookie.GetString("gace-theme", "ace/theme/tomorrow_night") or "ace/theme/tomorrow_night"
		local the_theme = "ace/theme/tomorrow_night"
		if table.HasValue(gace.AvailableThemes, c_theme:Split("/")[3]) then
			the_theme = c_theme
		end
		gace.RunJavascript("editor.setTheme('" .. the_theme .. "')")
	end)

	local function RGBStringToColor(str)
		local r, g, b = string.match(str, "(%d+):(%d+):(%d+)")
		return Color(tonumber(r), tonumber(g), tonumber(b))
	end
	html:AddFunction("gace", "ThemeChanged", function(theme, bgColor, fgColor, gutterBgColor)
		gace.UIColors.frame_bg = RGBStringToColor(bgColor)
		gace.UIColors.frame_fg = RGBStringToColor(fgColor)

		gace.UIColors.tab_bg = RGBStringToColor(gutterBgColor)
		gace.UIColors.tab_fg = RGBStringToColor(fgColor)

		cookie.Set("gace-theme", theme)
	end)

	html:AddFunction("gace", "ModeChanged", function(mode)
		local sess = gace.GetOpenSession()
		if sess then sess.mode = mode end
	end)
end)