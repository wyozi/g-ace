local PANEL = {}

PANEL.Keywords = {
	"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat",
	"return", "then", "true", "until", "while"
}
PANEL.LibFunctions = {}

-- globals
PANEL.GlobalNames = {"print", "MsgN", "Vector", "Angle"}
for _,fn in pairs(PANEL.GlobalNames) do
	table.insert(PANEL.LibFunctions, fn)
end
-- libs
PANEL.LibNames = {"math", "net", "string", "table", "os", "sql", "vgui", "http", "input", "draw", "concommand", "hook", "ents"}
for _,libnm in pairs(PANEL.LibNames) do
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
	self:DrawTextEntryText(invis, Color(255, 127, 0), invis)
end

function PANEL:GetTextSize(beforeCaret)
	surface.SetFont("GAce_CodeFont")
	self:SetFontInternal("GAce_CodeFont")
	local x = 3
	local y = 3
	local t = self:GetText()
	if beforeCaret then t = string.sub(t, 1, self:GetCaretPos()) end
	local w, h = surface.GetTextSize(t)
	return x + w, y + h
end

local function MathEval(str)
	local ops = {
		["^"] = {
			prec = 15,
			assoc = "right",
			func = function(x, y) return math.pow(x, y) end
		},

		["*"] = {
			prec = 10,
			assoc = "left",
			func = function(x, y) return x*y end
		},
		["/"] = {
			prec = 10,
			assoc = "left",
			func = function(x, y) return x/y end
		},
		["+"] = {
			prec = 5,
			assoc = "left",
			func = function(x, y) return x+y end
		},
		["-"] = {
			prec = 5,
			assoc = "left",
			func = function(x, y) return x-y end
		},
	}
	local opPattern = "%" .. table.concat(table.GetKeys(ops), "%")
	local funcs = {
		["sin"] = { func = math.sin, paramCount = 1 },
		["cos"] = { func = math.cos, paramCount = 1 },
		["tan"] = { func = math.tan, paramCount = 1 },

		["rad"] = { func = math.rad, paramCount = 1 },
		["deg"] = { func = math.deg, paramCount = 1 },

		["mod"] = { func = function(x, y) return x%y end, paramCount = 2 },
	}

	local function push(t, x) table.insert(t, x) end
	local function pop(t) return table.remove(t, #t) end
	local function peek(t) return t[#t] end

	local i = 1
	local function maketoken(type, text)
		i = i + #text
		return {type=type, text=text}
	end
	local function readtoken()
		local ws = str:match("^%s+", i)
		if ws then return maketoken("whitespace", ws) end

		local num_lit = str:match("^[%d%.]+", i)
		if num_lit then return maketoken("number", num_lit) end

		local op = str:match("^[" .. opPattern .. "]", i)
		if op then return maketoken("operator", op) end

		local str_lit = str:match("^%w+", i)
		if str_lit then return maketoken("identifier", str_lit) end

		local symbol = str:match("^.", i)
		if symbol then return maketoken("symbol", symbol) end
	end

	local out_q = {}
	local op_stack = {}

	while true do
		local t = readtoken()
		if not t then break end

		if t.type == "number" then
			push(out_q, tonumber(t.text))
		elseif t.type == "operator" then
			local curop = ops[t.text]
			while #op_stack > 0 and ops[peek(op_stack)] and
				((curop.assoc == "left" and curop.prec <= ops[peek(op_stack)].prec) or
				 (curop.assoc == "right" and curop.prec < ops[peek(op_stack)].prec)) do

				push(out_q, pop(op_stack))
			end
			push(op_stack, t.text)
		elseif t.type == "identifier" and funcs[t.text] then
			push(op_stack, t.text)
		elseif t.type == "symbol" and t.text == "(" then
			push(op_stack, "(")
		elseif t.type == "symbol" and t.text == ")" then
			while peek(op_stack) ~= "(" do
				push(out_q, pop(op_stack))
			end
			pop(op_stack) -- pop left parenthesis
			if #op_stack > 0 and funcs[peek(op_stack)] then
				push(out_q, pop(op_stack))
			end
		elseif t.type == "symbol" and t.text == "," then
			-- skip
		elseif t.type ~= "whitespace" then
			error("invalid token: " .. table.ToString(t))
		end

		--print("Token " .. t.text .. "; out_q:" .. table.ToString(out_q) .. "; op_stack:" .. table.ToString(op_stack))
	end

	while #op_stack > 0 do
		push(out_q, pop(op_stack))
	end

	local eval_stack = {}
	for k,v in ipairs(out_q) do
		if type(v) == "number" then
			push(eval_stack, v)
		elseif ops[v] then
			local s2, s1 = pop(eval_stack), pop(eval_stack)
			push(eval_stack, ops[v].func(s1, s2))
		elseif funcs[v] then
			local x = {}
			for i=1,funcs[v].paramCount do x[i] = pop(eval_stack) end
			x = table.Reverse(x)
			push(eval_stack, funcs[v].func(unpack(x)))
		end
	end

	return pop(eval_stack)
end

function PANEL:GetAutoComplete(text)
	local btext = text:sub(1, self:GetCaretPos())
	if #btext == 0 then return {} end

	local completions = gace.autocompletion.Complete(btext, self.ACOptions)
	if #completions > 20 then
		local _comp = {}
		for i=1, 20 do
			_comp[i] = completions[i]
		end
		completions = _comp
	end

	return completions
end

function PANEL:OpenAutoComplete(tab, openIfClosed)
	if not tab then
		if IsValid(self.AC) then self.AC:Remove() end
		return
	end

	if not IsValid(self.AC) then
		self.AC = vgui.Create("GAceCodeInput_AutoComplete")
		self.AC.CodeInput = self
	end

	self.AC.Values = tab
end

function PANEL:Think()
	if IsValid(self.AC) then
		local tw = self:GetTextSize(true)
		self.AC:SetWide(400)
		self.AC:SetPos(self:LocalToScreen(tw, -self.AC:GetTall()))
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
	self.Choice = 1
end

function PANEL_AC:IsBrowsingHistory()
	-- Make sure we're not screwing up browsing history
	local ci = self.CodeInput
	if ci.HistoryPos and ci.History and ci.HistoryPos ~= 0 then
		return true
	end

	return false
end

surface.CreateFont("GAce_AC_TypeFont", {
	font = "Courier New",
	size = 16,
	weight = 1000
})
function PANEL_AC:Paint(w, h)
	if self:IsBrowsingHistory() then return end

	surface.SetDrawColor(34, 36, 37)
	surface.DrawRect(0, 0, w, h)

	local values = self.Values
	for i=#values, 1, -1 do
		-- i is the visual index while k is the table index
		local k = #values - i + 1
		local v = values[k]
		
		local y = (i - 1) * 20
		
		if self.Choice == k then
			surface.SetDrawColor(255, 255, 255, 50)
			surface.DrawRect(0, y, w, 20)
		end
		surface.SetDrawColor(255, 255, 255)
		surface.DrawOutlinedRect(0, y, w, 20)

		if v.type == "function" or v.type == "library" then
			surface.SetDrawColor(PANEL.TokenColors.lib_func)
			surface.DrawRect(3, y + 3, 14, 14)

			if v.type == "function" then
				draw.SimpleText("f", "GAce_AC_TypeFont", 10, y + 10, Color(210, 77, 87), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			else
				draw.SimpleText("L", "GAce_AC_TypeFont", 10, y + 10, Color(108, 122, 137), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end

		surface.SetFont("GAce_CodeFont")
		self.CodeInput:DrawHighlightedText(v.value, 20, y + 2, Color(255, 255, 255), false)
		
		local typeString = v.type
		if typeString == "function" and v.contextInfo and v.contextInfo.returnType then
			typeString = "function -> " .. v.contextInfo.returnType
		end
		
		
		if typeString then
			draw.SimpleText(typeString, "GAce_AC_TypeFont", w - 5, y + 10, Color(200, 200, 200, 127), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
	end
end

local function findMatchLength(preText, match)
	for n=#match,1,-1 do
		if string.lower(string.sub(preText, -n)) == string.lower(string.sub(match, 1, n)) then
			return n
		end
	end
	return 0
end
--[[assert(findMatchLength("ayy lm", "aoni") == 0)
assert(findMatchLength("ayy lma", "aoni") == 1)
assert(findMatchLength("ayy lmao", "aoni") == 2)
assert(findMatchLength("ayy lmaoni", "aoni") == 4)]]

function PANEL_AC:CheckKeycode(keycode)
	if #self.Values == 0 then return end
	
	if self:IsBrowsingHistory() then return end

	if keycode == KEY_DOWN then
		self.Choice = math.max((self.Choice or 0) - 1, 1)
		return true
	end
	if keycode == KEY_UP then
		self.Choice = math.min((self.Choice or 0) + 1, #self.Values)
		return true
	end
	if keycode == KEY_TAB then
		local choice = self.Values[self.Choice or 0]
		if choice then
			local choiceValue = choice.value
			
			local cursorDelta = 0
			
			if choice.type == "function" then
				local parenthesis = "()"
				
				if choice.obj then
					local dinfo = debug.getinfo(choice.obj, "u")
					local paramCount = dinfo.nparams
					
					local paramNames = {}
					for i=1,paramCount do
						paramNames[i] = debug.getlocal(choice.obj, i)
					end
					if paramNames[1] == "self" then table.remove(paramNames, 1) end
					
					if #paramNames > 0 then
						parenthesis = "(" .. table.concat(paramNames, ", ") .. ")"
						cursorDelta = - (#parenthesis-1)
						
						-- TODO set selection to arglist when garrysmod-requests/#754 is implemented
					end
				end
				
				choiceValue = choiceValue .. parenthesis
			end

			local text = self.CodeInput:GetText()
			local preText = string.sub(text, 1, self.CodeInput:GetCaretPos())
			local postText = string.sub(text, self.CodeInput:GetCaretPos() + 1)

			local matchLen = findMatchLength(preText, choiceValue)
			preText = string.sub(preText, 1, -matchLen-1)

			local newText = table.concat({preText, choiceValue, postText}, "")
			self.CodeInput:SetText(newText)
			self.CodeInput:SetCaretPos(#preText + #choiceValue + cursorDelta)
			
			local ci = self.CodeInput
			self:Remove()

			-- tab focuses next element and we don't want that so we immediately refocus textentry
			-- TODO there is probably a better way to do this
			timer.Simple(0, function() ci:RequestFocus() end)

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
