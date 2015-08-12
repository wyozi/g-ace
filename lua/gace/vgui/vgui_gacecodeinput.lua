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
	str_literal = Color(108, 122, 137),
	num_literal = Color(38, 166, 91),
	keyword = Color(248, 148, 6),
	operator = Color(68,108,179),
	lib_func = Color(154, 18, 179)
}

function PANEL:DrawText(textcolor)
	surface.SetFont("DermaDefault")

	local caretPos = self:GetCaretPos()
	local drawCaret = self:HasFocus() --math.floor(CurTime() * 2) % 2 == 0

	local char = 0
	local x = 3
	local y = 4
	local tokenized = self:TokenizeLine(self:GetText())
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
		end
		char = nchar

		local tw = surface.GetTextSize(token.text)
		x = x+tw
	end

	local invis = Color(0, 0, 0, 0)
	self:DrawTextEntryText(invis, self.m_colHighlight, invis)
end

function PANEL:GetAutoComplete(text)
	local btext = text:sub(1, self:GetCaretPos())
	local cursorIdentifier = btext:match("[%w%.]+$") or ""

	local completions = gace.autocompletion.Complete(cursorIdentifier)
	if #completions > 25 then return end -- TOO MANY

	return _u.map(completions, function(x)
		local c = btext
		c = string.gsub(c, "%w+$", x.value)
		return c
	end)
end

--[[
function PANEL:OnKeyCode(keycode)
	if keycode == KEY_SPACE and input.IsControlDown() then
		local cursorIdentifier = self:GetText():sub(1, self:GetCaretPos()):match("[%w%.]+$") or ""

		PrintTable(gace.autocompletion.Complete(cursorIdentifier))
	end
end]]

derma.DefineControl("GAceCodeInput", "Code input for GAce", PANEL, "GAceInput")
