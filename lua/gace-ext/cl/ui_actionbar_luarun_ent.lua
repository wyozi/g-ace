gace.AddHook("AddActionBarComponents", "ActionBar_LuaRun_Ents", function(comps)
	comps:AddCategory("Run as", Color(39, 174, 96))
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

			luadev.RunOnShared(
				string.format(base, gace.GetOpenSession().Content, gace.GetOpenSession():GetExtensionlessName()),
				"g-ace swep: " .. (gace.GetSessionId() or "")
			)
		end,
		enabled = function() return luadev ~= nil and gace.IsSessionOpen() end,
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

			luadev.RunOnShared(
				string.format(base, gace.GetOpenSession().Content, gace.GetOpenSession():GetExtensionlessName()),
				"g-ace sent: " .. (gace.GetSessionId() or "")
			)
		end,
		enabled = function() return luadev ~= nil and gace.IsSessionOpen() end,
		tt = "Runs the code as SENT. SENT name is equal to extensionless file name"
	}
	comps:AddCategoryEnd()

end)