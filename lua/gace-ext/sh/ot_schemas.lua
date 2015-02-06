gace.netschemas.Register("ot-sub", {"string id"})
gace.netschemas.Register("ot-unsub", {"string id"})
gace.netschemas.Register("ot-cursor", {"string id", "int start", "int end"})

-- Serialization and deserialization for an OT operation
local ot_op_handler = {
	name = "op",
	type = {
		read = function()
			local ops = {}

			local opCount = net.ReadUInt(8)
			for i=1, opCount do
				local op = net.ReadInt(32)
				if op == 0 then
					table.insert(ops, net.ReadString())
				else
					table.insert(ops, op)
				end
			end

			return ops
		end,
		write = function(val)
			net.WriteUInt(#val, 8)
			for _, op in ipairs(val) do
				if type(op) == "string" then
					net.WriteUInt(0, 32)
					net.WriteString(op)
				else
					net.WriteUInt(op, 32)
				end
			end
		end
	}
}

gace.netschemas.Register("ot-apply", {"string id", "int rev", ot_op_handler})
gace.netschemas.Register("ot-applysv", {"string id", "entity user", ot_op_handler})
