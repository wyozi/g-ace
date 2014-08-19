
gace.AddHook("AddPanels", "Editor_AddConsole", function(frame, basepnl)
	local sb = basepnl:GetById("SideBar")

	local console = vgui.Create("RichText")
	console:SetTall(150)
	sb:AddDocked("Console", console, BOTTOM)
end)

-- TODO make these smoother/lighter
gace.LOG_ERROR = Color(255, 0, 0)
gace.LOG_WARN = Color(255, 127, 0)
gace.LOG_SUCCESS = Color(0, 255, 0)

gace.AddHook("LogMessage", "Console_OverrideOldLogSystem", function(...)

	local console = gace.GetPanel("Console")

	local function setclr(r, g, b)
		console:InsertColorChange(r,g,b,255)
	end
	local function append(txt)
		console:AppendText(txt)
	end
	setclr(100,100,100)	append(			"[")
	setclr(255,255,255)	append(os.date(	"%H"))
	setclr(255,255,255)	append(			":")
	setclr(255,255,255)	append(os.date(	"%M"))
	setclr(100,100,100)	append(			"] ")
	
	setclr(255, 255, 255)
	for _,v in pairs({...}) do
		if type(v) == "table" then
			setclr(v.r, v.g, v.b)
		else
			append(tostring(v))
		end
	end
	append("\n")

	console:GotoTextEnd()

end)
