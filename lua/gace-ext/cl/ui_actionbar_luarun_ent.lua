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

	local function FormatCode(template, code, id)
		local includes = gace.entitypath.FindIncludes(template)

		-- TODO include 'includes' files to code

		return Promise(function(res)
			local entname, realm = gace.entitypath.Analyze(id)
			local formatted = string.format(template, code, entname)
			res:resolve(formatted)
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

			local code = gace.GetOpenSession().Content
			local id = gace.GetSessionId()
			FormatCode(base, code, id):done(function(formattedCode)
				local entname, realm = gace.entitypath.Analyze(id)
				CreateRequest("lua-run" .. realm, formattedCode)
			end)
		end,
		enabled = function() return gace.IsSessionOpen() end,
		tt = "Runs the code as SWEP. SWEP ClassName is guessed from the filename"
	}
	comps:AddComponent {
		text = "SENT",
		fn = function(state)
			local base = [[
local ENT = {}
%s
scripted_ents.Register(ENT, "%s")
			]]


			local code = gace.GetOpenSession().Content
			local id = gace.GetSessionId()
			FormatCode(base, code, id):done(function(formattedCode)
				local entname, realm = gace.entitypath.Analyze(id)
				CreateRequest("lua-run" .. realm, formattedCode)
			end)
		end,
		enabled = function() return gace.IsSessionOpen() end,
		tt = "Runs the code as SENT. SENT ClassName is guessed from the filename"
	}
	comps:AddCategoryEnd()

end)
