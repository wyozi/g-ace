function gace.SendRequest(op, payload, cb)
	local reqid = cb and gace.GenReqId(op) or 0

	local netmsg = gace.NetMessageOut(reqid, op, payload)
	if cb then netmsg:ListenToResponse(cb) end
	netmsg:Send()
end

function gace.SendMultiPartRequest(op, payload, cb)
	-- TODO add the actual multipartness lol
	local reqid = cb and gace.GenReqId(op) or 0

	local netmsg = gace.NetMessageOut(reqid, op, payload)
	if cb then netmsg:ListenToResponse(cb) end
	netmsg:Send()
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
