gace.AddHook("AddActionBarComponents", "ActionBar_LuaRun", function(comps)
	comps:AddComponent {
		text = "Run as",
		fn = function(state)
			local menu = DermaMenu()

			menu:AddOption("Scripted weapon", function()
				local base = [[
local SWEP = {}
SWEP.Primary = {}
SWEP.Secondary = {}
%s
weapons.Register(SWEP, "%s", true)
				]]

				luadev.RunOnShared(
					string.format(base, gace.GetSessionContent(), gace.GetExtlessSessionId()),
					"g-ace swep: " .. (gace.GetSessionId() or "")
				)
			end)
			menu:AddOption("Scripted entity", function()
				local base = [[
local ENT = {}
%s
scripted_ents.Register(ENT, "%s")
				]]

				luadev.RunOnShared(
					string.format(base, gace.GetSessionContent(), gace.GetExtlessSessionId()),
					"g-ace sent: " .. (gace.GetSessionId() or "")
				)
			end)

			menu:Open()
		end,
		enabled = function() return luadev ~= nil end,
		tt = "Runs the code as if it was a SWEP or a SENT"
	},
end)