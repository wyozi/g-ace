G-Ace
=====

An in-game code editor for Garry's Mod.  

---

###Requirements

[LuaDev](http://facepunch.com/showthread.php?t=979552) ([svn](svn://anon:anon@svn.metastruct.org/srvaddons/luadev)) to run code.

[G-Ace IO](https://github.com/wyozi/g-ace-io) ([win](https://github.com/wyozi/g-ace-io/releases/download/0.02/gmsv_gaceio_win32.dll) | [linux](https://github.com/wyozi/g-ace-io/releases/download/0.02/gmsv_gaceio_linux.dll)) to access/handle files outside data folder.

[EPOE](http://facepunch.com/showthread.php?t=1145218) ([svn](svn://anon:anon@svn.metastruct.org/srvaddons/EPOE)) is **not** required, but is good to have as well.  

###Installation

Run ```git clone https://github.com/wyozi/g-ace.git``` in garrysmod/addons.

###Setup

G-Ace comes with a simple virtual filesystem. There are two ways to add folders to the filesystem; with console commands or [in code](https://github.com/wyozi/g-ace/blob/master/lua/autorun/server/fileaccess.lua). The following console commands are the quickest way to add a folder, but can only be run in server console or as RCON.

**g-ace-vfs-add [name] [type] [access] [root-path]**  
> Adds a permanent virtual folder.  
> Example command: g-ace-vfs-add ulxlogs gmodio admin ulx_logs/  

>**[name]** = Name of the virtual folder  
>**[type]** = Type of the virtual folder (available types: see [wiki](https://github.com/wyozi/g-ace/wiki/Virtual-folder-types))  
>**[access]** = Who should have access to this vfolder ("superadmin", "admin", "all")  
>**[root-path]** = The root path of the vfolder relative to the type's root path


**g-ace-vfs-add-temp [name] [type] [access] [root-path]**
> Adds a temporary virtual folder (will be deleted on map change or restart).  
> Example command: g-ace-vfs-add-temp ulxlogs gmodio admin ulx_logs/  

>**[name]** = Name of the virtual folder  
>**[type]** = Type of the virtual folder (available types: see [wiki](https://github.com/wyozi/g-ace/wiki/Virtual-folder-types))  
>**[access]** = Who should have access to this vfolder ("superadmin", "admin", "all")  
>**[root-path]** = The root path of the vfolder relative to the type's root path

**g-ace-vfs-del [name]**
> Deletes a virtual folder.  
> Example command: g-ace-vfs-del ulxlogs  

>**[name]** = Name of the virtual folder  
