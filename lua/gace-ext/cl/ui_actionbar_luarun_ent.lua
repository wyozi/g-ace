gace.AddHook("AddActionBarComponents", "ActionBar_LuaRun_Ents", function(comps)
	comps:AddCategory("Run as", Color(39, 174, 96))

	local function CreateRequest(op, code)
		gace.SendRequest(op, {code = code}, function(_, _, pl)
			if pl.err then
				gace.Log(gace.LOG_ERROR, op .. " failed: ", pl.err)
			else
				gace.Log(op .. " done!")
			end
		end)
	end

	comps:AddComponent {
		text = "SWEP",
		fn = function(state)
			local base = [[
local SWEP = {}
SWEP.Primary = {}
SWEP.Secondary = {}
%s
weapons.Register(SWEP, "%s", true)
			]]

			CreateRequest("lua-runsh", string.format(base, gace.GetOpenSession().Content, gace.GetOpenSession():GetExtensionlessName()))
		end,
		enabled = function() return gace.IsSessionOpen() end,
		tt = "Runs the code as SWEP. SWEP name is equal to extensionless file name"
	}
	comps:AddComponent {
		text = "SENT",
		fn = function(state)
			local base = [[
local ENT = {}
%s
scripted_ents.Register(ENT, "%s")
			]]

			CreateRequest("lua-runsh", string.format(base, gace.GetOpenSession().Content, gace.GetOpenSession():GetExtensionlessName()))
		end,
		enabled = function() return gace.IsSessionOpen() end,
		tt = "Runs the code as SENT. SENT name is equal to extensionless file name"
	}
	comps:AddCategoryEnd()

end)
