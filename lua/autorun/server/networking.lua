function gace.HandleNetworking(ply, reqid, op, payload)

	local responder_func = function(ply, reqid, op, payload)
		if payload.multipart then
			for _,part in pairs(payload.parts) do
				gace.Send(ply, reqid, op, part)
			end
			return
		end
		gace.Send(ply, reqid, op, payload)
	end

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
	elseif op == "mkdir" then
		responder_func(ply, reqid, op, gace.MakeMkDirResponse(ply, payload.path))
	elseif op == "rm" then
		responder_func(ply, reqid, op, gace.MakeRmResponse(ply, payload.path))
	elseif op == "find" then
		responder_func(ply, reqid, op, gace.MakeFindResponse(ply, payload.path, payload.phrase))
	end

	-- Collab edit
	if op == "colsetfile" then
		local targs = gace.FindCollabTargets(payload.path, ply)
		gace.Send(targs, "", "colsetfile", {ply=ply, path=payload.path})
	end

	-- Git integration
	if op == "git-status" then
		responder_func(ply, reqid, op, gace.Git_MakeStatusResponse(ply, payload.path))
	elseif op == "git-log" then
		responder_func(ply, reqid, op, gace.Git_MakeLogResponse(ply, payload.path))
	elseif op == "git-push" then
		responder_func(ply, reqid, op, gace.Git_MakePushResponse(ply, payload.path))
	elseif op == "git-commitall" then
		responder_func(ply, reqid, op, gace.Git_MakeCommitAllResponse(ply, payload.path, payload.msg))
	end
end
