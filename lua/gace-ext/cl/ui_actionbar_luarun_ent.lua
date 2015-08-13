gace.AddHook("AddActionBarComponents", "ActionBar_LuaRun_Ents", function(comps)
	comps:AddCategory("Run as", Color(102, 51, 153))

	local function CreateRequest(op, code)
		gace.SendRequest(op, {code = code}, function(_, _, pl)
			if pl.err then
				gace.Log(gace.LOG_ERROR, op .. " failed: ", pl.err)
			else
				gace.Log(op .. " done!")
			end
		end)
	end

	-- source: http://lua-users.org/wiki/StringInterpolation
	local function interp(s, tab)
		return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
	end

	local function FormatCode(template, code, id)
		local includes = gace.entitypath.FindIncludes(template)

		-- TODO include 'includes' files to code

		return ATPromise(function(res)
			local entname, realm = gace.entitypath.Analyze(id)
			local formatted = interp(template, {code = code, entname = entname})
			res:resolve(formatted)
		end)
	end

	comps:AddComponent {
		text = "SWEP",
		fn = function(state)
			local base = [[
local SWEP = weapons.Get("${entname}") or {}
SWEP.Primary = SWEP.Primary or {}
SWEP.Secondary = SWEP.Secondary or {}
${code}
weapons.Register(SWEP, "${entname}", true)
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
local ENT = scripted_ents.Get("${entname}") or {}
${code}
scripted_ents.Register(ENT, "${entname}")
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
