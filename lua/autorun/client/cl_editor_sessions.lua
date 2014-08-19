-- "Sessions" table format
-- Key: session id (aka filename of the opened file)
-- Value: Table containing session specific data
--		Contents: String of latest contents

gace.Sessions = {}
gace.OpenedSessionId = nil

function gace.IsSessionOpen()
	return gace.OpenedSessionId ~= nil
end

function gace.GetSession(id)
	return gace.Sessions[id]
end

function gace.GetSessionId()
	return gace.OpenedSessionId
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

function gace.OpenSession(id, data)
	if gace.OpenedSessionId == id then return end

	local sess = gace.GetSession(id)

	gace.OpenedSessionId = id

	gace.CallHook("OnSessionOpened", id)

	local sess_exists = sess ~= nil

	if not sess_exists then
		sess = gace.CreateSession(id)
	end

	if sess_exists or (data and data.content) then
		gace.SetHTMLSession(id, (data and data.content) and data.content or nil, true)

		if (data and data.content) then
			sess.SavedContent = data.content
		end

		if data and data.callback then callback() end
	else
		gace.SetHTMLSession(id, "Fetching latest sources from server.")

		gace.Fetch(id, function(_, _, payload)
			if payload.err then
				return gace.Log(gace.LOG_ERROR, "Can't open ", id, ": ", payload.err)
			end

			sess.Content = payload.content
			sess.SavedContent = sess.Content
			gace.SetHTMLSession(id, sess.Content)

			if data and data.callback then callback() end
		end)
	end

end

function gace.CloseSession(id)
	gace.RunJavascript([[
		gaceSessions.removeSession("]] .. id .. [[");
	]])
	if gace.GetSessionId() == id then
		gace.OpenedSessionId = nil
	end

	gace.CallHook("OnSessionClosed", id)
end