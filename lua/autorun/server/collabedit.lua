-- This function should parse the path and return which players should receive collaboration packets from this ply
-- Atm it just returns a list of all superadmins. TODO
function gace.FindCollabTargets(path, ply)
	local plys = {}
	for _,ply in pairs(player.GetAll()) do
		if ply:IsSuperAdmin() then
			table.insert(plys, ply)
		end
	end
	return plys
end