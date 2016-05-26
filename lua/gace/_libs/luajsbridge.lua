luajsbridge = {}
luajsbridge.Callbacks = {}

function luajsbridge.Debug(...)
	--MsgN("[LuaJSBridge] ", ...)
end
function luajsbridge.Error(...)
	error("LuaJSBridge: " .. table.concat({...}, ""))
end

function luajsbridge.JSEscape(str)
	return str:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\'", "\\'"):gsub("\r", "\\r"):gsub("\n", "\\n")
end

-- If you want arrays to be handled properly, you need https://github.com/craigmj/json4lua
function luajsbridge.JSONify(tbl)
	return util.TableToJSON(tbl)
end

function luajsbridge.ToJS(obj)
	local t = type(obj)
	if t == "string" then
		return "\"" .. luajsbridge.JSEscape(obj) .. "\""
	elseif t == "number" then
		return tostring(obj)
	elseif t == "table" then
		return "JSON.parse(" .. luajsbridge.ToJS(luajsbridge.JSONify(obj)) .. ")"
	elseif t == "function" then
		local id = #luajsbridge.Callbacks + 1
		luajsbridge.Callbacks[id] = obj
		return "function(a,b,c,d,e,f,g,h,i) { luajsbridge.OnCallback(" .. id .. ", a,b,c,d,e,f,g,h,i) }"
	end
	luajsbridge.Error("Trying to JSify invalid type " .. t)
end

function luajsbridge.CreateBridge(pnl)
	return setmetatable({
		_pnl = pnl,
		_pathComps = {}
	}, luajsbridge.Meta)
end

luajsbridge.Meta = {}

function luajsbridge.Meta:__index(key)
	if key:sub(1, 1) == "_" then
		return rawget(self, key)
	end

	luajsbridge.Debug("Creating a SubBridge for ", key, " in ", table.concat(self._pathComps, "."))

	local subBridge = luajsbridge.CreateBridge(self._pnl)
	table.Add(subBridge._pathComps, self._pathComps)
	table.insert(subBridge._pathComps, key)

	return subBridge
end
function luajsbridge.Meta:__call(...)
	local params = {}
	for _,v in ipairs{...} do
		table.insert(params, luajsbridge.ToJS(v))
	end

	local js = string.format("%s(%s)", table.concat(self._pathComps, "."), table.concat(params, ","))
	luajsbridge.Debug("Running JS: ", js)

	self._pnl:RunJavascript(js)
end

hook.Add("InitPostEntity", "LJSBridge_OverrideDHTMLInit", function()
	-- Override DHTML:Init() to automatically create a Bridge per DHTML component
	local tbl = vgui.GetControlTable("DHTML")

	local oldinit = tbl.OldInit or tbl.Init
	tbl.OldInit = oldinit
	function tbl:Init()
		oldinit(self)

		self.Bridge = luajsbridge.CreateBridge(self)
		self:AddFunction("luajsbridge", "OnCallback", function(id, ...)
			luajsbridge.Debug("OnCallback #", id,  " called with args: ", ...)
			local cb = luajsbridge.Callbacks[id]

			if not cb then luajsbridge.Error("Callback #" .. id .. " does not exist") end

			cb(...)
		end)
	end
end)

concommand.Add("ljsbridge_test", function()
	local dhtml = vgui.Create("DHTML")
	dhtml:SetHTML([[
		<script>
		test = {}
		test.inner = {}
		test.inner.func = function(str, num, obj, arr, cb) {
			console.log("str: " + str);
			console.log("num: " + num);
			console.log("obj.str: " + obj.str);
			console.log("obj.num: " + obj.num);
			console.log("obj.innerTable.key: " + obj.innerTable.key);

			console.log("arr[1]: " + arr[1]);
			console.log("arr[2].a: " + arr[2].a);

			cb("js-string", 32);
		}
		</script>
	]])

	local bridge = dhtml.Bridge

	bridge.test.inner.func("Hello JS", 42, {
		str = "string",
		num = 13,
		innerTable = {
			key = "value"
		}
	}, {3, 2, {a = "b"}}, function(a, b)
		print("callback: ", a, b)
	end)

	-- Need to give some time for JS to run
	timer.Simple(2, function()
		dhtml:Remove()
	end)
end)
