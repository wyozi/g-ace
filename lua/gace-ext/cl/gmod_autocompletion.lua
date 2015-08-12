gace.AddHook("SetupHTMLPanel", "SetupGModAutoCompletionFuncs", function(html)
	html:AddFunction("gace", "QueryGModApi", function(requestid, prefix)
		local acompl = gace.autocompletion.Complete(prefix)
		if #acompl > 0 then
			gace.JSBridge().ParseGModQueryResponse(requestid, acompl)
		end
	end)
end)
