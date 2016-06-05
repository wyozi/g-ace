gace.autocompletion = {}

local funcSignatures = {}
gace.autocompletion.funcSignatures = funcSignatures

local function inheritsMeta(name, meta)
	if name == "LocalPlayer" then
		return meta == "Player" or inheritsMeta("Player", meta)
	elseif (name == "Player" or name == "Vehicle" or name == "Weapon") and meta == "Entity" then
		return true
	end
	return name == meta
end

local function getTableTypeTable(typ)
	if typ.t == "meta" then
		if typ.name == "LocalPlayer" then
			local items = {}
			for k,v in pairs(FindMetaTable("Entity")) do items[k] = v end
			for k,v in pairs(FindMetaTable("Player")) do items[k] = v end
			for k,v in pairs(LocalPlayer():GetTable()) do items[k] = v end
			return items
		elseif inheritsMeta(typ.name, "Entity") then
			local items = {}
			for k,v in pairs(FindMetaTable("Entity")) do items[k] = v end
			for k,v in pairs(FindMetaTable(typ.name)) do items[k] = v end
			return items
		end
		return FindMetaTable(typ.name)
	end
	local tbl = typ.tbl
	if type(tbl) == "table" then
		return tbl
	else
		return tbl()
	end
end

local function identifyCallName(fnName, prevType)
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
					-- the second part of if tests for meta inheritance
					if prevType[k] ~= v and (prevType.t ~= "meta" or k ~= "name" or not inheritsMeta(prevType.name, v)) then
						passTest = false
						break
					end
				end
			end
		end
		
		if passTest then
			if sig.ret.t == "_copyPrev" then
				return prevType
			else
				return sig.ret
			end
		end
	end
end

local function identifyType(node, prevType)
	if prevType and (prevType.t == "table" or prevType.t == "meta") then
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
		local callt = identifyCallName(fnName, prevType)
		if callt then
			return callt
		end
	end

	return {}
end

local function otype(obj)
	-- Middleclass support
	if type(obj) == "table" and type(obj.class) == "table" and type(obj.class.name) == "string" then
		return string.format("class %s", obj.class.name)
	end
	
	return type(obj)
end
	
function gace.autocompletion.Complete(text, opts)
	local relevantText = text:match("(%S*)$")
	local ret = {}
	
	local initTyp = {t = "table", tbl = (opts and opts.context) or _G} 
	local typ = initTyp
	
	local i = 1
	local nendChar
	for node, endChar in string.gmatch(relevantText, "(.-)([:%.])") do
		typ = identifyType(node, typ)
		
		-- if in first node, no proper typ was found check for global extras
		if i == 1 and not typ.t and opts and opts.globalExtras then
			local extra = opts.globalExtras[node]
			if extra then
				typ = extra
			end
		end
		
		if typ.t == "table" and nendChar == ":" then
			typ.requireMethod = true
		end
		--print("node: ", node, " has type: ", table.ToString(typ))
		
		i = i + #node + 1
		nendChar = endChar
	end
	
	local lastNode = relevantText:sub(i)
	local lastNodel = lastNode:lower()
	
	-- table-based autocompletion
	if typ.t == "table" or typ.t == "meta" then
		local tbl = getTableTypeTable(typ)
		for name,val in pairs(tbl) do
			if type(name) == "string" and name:lower():StartWith(lastNodel) then
				local rtype = otype(val)
				
				local cinfo
				if rtype == "function" then
					local fntype = identifyCallName(name, typ)
					if fntype then
						if fntype.t == "object" then
							cinfo = { returnType = fntype.luatype }
						elseif fntype.t == "meta" then
							cinfo = { returnType = fntype.name }
						end
					end
				end
				
				table.insert(ret, {value = name, obj = val, type = rtype, contextInfo = cinfo})
			end
		end
	end
	
	-- if we're still in global scope, add global extras
	if initTyp == typ and opts and opts.globalExtras then
		for name,_ in pairs(opts.globalExtras) do
			if name:lower():StartWith(lastNodel) then
				table.insert(ret, {value = name})
			end
		end
	end
	
	table.sort(ret, function(a, b)
		return #a.value < #b.value
	end)
	
	return ret
end
