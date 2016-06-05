gace.autocompletion = {}

local funcSignatures = {
	["LocalPlayer"] = { ret = { t = "table", tbl = function()
		local items = {}
		for k,v in pairs(FindMetaTable("Player")) do items[k] = v end
		for k,v in pairs(LocalPlayer():GetTable()) do items[k] = v end
		return items
	end } },
	["getUser"] = { parent_test = { t = "table", tbl = ULib }, ret = { t = "table", tbl = FindMetaTable("Player") }}
}

local function getTableTypeTable(typ)
	local tbl = typ.tbl
	if type(tbl) == "table" then
		return tbl
	else
		return tbl()
	end
end

local function identifyType(node, prevType)
	if prevType and prevType.t == "table" then
		local tbl = getTableTypeTable(prevType)
		local indexed = tbl[node]
		
		if prevType.requireMethod then
			-- note: do not merge this if with above if; if method is required the if chain should terminate if it's not a a method
			if type(indexed) == "function" then
				return { t = "object", obj = indexed }
			end
		elseif type(indexed) == "table" then
			return { t = "table", tbl = indexed }
		elseif indexed ~= nil then
			return { t = "object", obj = indexed}
		end
	end
	
	local fnName = node:match("([%a_][%w_]*)%b()")
	if fnName then
		local sig = funcSignatures[fnName]
		if sig then
			local passTest = true
			
			-- signature might require specific kind of parent (or prev node)
			if sig.parent_test then
				if not prevType then -- prevnode must exist
					passTest = false
				else
					-- make sure parent test values equal to prev node values
					for k,v in pairs(sig.parent_test) do
						if prevType[k] ~= v then
							passTest = false
							break
						end
					end
				end
			end
			
			if passTest then
				return sig.ret
			end
		end
	end

	return {}
end

local function otype(obj)
	if type(obj) == "function" then
		return "function"
	end
end
	
function gace.autocompletion.Complete(text, opts)
	local relevantText = text:match("(%S*)$")
	local ret = {}
	
	local typ = {t = "table", tbl = (opts and opts.context) or _G}
	
	local i = 1
	local nendChar
	for node, endChar in string.gmatch(relevantText, "(.-)([:%.])") do
		typ = identifyType(node, typ)
		
		if nendChar == ":" then
			typ.requireMethod = true
		end
		--print("node: ", node, " has type: ", table.ToString(typ))
		
		i = i + #node + 1
		nendChar = endChar
	end
	
	local lastNode = relevantText:sub(i)
	
	-- table-based autocompletion
	if typ.t == "table" then
		local lastNodel = lastNode:lower()
		local tbl = getTableTypeTable(typ)
		for name,val in pairs(tbl) do
			if type(name) == "string" and name:lower():StartWith(lastNodel) then
				local rtype, cinfo = otype(val)
				table.insert(ret, {value = name, obj = val, type = rtype, contextInfo = cinfo})
			end
		end
	end
	
	return ret
end
