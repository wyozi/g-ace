G-Ace
=====

An in-game code editor for Garry's Mod.

![screenshot](http://i.imgur.com/g6PQeBk.png)

---

### Features
- [Ace](https://github.com/ajaxorg/ace) editor, which is used internally, supports syntax highlighting, auto completion, multiple cursors, themes, many language modes etc..
- First class Git support using [gm_git](https://github.com/wyozi/gm_git)
- Instant GLua documentation lookup using [glua-docs](https://github.com/samuelmaddock/glua-docs)
- Collaborative editing using [ot.js](https://github.com/Operational-Transformation/ot.js/) and [ot.lua](https://github.com/Operational-Transformation/ot.lua)
- IO outside the ```data/``` folder using [g-ace-io](https://github.com/wyozi/g-ace-io)

### Requirements

G-Ace works out of the box.

__Access outside ```data/``` folder__: [g-ace-io](https://github.com/wyozi/g-ace-io)  
__Git support__: [gm_git](https://github.com/wyozi/gm_git)  

The modules in releases might not be up to date enough to work with G-Ace.
In that case compile them yourself or bug me with an issue.

### Installation

Run ```git clone https://github.com/wyozi/g-ace.git``` in garrysmod/addons.

### Usage

```gace-open``` to open editor.  
```gace-reopen``` to re-open editor (use this if the HTML panel crashes or something like that).  

### Testing

Run ```gace-test``` in console to run the test suite.

### Setup

You can use "Create VFolder" button in G-Ace to create a temporary vfolder. Command is available to superadmins.

To create a simple over-map-changes persistent [gace-io](https://github.com/wyozi/g-ace-io) folder, run this code on server (eg ```lua/autorun/server```):

```lua
local f = gace.VFS.RealGIOFolder("folder", "./garrysmod/addons/gitaddon")
f:grantPermission("players", gace.VFS.ServerPermission)

gace.Root:addVirtualFolder(f)
```
