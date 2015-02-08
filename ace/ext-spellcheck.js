define("ace/ext/spellcheck",["require","exports","module","ace/lib/event","ace/editor","ace/config"],function(a,b){"use strict";var c=a("../lib/event");b.contextMenuHandler=function(a){var b=a.target,d=b.textInput.getElement();if(b.selection.isEmpty()){var e=b.getCursorPosition(),f=b.session.getWordRange(e.row,e.column),g=b.session.getTextRange(f);if(b.session.tokenRe.lastIndex=0,b.session.tokenRe.test(g)){var h="",i=g+" "+h;d.value=i,d.setSelectionRange(g.length,g.length+1),d.setSelectionRange(0,0),d.setSelectionRange(0,g.length);var j=!1;c.addListener(d,"keydown",function k(){c.removeListener(d,"keydown",k),j=!0}),b.textInput.setInputHandler(function(a){if(console.log(a,i,d.selectionStart,d.selectionEnd),a==i)return"";if(0===a.lastIndexOf(i,0))return a.slice(i.length);if(a.substr(d.selectionEnd)==i)return a.slice(0,-i.length);if(a.slice(-2)==h){var c=a.slice(0,-2);if(" "==c.slice(-1))return j?c.substring(0,d.selectionEnd):(c=c.slice(0,-1),b.session.replace(f,c),"")}return a})}}};var d=a("../editor").Editor;a("../config").defineOptions(d.prototype,"editor",{spellcheck:{set:function(a){var c=this.textInput.getElement();c.spellcheck=!!a,a?this.on("nativecontextmenu",b.contextMenuHandler):this.removeListener("nativecontextmenu",b.contextMenuHandler)},value:!0}})}),function(){window.require(["ace/ext/spellcheck"],function(){})}();