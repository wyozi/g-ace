gace.AddHook("SetupHTMLPanel", "SetupGModAutoCompletionFuncs", function(html)
	html:AddFunction("gace", "QueryGModApi", function(requestid, prefix)
		local acompl = gace.autocompletion.Complete(prefix)
		if #acompl > 0 then
			local mapped = {}
			
			-- convert to Ace-accepted autocompletion objects
			for _,v in pairs(acompl) do
				table.insert(mapped, {name = v.value, value = v.value, meta = "gmod"})
			end
			
			gace.JSBridge().ParseGModQueryResponse(requestid, mapped)
		end
	end)
end)
