
-- TODO make these smoother/lighter
gace.LOG_ERROR = Color(255, 0, 0)
gace.LOG_WARN = Color(255, 127, 0)
gace.LOG_SUCCESS = Color(0, 255, 0)

function gace.AppendToConsole(...)
	local function setclr(r, g, b)
		gace.Frame.Console:InsertColorChange(r,g,b,255)
	end
	local function append(txt)
		gace.Frame.Console:AppendText(txt)
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

	gace.Frame.Console:GotoTextEnd()
end