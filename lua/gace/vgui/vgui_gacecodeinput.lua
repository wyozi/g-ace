local PANEL = {}

PANEL.Keywords = {"local"}
PANEL.LibFunctions = {}

-- globals
for _,fn in pairs{"print", "MsgN"} do
	table.insert(PANEL.LibFunctions, fn)
end
-- libs
for _,libnm in pairs{"math", "net", "string"} do
	local lib = _G[libnm]
	for fn,_ in pairs(lib) do
		table.insert(PANEL.LibFunctions, libnm .. "." .. fn)
	end
end

function PANEL:TokenizeLine(str)
	local tokens = {}

	local t = 1
	local function parse()
		local ws = str:match("^%s+", t)
		if ws then return { start = t, type = "whitespace", text = ws } end

		local str_lit = str:match("^%b\"\"", t)
		if str_lit then return { start = t, type = "str_literal", text = str_lit, value = str_lit:sub(2, -2) } end

		local hex_lit = str:match("^0x[ABCDEFabcdef0123456789]+", t)
		if hex_lit then return { start = t, type = "num_literal", text = hex_lit, value = tonumber(hex_lit:sub(3), 16) } end

		local num_lit = str:match("^[%d%.]", t)
		if num_lit then return { start = t, type = "num_literal", text = num_lit, value = tonumber(num_lit) } end

		local name = str:match("^[%w%.]+", t)
		if name then
			local _type = "name"
			if table.HasValue(self.Keywords, name) then _type = "keyword"
			elseif table.HasValue(self.LibFunctions, name) then _type = "lib_func" end
			return { start = t, type = _type, text = name }
		end

		local symbol = str:match("^[%=%(%)%[%]%.:,]", t)
		if symbol then return { start = t, type = "symbol", text = symbol } end

		local operator = str:match("^[%*%+%-]", t)
		if operator then return { start = t, type = "operator", text = operator } end

		local misc = str:match(".*", t)
		return { start = t, type = "unknown", text = misc }
	end

	repeat
		local token = parse()
		if not token then break end

		table.insert(tokens, token)
		t = t + #token.text
	until t > #str

	return tokens
end

PANEL.TokenColors = {
	str_literal = Color(230, 219, 116),
	num_literal = Color(174, 129, 255),
	keyword = Color(249, 38, 114),
	operator = Color(249, 38, 114),
	lib_func = Color(102, 217, 239)
}

surface.CreateFont("GAce_CodeFont", {
	font = "Courier New",
	size = 15
})

function PANEL:DrawHighlightedText(text, x, y, textcolor, drawCaret)
	local caretPos = self:GetCaretPos()

	local char = 0
	local tokenized = self:TokenizeLine(text)
	for _,token in pairs(tokenized) do
		surface.SetTextPos(x, y)
		surface.SetTextColor(token.color or self.TokenColors[token.type] or textcolor)
		surface.DrawText(token.text)

		local nchar = char + string.len(token.text)
		if drawCaret and caretPos <= nchar then
			local carettokenx = surface.GetTextSize(string.sub(token.text, 1, caretPos-char))
			local caretx = x + carettokenx - 1
			surface.SetDrawColor(255, 127, 0)
			surface.DrawLine(caretx, 4, caretx, self:GetTall()-4)

			drawCaret = false
		end
		char = nchar

		local tw = surface.GetTextSize(token.text)
		x = x+tw
	end
end

function PANEL:DrawText(textcolor)
	surface.SetFont("GAce_CodeFont")
	self:SetFontInternal("GAce_CodeFont")

	local drawCaret = self:HasFocus() --math.floor(CurTime() * 2) % 2 == 0

	self:DrawHighlightedText(self:GetText(), 3, 3, textcolor, drawCaret)

	local invis = Color(0, 0, 0, 0)
	self:DrawTextEntryText(invis, self.m_colHighlight, invis)
end

function PANEL:GetTextSize()
	surface.SetFont("GAce_CodeFont")
	self:SetFontInternal("GAce_CodeFont")
	local x = 3
	local y = 3
	local w, h = surface.GetTextSize(self:GetText())
	return x + w, y + h
end

function PANEL:GetAutoComplete(text)
	local btext = text:sub(1, self:GetCaretPos())
	local cursorIdentifier = btext:match("[%w%.]+$") or ""

	local completions = gace.autocompletion.Complete(cursorIdentifier)
	if #completions > 20 then
		local _comp = {}
		for i=1, 20 do
			_comp[i] = completions[i]
		end
		completions = _comp
	end

	return _u.map(completions, function(x)
		local c = btext
		if cursorIdentifier == "" or c:sub(-1) == "." then
			c = c .. x.value
		else
			c = string.gsub(c, "%w+$", x.value)
		end

		return c
	end)
end

function PANEL:OpenAutoComplete(tab, openIfClosed)
	if not tab then return end
	if #tab == 0 then return end

	if not IsValid(self.AC) then
		self.AC = vgui.Create("GAceCodeInput_AutoComplete")
		self.AC.CodeInput = self
	end

	self.AC.Values = tab
end

function PANEL:Think()
	if IsValid(self.AC) then
		local tw = self:GetTextSize()
		self.AC:SetWide(tw + 200)
		self.AC:SetPos(self:LocalToScreen(tw, self:GetTall() - 2))
	end
end

function PANEL:OnKeyCode(keycode)
	if IsValid(self.AC) and self.AC:CheckKeycode(keycode) then return true end
end

derma.DefineControl("GAceCodeInput", "Code input for GAce", PANEL, "GAceInput")

local PANEL_AC = {}
function PANEL_AC:Init()
	self:SetDrawOnTop(true)
	self.Values = {}
end
function PANEL_AC:Paint(w, h)
	surface.SetDrawColor(34, 36, 37)
	surface.DrawRect(0, 0, w, h)

	for k,v in pairs(self.Values) do
		if self.Choice == k then
			surface.SetDrawColor(255, 255, 255, 50)
			surface.DrawRect(0, (k-1) * 20, w, 20)
		end
		surface.SetDrawColor(255, 255, 255)
		surface.DrawOutlinedRect(0, (k-1) * 20, w, 20)

		surface.SetFont("GAce_CodeFont")
		self.CodeInput:DrawHighlightedText(v, 5, (k-1) * 20 + 2, Color(255, 255, 255), false)
	end
end
function PANEL_AC:CheckKeycode(keycode)
	if keycode == KEY_DOWN then
		self.Choice = ((self.Choice or 0) + 1) % (#self.Values + 1)
		return true
	end
	if keycode == KEY_UP and self.Choice and self.Choice > 0 then
		self.Choice = math.max((self.Choice or 0) - 1, 0)
		return true
	end
	if keycode == KEY_ENTER then
		local choice = self.Values[self.Choice or 0]
		if choice then
			self.CodeInput:SetText(choice)
			self.CodeInput:SetCaretPos(choice:len())
			self.CodeInput:RequestFocus()
			self:Remove()

			return true
		end
	end
end
function PANEL_AC:Think()
	if not IsValid(self.CodeInput) or not self.CodeInput:IsVisible() or not self.CodeInput:IsEditing() then
		self:Remove()
	end
	self:SetTall(#self.Values * 20)
end
derma.DefineControl("GAceCodeInput_AutoComplete", "Code autocompleter popup for GAce", PANEL_AC, "Panel")
