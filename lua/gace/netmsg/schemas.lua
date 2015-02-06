-- Schemas are basically blueprints for how data for specific opcode should be
-- transferred over the internet. Netmsgobj only supports table as the payload,
-- but when we go on stream level, we can treat it as data all we want.
--
-- Because responses don't have opcodes, schemas only work for non-response netmsgs
--
-- Schemas work especially well for small netmessages that get sent frequently

gace.netschemas = {}
gace.netschemas.Schemas = {}

function gace.netschemas.Get(op)
	return gace.netschemas.Schemas[op]
end

function gace.netschemas.Write(op, payload)
	local schema = gace.netschemas.Get(op)
	if not schema then
		net.WriteTable(payload)
	else
		gace.Debug("Writing netmsgobj of ", op, " using a schema")
		for _,t in ipairs(schema.types) do
			local val = payload[t.name]
			t.handler.write(val)
		end
		gace.Debug("Wrote netmsgobj of ", op, " using a schema")
	end
end
function gace.netschemas.Read(op)
	local schema = gace.netschemas.Get(op)
	if not schema then
		return net.ReadTable(payload)
	else
		gace.Debug("Reading netmsgobj of ", op, " using a schema")

		local tbl = {}

		for _,t in ipairs(schema.types) do
			tbl[t.name] = t.handler.read()
		end

		return tbl
	end
end

local typeHandlers = {
	int = {
		read = function()
			return net.ReadInt(32)
		end,
		write = function(val)
			net.WriteInt(val, 32)
		end
	},
	entity = {
		read = net.ReadEntity,
		write = net.WriteEntity
	},
	string = {
		read = net.ReadString,
		write = net.WriteString
	}
}

-- Registers a new schema
function gace.netschemas.Register(op, types)
	-- Parse types
	local parsedTypes = {}
	for _,t in ipairs(types) do
		local ntype, name
		if type(t) == "string" then
			ntype, name = t:match("(%a+) (%a+)")
		elseif type(t) == "table" then
			ntype = t.type
			name = t.name
		end

		local handler = ntype
		if type(handler) == "string" then
			handler = typeHandlers[ntype]
			if not handler then
				error("Attempting to register netschema with unknown ntype '" .. tostring(ntype) .. "'")
				return
			end
		end

		table.insert(parsedTypes, {name = name, handler = handler})
	end

	gace.netschemas.Schemas[op] = {
		types = parsedTypes
	}
end

gace.netschemas.Register("ayy", {"int kek", "string sup"})
