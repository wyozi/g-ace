G-Ace
=====

An in-game code editor for Garry's Mod.

![screenshot](http://i.imgur.com/g6PQeBk.png)

---

### Requirements

If you want access outside data/ folder: [G-Ace IO](https://github.com/wyozi/g-ace-io)

### Installation

Run ```git clone https://github.com/wyozi/g-ace.git``` in garrysmod/addons.

### Testing

Run ```gace-test``` in console to run the test suite.

### Setup

You can use "Create VFolder" button in GAce to create a temporary vfolder. Command is available to superadmins.

To create a simple over-map-changes persistent [gace-io](https://github.com/wyozi/g-ace-io) folder, run this code on server (eg ```lua/autorun/server```):

```lua
local f = gace.VFS.RealGIOFolder("folder", "./garrysmod/addons/gitaddon")
f:grantPermission("players", gace.VFS.ServerPermission)

gace.Root:addVirtualFolder(f)
```
