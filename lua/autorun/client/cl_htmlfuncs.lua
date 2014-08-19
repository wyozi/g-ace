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

gace.AddHook("SetupHTMLPanel", "Editor_SetupHTMLFunctions", function(html)
	-- Session related functions
	html:AddFunction("gace", "UpdateSessionContent", function(content)
		local sess = gace.GetOpenSession()
		sess.Content = content

		-- TODO check if we need to add marker for "file contains unsaved changes"
	end)
	html:AddFunction("gace", "SaveSession", function()
		gace.Log("Saving session")
	end)
	html:AddFunction("gace", "NewSession", function(id, line, column)
		gace.OpenSession("newfile" .. os.time() .. ".txt")
	end)
	html:AddFunction("gace", "OpenSession", function(id, line, column)
		gace.Log("Opening session '", id, "' at line ", line, " column ", column)
		gace.OpenSession(id, function()
			if not line and not column then return end

			gace.RunJavascript("editor.moveCursorTo(" .. line .. ", " .. (column or 0) .. ");")
		end)
	end)
	html:AddFunction("gace", "CloseSession", function(force)
		gace.Log("Closing session (force=", force, ")")
	end)


	html:AddFunction("gace", "RequestSessionContent", function()
		local sess, id = gace.GetOpenSession()
		gace.SetHTMLSession(id, sess.Content)
	end)

	-- General editor related functions (such as updating theme)
end)