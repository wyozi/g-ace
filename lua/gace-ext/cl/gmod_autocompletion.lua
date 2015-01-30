gace.AddHook("SetupHTMLPanel", "SetupGModAutoCompletionFuncs", function(html)
	html:AddFunction("gace", "QueryGModApi", function(requestid, prefix)
		local spl = prefix:Split(".")

		local cur_table = _G

		local i = 1
		while i <= #spl do
			local is_last = i == #spl

			local val = spl[i]
			local lookedup_val = cur_table[val]

			if lookedup_val == nil and not is_last then
				return -- No possibilities found
			end

			if type(lookedup_val) == "table" then
				if is_last then return end -- If last val == table, no useful data to show
				cur_table = lookedup_val

			elseif lookedup_val == nil and is_last then
				local completions = {}
				for key,_ in pairs(cur_table) do
					if key:StartWith(val) then
						table.insert(completions, {
							name = key,
							value = key
						})
					end
				end

				gace.JSBridge().ParseGModQueryResponse(requestid, _u.map(completions, function(pos)
					return {name = pos.name, value = pos.value, meta = "gmod"}
				end))
			else
				return -- No possibilities can be found
			end

			i = i + 1
		end
	end)
end)
