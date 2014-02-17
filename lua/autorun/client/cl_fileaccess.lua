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
