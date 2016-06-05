local funcSignatures = gace.autocompletion.funcSignatures

-- Add some common names. These might not be 100% correct (because there is no parent_test) but good enough
funcSignatures["LocalPlayer"] = { ret = { t = "meta", name = "LocalPlayer" } }
funcSignatures["GetParent"] = { ret = { t = "_copyPrev" }}
funcSignatures["GetPos"] = { ret = { t = "meta", name = "Vector" }}
funcSignatures["EyePos"] = { ret = { t = "meta", name = "Vector" }}
funcSignatures["EyeAngles"] = { ret = { t = "meta", name = "Angle" }}

-- Add from some common libraries
funcSignatures["getUser"] = { parent_test = { t = "table", tbl = ULib }, ret = { t = "meta", name = "Player" }}

-- Signatures automatically parsed from GMod wiki

-- Code for parsing:
--[[
local primitives = {number = true, boolean = true, table = true}
local meta = "Weapon"
http.Fetch("https://wiki.garrysmod.com/api.php?action=query&list=categorymembers&cmtitle=Category:" .. meta .. "&cmlimit=1000&format=json", function(json)
	local t = util.JSONToTable(json)
	
	local members = {}
	for _,m in pairs(t.query.categorymembers) do
		table.insert(members, m.title)
	end
	
	local massFetchUrl = "https://wiki.garrysmod.com/api.php?action=query&prop=revisions&format=json&rvprop=content&titles=" .. table.concat(members, "|")
	http.Fetch(massFetchUrl, function(json)
		for id,page in pairs(util.JSONToTable(json).query.pages) do
			local title = page.title
			local rev = page.revisions[1]["*"]
			local returnType = rev:match("{{Ret.-type=(%S*)")
			if returnType then
				local ftitle = title:match("([^/]*)$")
				if primitives[returnType] then
					print(ftitle .. " = { parent_test = parent_test, ret = { t = \"object\", luatype = \"" .. returnType .. "\" } },")
				else
					print(ftitle .. " = { parent_test = parent_test, ret = { t = \"meta\", name = \"" .. returnType .. "\" } },")
				end
			end
		end
	end)
end)
]]

-- Vector methods
local parent_test = { t = "meta", name = "Vector" }
table.Merge(funcSignatures, {
	ToColor = { parent_test = parent_test, ret = { t = "object", luatype = "table" } },
	LengthSqr = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	IsEqualTol = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	WithinAABox = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	ToScreen = { parent_test = parent_test, ret = { t = "object", luatype = "table" } },
	IsZero = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	DotProduct = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	Angle = { parent_test = parent_test, ret = { t = "meta", name = "Angle" } },
	Length2D = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	Distance = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	DistToSqr = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	AngleEx = { parent_test = parent_test, ret = { t = "meta", name = "Angle" } },
	Cross = { parent_test = parent_test, ret = { t = "meta", name = "Vector" } },
	GetNormal = { parent_test = parent_test, ret = { t = "meta", name = "Vector" } },
	GetNormalized = { parent_test = parent_test, ret = { t = "meta", name = "Vector" } },
	Length = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	Dot = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	Length2DSqr = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
})

local parent_test = { t = "meta", name = "Entity" }
table.Merge(funcSignatures, {
	BecomeRagdollOnClient = { parent_test = parent_test, ret = { t = "meta", name = "CSEnt" } },
	BoundingRadius = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	GetAnimInfo = { parent_test = parent_test, ret = { t = "object", luatype = "table" } },
	GetAngles = { parent_test = parent_test, ret = { t = "meta", name = "Angle" } },
	AddGesture = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	GetAbsVelocity = { parent_test = parent_test, ret = { t = "meta", name = "Vector" } },
	BoneHasFlag = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	EntIndex = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	FindTransitionSequence = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	FindBodygroupByName = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	EyePos = { parent_test = parent_test, ret = { t = "meta", name = "Vector" } },
	AddLayeredSequence = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	EyeAngles = { parent_test = parent_test, ret = { t = "meta", name = "Angle" } },
	AddCallback = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	BodyTarget = { parent_test = parent_test, ret = { t = "meta", name = "Vector" } },
	AlignAngles = { parent_test = parent_test, ret = { t = "meta", name = "Angle" } },
	BoneLength = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	AddGestureSequence = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	CreateParticleEffect = { parent_test = parent_test, ret = { t = "meta", name = "CNewParticleEffect" } },
	CreatedByMap = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
})

local parent_test = { t = "meta", name = "Player" }
table.Merge(funcSignatures, {
	AccountID = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	GetAllowWeaponsInVehicle = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	GetAllowFullRotation = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	GetAimVector = { parent_test = parent_test, ret = { t = "meta", name = "Vector" } },
	GetActiveWeapon = { parent_test = parent_test, ret = { t = "meta", name = "Weapon" } },
	Frags = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	FlashlightIsOn = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	CanUseFlashlight = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	Alive = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	Armor = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	CheckLimit = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	Crouching = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	Deaths = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
})

local parent_test = { t = "meta", name = "Weapon" }
table.Merge(funcSignatures, {
	GetPrintName = { parent_test = parent_test, ret = { t = "meta", name = "string" } },
	Clip1 = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	GetSlot = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	AllowsAutoSwitchTo = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	IsScripted = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	GetSecondaryAmmoType = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	HasAmmo = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	LastShootTime = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	IsWeaponVisible = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	IsCarriedByLocalPlayer = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	Clip2 = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	GetWeight = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	GetWeaponWorldModel = { parent_test = parent_test, ret = { t = "meta", name = "string" } },
	GetMaxClip2 = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	GetWeaponViewModel = { parent_test = parent_test, ret = { t = "meta", name = "string" } },
	AllowsAutoSwitchFrom = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	GetSlotPos = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	GetHoldType = { parent_test = parent_test, ret = { t = "meta", name = "string" } },
	GetActivity = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	DefaultReload = { parent_test = parent_test, ret = { t = "object", luatype = "boolean" } },
	GetNextPrimaryFire = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	GetNextSecondaryFire = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	GetPrimaryAmmoType = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
	GetMaxClip1 = { parent_test = parent_test, ret = { t = "object", luatype = "number" } },
})
