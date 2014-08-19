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

function gace.GetOpenSession()
	return gace.Sessions[gace.OpenedSessionId], gace.OpenedSessionId
end

function gace.CreateSession(id, tbl)
	local t = {}

	if tbl then
		if tbl.content then t.Content = tbl.content end
	end

	gace.Sessions[id] = t

	return t
end

function gace.OpenSession(id, callback)
	local sess = gace.GetSession(id)

	gace.OpenedSessionId = id

	if sess then
		gace.SetHTMLSession(id, _, true)
		if callback then callback() end
	else
		sess = gace.CreateSession(id)

		gace.SetHTMLSession(id, "Fetching latest sources from server.")

		gace.Fetch(id, function(_, _, payload)
			if payload.err then
				return gace.Log(gace.LOG_ERROR, "Can't open ", id, ": ", payload.err)
			end

			sess.Content = payload.content
			gace.SetHTMLSession(id, sess.Content)

			if callback then callback() end
		end)
	end

end