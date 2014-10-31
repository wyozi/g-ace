function gace.SendRequest(op, payload, cb)
	local reqid = 0
	if cb then
		reqid = gace.GenReqId(op)
		gace.AddRequestCallback(reqid, cb)
	end
	gace.Send(nil, reqid, op, payload)
end

function gace.SendMultiPartRequest(op, payload, cb)
	local reqid = 0
	if cb then
		reqid = gace.GenReqId(op)
		gace.AddRequestCallback(reqid, cb, true)
	end
	gace.Send(nil, reqid, op, payload)
end

function gace.HandleNetworking(reqid, op, payload)
	if op == "colsetfile" then
		gace.SetCollabFile(payload)
	elseif op == "git_updstatus" then
		for file,status in pairs(payload) do
			local pathobj = gace.Path(file)
			local vfoldername = pathobj:GetVFolder()

			if status == "empty" then status = nil end

			local vfolder = gace.VFolders[vfoldername]
			if vfolder and vfolder.git then
				vfolder.git.filestatuses = vfolder.git.filestatuses or {}
				vfolder.git.filestatuses[pathobj:WithoutVFolder():ToString()] = status
			end
		end
	end
end