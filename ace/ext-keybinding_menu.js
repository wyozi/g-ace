define("ace/ext/menu_tools/overlay_page",["require","exports","module","ace/lib/dom"],function(a,b,c){"use strict";var d=a("../../lib/dom"),e="#ace_settingsmenu, #kbshortcutmenu {background-color: #F7F7F7;color: black;box-shadow: -5px 4px 5px rgba(126, 126, 126, 0.55);padding: 1em 0.5em 2em 1em;overflow: auto;position: absolute;margin: 0;bottom: 0;right: 0;top: 0;z-index: 9991;cursor: default;}.ace_dark #ace_settingsmenu, .ace_dark #kbshortcutmenu {box-shadow: -20px 10px 25px rgba(126, 126, 126, 0.25);background-color: rgba(255, 255, 255, 0.6);color: black;}.ace_optionsMenuEntry:hover {background-color: rgba(100, 100, 100, 0.1);-webkit-transition: all 0.5s;transition: all 0.3s}.ace_closeButton {background: rgba(245, 146, 146, 0.5);border: 1px solid #F48A8A;border-radius: 50%;padding: 7px;position: absolute;right: -8px;top: -8px;z-index: 1000;}.ace_closeButton{background: rgba(245, 146, 146, 0.9);}.ace_optionsMenuKey {color: darkslateblue;font-weight: bold;}.ace_optionsMenuCommand {color: darkcyan;font-weight: normal;}";d.importCssString(e),c.exports.overlayPage=function(a,b,c,e,f,g){function h(a){27===a.keyCode&&i.click()}c=c?"top: "+c+";":"",f=f?"bottom: "+f+";":"",e=e?"right: "+e+";":"",g=g?"left: "+g+";":"";var i=document.createElement("div"),j=document.createElement("div");i.style.cssText="margin: 0; padding: 0; position: fixed; top:0; bottom:0; left:0; right:0;z-index: 9990; background-color: rgba(0, 0, 0, 0.3);",i.addEventListener("click",function(){document.removeEventListener("keydown",h),i.parentNode.removeChild(i),a.focus(),i=null}),document.addEventListener("keydown",h),j.style.cssText=c+e+f+g,j.addEventListener("click",function(a){a.stopPropagation()});var k=d.createElement("div");k.style.position="relative";var l=d.createElement("div");l.className="ace_closeButton",l.addEventListener("click",function(){i.click()}),k.appendChild(l),j.appendChild(k),j.appendChild(b),i.appendChild(j),document.body.appendChild(i),a.blur()}}),define("ace/ext/menu_tools/get_editor_keyboard_shortcuts",["require","exports","module","ace/lib/keys"],function(a,b,c){"use strict";var d=a("../../lib/keys");c.exports.getEditorKeybordShortcuts=function(a){var b=(d.KEY_MODS,[]),c={};return a.keyBinding.$handlers.forEach(function(a){var d=a.commandKeyBinding;for(var e in d){var f=e.replace(/(^|-)\w/g,function(a){return a.toUpperCase()}),g=d[e];Array.isArray(g)||(g=[g]),g.forEach(function(a){"string"!=typeof a&&(a=a.name),c[a]?c[a].key+="|"+f:(c[a]={key:f,command:a},b.push(c[a]))})}}),b}}),define("ace/ext/keybinding_menu",["require","exports","module","ace/editor","ace/ext/menu_tools/overlay_page","ace/ext/menu_tools/get_editor_keyboard_shortcuts"],function(a,b,c){"use strict";function d(b){if(!document.getElementById("kbshortcutmenu")){var c=a("./menu_tools/overlay_page").overlayPage,d=a("./menu_tools/get_editor_keyboard_shortcuts").getEditorKeybordShortcuts,e=d(b),f=document.createElement("div"),g=e.reduce(function(a,b){return a+'<div class="ace_optionsMenuEntry"><span class="ace_optionsMenuCommand">'+b.command+'</span> : <span class="ace_optionsMenuKey">'+b.key+"</span></div>"},"");f.id="kbshortcutmenu",f.innerHTML="<h1>Keyboard Shortcuts</h1>"+g+"</div>",c(b,f,"0","0","0",null)}}var e=a("ace/editor").Editor;c.exports.init=function(a){e.prototype.showKeyboardShortcuts=function(){d(this)},a.commands.addCommands([{name:"showKeyboardShortcuts",bindKey:{win:"Ctrl-Alt-h",mac:"Command-Alt-h"},exec:function(a){a.showKeyboardShortcuts()}}])}}),function(){window.require(["ace/ext/keybinding_menu"],function(){})}();