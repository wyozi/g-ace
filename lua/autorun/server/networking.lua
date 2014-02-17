function gace.HandleNetworking(ply, reqid, op, payload)

	local responder_func = gace.Send

	-- If reqid is zero or empty, the client (most likely) doesnt care about response, so we dont send anything
	if reqid == "0" or reqid == "" then
		responder_func = function() end
	end

	-- File access
	if op == "ls" then
		responder_func(ply, reqid, op,
			payload.recursive and gace.MakeRecursiveListResponse(ply, payload.path)
							  or  gace.MakeListResponse(ply, payload.path))
	elseif op == "fetch" then
		responder_func(ply, reqid, op, gace.MakeFetchResponse(ply, payload.path))
	elseif op == "save" then
		responder_func(ply, reqid, op, gace.MakeSaveResponse(ply, payload.path, payload.content))
	elseif op == "rm" then
		responder_func(ply, reqid, op, gace.MakeRmResponse(ply, payload.path))
	end

	-- Collab edit
end