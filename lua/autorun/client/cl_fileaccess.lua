function gace.SendRequest(op, payload, cb)
	local reqid = 0
	if cb then
		reqid = gace.GenReqId(op)
		gace.AddRequestCallback(reqid, cb)
	end
	gace.Send(nil, reqid, op, payload)
end

function gace.List(path, callback, recursive)
	gace.SendRequest("ls", {path=path, recursive=recursive}, callback)
end

function gace.Fetch(path, callback)
	gace.SendRequest("fetch", {path=path}, callback)
end

function gace.Save(path, content, callback)
	gace.SendRequest("save", {path=path, content=content}, callback)
end

function gace.Delete(path, callback)
	gace.SendRequest("rm", {path=path}, callback)
end

function gace.HandleNetworking(reqid, op, payload)

end