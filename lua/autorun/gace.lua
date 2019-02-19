gace = gace or {}

local function load(file, type)
	type = type or "shared"

	local _server = type == "server" or type == "shared"
	local _client = type == "client" or type == "shared"

	if SERVER then
		if _client then AddCSLuaFile(file) end
		if _server then include(file) end
	end
	if CLIENT then
		if _client then include(file) end
	end
end

-- TODO move somewhere else
function gace.Error(str)
	ErrorNoHalt(str)
end

-- Load libraries
load("gace/_libs/andthen.lua", "shared")
load("gace/_libs/middleclass.lua", "shared")
load("gace/_libs/underscore.lua", "shared")
load("gace/_libs/luajsbridge.lua", "client")

-- Load GAce files

-- Schemas can be registered by all files so this needs to be first
load("gace/netmsg/schemas.lua")

load("gace/util/logging.lua")
load("gace/util/miscutils.lua")
load("gace/util/hooks.lua")
load("gace/util/entitypath.lua")
load("gace/util/autocompletion.lua")
load("gace/util/autocompletion_funcsigs.lua")

load("gace/cache/cache.lua")
load("gace/cache/cache_simple.lua")
load("gace/cache/cachesync_filesystem.lua")

load("gace/netmsg/reqid.lua")
load("gace/netmsg/protocol_netlib.lua")
load("gace/netmsg/netmsgobj.lua")

load("gace/cmd/commands.lua")
load("gace/cmd/ipc.lua")

load("gace/util/tablesplit.lua")
load("gace/util/eventemitter.lua")
load("gace/util/path.lua")
load("gace/util/promisehelpers.lua")

load("gace/vfs/_vfs.lua")
load("gace/vfs/node.lua")
load("gace/vfs/file.lua")
load("gace/vfs/folder.lua")

load("gace/vfs/virtual/virtualfile.lua")
load("gace/vfs/virtual/virtualfolder.lua")

load("gace/vfs/memory/memoryfile.lua")
load("gace/vfs/memory/memoryfolder.lua")

load("gace/vfs/net/netfile.lua", "client")
load("gace/vfs/net/netfolder.lua", "client")

load("gace/vfs/real-data/realdatafile.lua")
load("gace/vfs/real-data/realdatafolder.lua")

load("gace/vfs/real-gaceio/_gaceio.lua", "server")
load("gace/vfs/real-gaceio/realgaceiofile.lua", "server")
load("gace/vfs/real-gaceio/realgaceiofolder.lua", "server")

load("gace/vfs-cmds/grep.lua")
load("gace/vfs-cmds/cat.lua")
load("gace/vfs-cmds/cp.lua")
load("gace/vfs-cmds/mv.lua")
load("gace/vfs-cmds/ls.lua")
load("gace/vfs-cmds/mkvfolder.lua")
load("gace/vfs-cmds/write.lua")

load("gace/ext/extloader.lua")

-- Load all client crap
load("gace/client/cl_editor_base.lua", "client")
load("gace/client/cl_editor_sessions.lua", "client")
load("gace/client/cl_editor_tabs.lua", "client")
load("gace/client/cl_editor_ui.lua", "client")
load("gace/client/cl_filetree.lua", "client")
load("gace/client/cl_htmlfuncs.lua", "client")
load("gace/client/cl_networking.lua", "client")
load("gace/client/vfs.lua", "client")

load("gace/vgui/vgui_dynamicpanel.lua", "client")
load("gace/vgui/vgui_gacebutton.lua", "client")
load("gace/vgui/vgui_gacesplitter.lua", "client")
load("gace/vgui/vgui_gacetab.lua", "client")
load("gace/vgui/vgui_gacetabsel.lua", "client")
load("gace/vgui/vgui_gacetextinput.lua", "client")
load("gace/vgui/vgui_gacecodeinput.lua", "client")
load("gace/vgui/vgui_gacetree.lua", "client")

-- Load GAce testing lib and tests
load("gace-tests/_gacetests.lua", "shared")
load("gace-tests/utils.lua", "shared")
load("gace-tests/path.lua", "shared")
load("gace-tests/pathobj.lua", "shared")
load("gace-tests/netmsgobj.lua", "shared")
load("gace-tests/ui_gacetree.lua", "shared")
load("gace-tests/reqid.lua", "shared")
load("gace-tests/ot.lua", "shared")
load("gace-tests/tablesplit.lua", "shared")

load("gace-tests/vfs/_vfs.lua", "shared")
load("gace-tests/vfs/classes.lua", "shared")
load("gace-tests/vfs/root.lua", "shared")
