gace.AddHook("AddActionBarComponents", "ActionBar_LuaRun_Ents", function(comps)
	comps:AddCategory("Run as", Color(102, 51, 153))

	-- source: http://lua-users.org/wiki/StringInterpolation
	local function interp(s, tab)
		return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
	end

	local function FormatCode(template, code, id)
		code = gace.entitypath.RebaseIncludes(id, code)
		return ATPromise(function(res)
			local entname, realm = gace.entitypath.Analyze(id)
			local formatted = interp(template, {code = code, entname = entname})
			res:resolve(formatted)
		end)
	end

	local function GetSLuaFormat(slua)
		local testSwep = slua:find("SWEP[%.:]")
		if testSwep then
			return [[
local SWEP = weapons.GetStored("${entname}") or { t = {} }
SWEP.Primary = SWEP.Primary or {}
SWEP.Secondary = SWEP.Secondary or {}
${code}
weapons.Register(SWEP, "${entname}", true)
			]]
		end
		
		local testSent = slua:find("ENT[%.:]")
		if testSent then
			return [[ _OLDENT = ENT; ENT = scripted_ents.GetStored("${entname}") or { t = {} }; ENT = ENT.t;
${code}
scripted_ents.Register(ENT, "${entname}")
ENT = _OLDENT;
_OLDENT = nil;
			]]
		end
		
		local testEff = slua:find("EFFECT[%.:]")
		if testEff then
			return [[
local EFFECT = effects.Create("${entname}") or {}
${code}
effects.Register(EFFECT, "${entname}")
			]], "cl"
		end
	end

	local function runSLua(forceRealm, target)
		local code = gace.GetOpenSession().Content
		local id = gace.GetSessionId()
		
		local base, frealm = GetSLuaFormat(code)
		
		if not base then
			gace.Log(gace.LOG_ERROR, "File contents not recognized as SWEP/SENT/STool")
			return
		end

		FormatCode(base, code, id):done(function(formattedCode)
			local entname, arealm = gace.entitypath.Analyze(id)
			
			local realm = forceRealm or frealm or arealm
			local op = "lua-run" .. realm
			
			local sess = gace.GetOpenSession()
			local codeId = ("gace://%s"):format(sess.Id)
			
			gace.SendRequest(op, {codeId = codeId, code = formattedCode, target = target}, function(_, _, pl)
				if pl.err then
					gace.Log(gace.LOG_ERROR, op .. " failed: ", pl.err)
				else
					gace.Log(op .. " done!")
				end
			end)
		end)
	end

	comps:AddComponent {
		text = "SLua",
		fn = function(state)
			runSLua()
		end,
		splitFn = function(menu)
			menu:AddOption("Run on self", function() runSLua("cl") end)
			menu:AddOption("Run on server", function() runSLua("sv") end)
			menu:AddSpacer()
			for _,p in pairs(player.GetAll()) do
				menu:AddOption("Run on " .. p:Nick(), function() runSLua("target", p) end)
			end
		end,
		enabled = function() return gace.IsSessionOpen() end,
		tt = "Runs the code as either SWEP/SENT/STool. Which one to run and ClassName are guessed from the filename and contents"
	}

end)
