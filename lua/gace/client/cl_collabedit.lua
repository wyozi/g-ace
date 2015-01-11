gace.CollabPositions = gace.CollabPositions or {}

function gace.SetCollabFile(payload)
	gace.CollabPositions[payload.ply] = payload.path
end