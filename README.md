G-Ace
=====

An in-game code editor for Garry's Mod.  

---

###Requirements

If you want access outside data/ folder: [G-Ace IO](https://github.com/wyozi/g-ace-io)

###Installation

Run ```git clone https://github.com/wyozi/g-ace.git``` in garrysmod/addons.

###Setup

Currently there is no way to create a virtual folder without writing some code.
A simple [gace-io](https://github.com/wyozi/g-ace-io) folder can be created like this:

```lua
local f = gace.VFS.RealGIOFolder("folder", "./garrysmod/addons/gitaddon")
f:grantPermission("players", gace.VFS.ServerPermission)

gace.Root:addVirtualFolder(f)
```
