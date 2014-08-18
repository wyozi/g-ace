-- "Sessions" table format
-- Key: session id (aka filename of the opened file)
-- Value: Table containing session specific data
--		Contents: String of latest contents

gace.Sessions = {}
gace.OpenedSessionId = nil

function gace.GetSession(id)
	return gace.Sessions[id]
end

function gace.SessionExists(id)
	return gace.Sessions[id] ~= nil
end

function gace.GetOpenedSession()
	return gace.Sessions[gace.OpenedSessionId]
end

function gace.CreateSession(id, tbl)
	local t = {}

	if tbl then
		if tbl.contents then t.Contents = tbl.contents end
	end

	gace.Sessions[id] = t

	return t
end

function gace.OpenSession(id, callback)
	local sess = gace.GetSession(id)
	if sess then
		gace.OpenedSessionId = id
		if callback then callback(true) end
		return
	end

	gace.Fetch(id, function(_, _, payload)
		if payload.err then
			return MsgN("[G-Ace] Can't open ", id, ": ", payload.err)
		end
		gace.CreateSession(id, {contents = payload.content})
		if callback then callback(false) end
	end)
end