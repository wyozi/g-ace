-- "Sessions" table format
-- Key: session id (aka filename of the opened file)
-- Value: Table containing session specific data
--		Contents: String of latest contents

gace.Sessions = {}
gace.OpenedSessionId = nil

-- A VFolder specific cache thing. Can be used for eg git integration which is per vfolder
gace.VFolders = {}

gace.AddHook("ClearGAceVariables", "ClearSessions", function()
	gace.Sessions = {}
	gace.VFolders = {}
	gace.OpenedSessionId = nil
end)

local session_meta = {}
session_meta.__index = session_meta

session_meta.GetExtensionlessName = function(self)
	return string.StripExtension(gace.Path(self.Id):GetFile())
end

session_meta.IsSaved = function(self)
	-- TODO optimize; this gets called like a thousand times from all around the code.
	-- Maybe use a simple boolean flag instead of full string check?
	return self.SavedContent == self.Content
end

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
	t.Id = id

	setmetatable(t, session_meta)

	if tbl then
		if tbl.content then t.Content = tbl.content end
	end

	gace.Sessions[id] = t

	local vfolder = gace.Path(id):GetVFolder()
	gace.VFolders[vfolder] = gace.VFolders[vfolder] or {Name = vfolder}

	t.VFolder = gace.VFolders[vfolder]

	return t
end

function gace.OpenSession(id, data)
	if gace.OpenedSessionId == id then
		if data and data.callback then data.callback() end
		return
	end

	local sess = gace.GetSession(id)

	gace.OpenedSessionId = id

	gace.CallHook("OnSessionOpened", id)

	local sess_exists = sess ~= nil

	if not sess_exists then
		sess = gace.CreateSession(id)
	end

	if sess_exists or (data and data.content) then
		gace.SetHTMLSession(id, (data and data.content) and data.content or nil, true, (data and data.mode))

		if (data and data.content) then
			sess.Content = data.content
			if not data.mark_unsaved then
				sess.SavedContent = data.content
			end
		end

		if data and data.callback then data.callback() end
	else
		gace.SetHTMLSession(id, "Fetching latest sources from server.")

		gace.cmd.cat(LocalPlayer(), id):then_(function(t)
			sess.Content = t.data
			if not data or not data.mark_unsaved then
				sess.SavedContent = sess.Content
			end
			gace.SetHTMLSession(id, sess.Content, nil, (data and data.mode))

			if data and data.callback then data.callback() end
		end):catch(function(e)
			gace.Log(gace.LOG_ERROR, "Can't open ", id, ": ", e)
		end)
	end

end

function gace.CloseSession(id)
	gace.JSBridge().gaceSessions.removeSession(id)
	
	if gace.GetSessionId() == id then
		gace.OpenedSessionId = nil
	end

	gace.Sessions[id] = nil

	gace.CallHook("OnSessionClosed", id)
end
