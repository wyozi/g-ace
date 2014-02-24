function gace.List(path, callback, recursive)
	if recursive then return ErrorNoHalt("gace.List is no longer recursive. Use gace.ListTree (and remember multipartness)") end
	gace.SendRequest("ls", {path=path, recursive=recursive}, callback)
end

function gace.ListTree(path, callback)
	gace.SendMultiPartRequest("ls", {path=path, recursive=true}, callback)
end

function gace.Fetch(path, callback)
	gace.SendRequest("fetch", {path=path}, callback)
end

function gace.Save(path, content, callback)
	gace.SendRequest("save", {path=path, content=content}, callback)
end

function gace.MkDir(path, callback)
	gace.SendRequest("mkdir", {path=path}, callback)
end

function gace.Delete(path, callback)
	gace.SendRequest("rm", {path=path}, callback)
end

function gace.Find(path, phrase, callback)
	gace.SendRequest("find", {path=path, phrase=phrase}, callback)
end

