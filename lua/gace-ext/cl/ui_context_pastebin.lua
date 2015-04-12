local function SendToPaste(code)
	http.Post("http://paste.ee/api", {
		key = "public",
		description = "G-Ace paste",
		paste = code,
		language = "lua",
		format = "json"
	}, function(body)
		local json = util.JSONToTable(body)
		if json.status == "success" then
			local link = json.paste.link
			SetClipboardText(link)
			gace.Log("Succesfully uploaded. Link: " .. link .. " (already copied to your clipboard)")
		else
			gace.Log(gace.LOG_ERROR, "Upload failed: " .. json.status)
		end
	end)
end

gace.AddHook("EditorContextMenu", "Pastebin", function(menu, data)
    menu:AddOption("Send to pastebin", function()
		local code = data.selection_text
		if not code or code == "" then
			code = gace.GetOpenSession().Content
		end

		if not code or code == "" then
			gace.Log(gace.LOG_WARN, "There's nothing to upload!")
			return
		end
		SendToPaste(code)
	end):SetIcon("icon16/script.png")
end)
