define("ace/mode/lua_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text_highlight_rules").TextHighlightRules,e=function(){var a="break|do|else|elseif|end|for|function|if|in|local|repeat|return|then|until|while|or|and|not",b="true|false|nil|_G|_VERSION",c="string|xpcall|package|tostring|print|os|unpack|require|getfenv|setmetatable|next|assert|tonumber|io|rawequal|collectgarbage|getmetatable|module|rawset|math|debug|pcall|table|newproxy|type|coroutine|_G|select|gcinfo|pairs|rawget|loadstring|ipairs|_VERSION|dofile|setfenv|load|error|loadfile|sub|upper|len|gfind|rep|find|match|char|dump|gmatch|reverse|byte|format|gsub|lower|preload|loadlib|loaded|loaders|cpath|config|path|seeall|exit|setlocale|date|getenv|difftime|remove|time|clock|tmpname|rename|execute|lines|write|close|flush|open|output|type|read|stderr|stdin|input|stdout|popen|tmpfile|log|max|acos|huge|ldexp|pi|cos|tanh|pow|deg|tan|cosh|sinh|random|randomseed|frexp|ceil|floor|rad|abs|sqrt|modf|asin|min|mod|fmod|log10|atan2|exp|sin|atan|getupvalue|debug|sethook|getmetatable|gethook|setmetatable|setlocal|traceback|setfenv|getinfo|setupvalue|getlocal|getregistry|getfenv|setn|insert|getn|foreachi|maxn|foreach|concat|sort|remove|resume|yield|status|wrap|create|running|__add|__sub|__mod|__unm|__concat|__lt|__index|__call|__gc|__metatable|__mul|__div|__pow|__len|__eq|__le|__newindex|__tostring|__mode|__tonumber",d="string|package|os|io|math|debug|table|coroutine",e="",f="setn|foreach|foreachi|gcinfo|log10|maxn",g=this.createKeywordMapper({keyword:a,"support.function":c,"invalid.deprecated":f,"constant.library":d,"constant.language":b,"invalid.illegal":e,"variable.language":"self"},"identifier"),h="(?:(?:[1-9]\\d*)|(?:0))",i="(?:0[xX][\\dA-Fa-f]+)",j="(?:"+h+"|"+i+")",k="(?:\\.\\d+)",l="(?:\\d+)",m="(?:(?:"+l+"?"+k+")|(?:"+l+"\\.))",n="(?:"+m+")";this.$rules={start:[{stateName:"bracketedComment",onMatch:function(a,b,c){return c.unshift(this.next,a.length-2,b),"comment"},regex:/\-\-\[=*\[/,next:[{onMatch:function(a,b,c){return a.length==c[1]?(c.shift(),c.shift(),this.next=c.shift()):this.next="","comment"},regex:/\]=*\]/,next:"start"},{defaultToken:"comment"}]},{token:"comment",regex:"\\-\\-.*$"},{stateName:"bracketedString",onMatch:function(a,b,c){return c.unshift(this.next,a.length,b),"string"},regex:/\[=*\[/,next:[{onMatch:function(a,b,c){return a.length==c[1]?(c.shift(),c.shift(),this.next=c.shift()):this.next="","string"},regex:/\]=*\]/,next:"start"},{defaultToken:"string"}]},{token:"string",regex:'"(?:[^\\\\]|\\\\.)*?"'},{token:"string",regex:"'(?:[^\\\\]|\\\\.)*?'"},{token:"constant.numeric",regex:n},{token:"constant.numeric",regex:j+"\\b"},{token:g,regex:"[a-zA-Z_$][a-zA-Z0-9_$]*\\b"},{token:"keyword.operator",regex:"\\+|\\-|\\*|\\/|%|\\#|\\^|~|<|>|<=|=>|==|~=|=|\\:|\\.\\.\\.|\\.\\."},{token:"paren.lparen",regex:"[\\[\\(\\{]"},{token:"paren.rparen",regex:"[\\]\\)\\}]"},{token:"text",regex:"\\s+|\\w+"}]},this.normalizeRules()};c.inherits(e,d),b.LuaHighlightRules=e}),define("ace/mode/folding/lua",["require","exports","module","ace/lib/oop","ace/mode/folding/fold_mode","ace/range","ace/token_iterator"],function(a,b){"use strict";var c=a("../../lib/oop"),d=a("./fold_mode").FoldMode,e=a("../../range").Range,f=a("../../token_iterator").TokenIterator,g=b.FoldMode=function(){};c.inherits(g,d),function(){this.foldingStartMarker=/\b(function|then|do|repeat)\b|{\s*$|(\[=*\[)/,this.foldingStopMarker=/\bend\b|^\s*}|\]=*\]/,this.getFoldWidget=function(a,b,c){var d=a.getLine(c),e=this.foldingStartMarker.test(d),f=this.foldingStopMarker.test(d);if(e&&!f){var g=d.match(this.foldingStartMarker);if("then"==g[1]&&/\belseif\b/.test(d))return;if(g[1]){if("keyword"===a.getTokenAt(c,g.index+1).type)return"start"}else{if(!g[2])return"start";var h=a.bgTokenizer.getState(c)||"";if("bracketedComment"==h[0]||"bracketedString"==h[0])return"start"}}if("markbeginend"!=b||!f||e&&f)return"";var g=d.match(this.foldingStopMarker);if("end"===g[0]){if("keyword"===a.getTokenAt(c,g.index+1).type)return"end"}else{if("]"!==g[0][0])return"end";var h=a.bgTokenizer.getState(c-1)||"";if("bracketedComment"==h[0]||"bracketedString"==h[0])return"end"}},this.getFoldWidgetRange=function(a,b,c){var d=a.doc.getLine(c),e=this.foldingStartMarker.exec(d);if(e)return e[1]?this.luaBlock(a,c,e.index+1):e[2]?a.getCommentFoldRange(c,e.index+1):this.openingBracketBlock(a,"{",c,e.index);var e=this.foldingStopMarker.exec(d);return e?"end"===e[0]&&"keyword"===a.getTokenAt(c,e.index+1).type?this.luaBlock(a,c,e.index+1):"]"===e[0][0]?a.getCommentFoldRange(c,e.index+1):this.closingBracketBlock(a,"}",c,e.index+e[0].length):void 0},this.luaBlock=function(a,b,c){var d=new f(a,b,c),g={"function":1,"do":1,then:1,elseif:-1,end:-1,repeat:1,until:-1},h=d.getCurrentToken();if(h&&"keyword"==h.type){var i=h.value,j=[i],k=g[i];if(k){var l=-1===k?d.getCurrentTokenColumn():a.getLine(b).length,m=b;for(d.step=-1===k?d.stepBackward:d.stepForward;h=d.step();)if("keyword"===h.type){var n=k*g[h.value];if(n>0)j.unshift(h.value);else if(0>=n){if(j.shift(),!j.length&&"elseif"!=h.value)break;0===n&&j.unshift(h.value)}}var b=d.getCurrentTokenRow();return-1===k?new e(b,a.getLine(b).length,m,l):new e(m,l,b,d.getCurrentTokenColumn())}}}}.call(g.prototype)}),define("ace/mode/behaviour/cstyle",["require","exports","module","ace/lib/oop","ace/mode/behaviour","ace/token_iterator","ace/lib/lang"],function(a,b){"use strict";var c,d=a("../../lib/oop"),e=a("../behaviour").Behaviour,f=a("../../token_iterator").TokenIterator,g=a("../../lib/lang"),h=["text","paren.rparen","punctuation.operator"],i=["text","paren.rparen","punctuation.operator","comment"],j={},k=function(a){var b=-1;return a.multiSelect&&(b=a.selection.index,j.rangeCount!=a.multiSelect.rangeCount&&(j={rangeCount:a.multiSelect.rangeCount})),j[b]?c=j[b]:void(c=j[b]={autoInsertedBrackets:0,autoInsertedRow:-1,autoInsertedLineEnd:"",maybeInsertedBrackets:0,maybeInsertedRow:-1,maybeInsertedLineStart:"",maybeInsertedLineEnd:""})},l=function(a,b,c,d){var e=a.end.row-a.start.row;return{text:c+b+d,selection:[0,a.start.column+1,e,a.end.column+(e?0:1)]}},m=function(){this.add("braces","insertion",function(a,b,d,e,f){var h=d.getCursorPosition(),i=e.doc.getLine(h.row);if("{"==f){k(d);var j=d.getSelectionRange(),n=e.doc.getTextRange(j);if(""!==n&&"{"!==n&&d.getWrapBehavioursEnabled())return l(j,n,"{","}");if(m.isSaneInsertion(d,e))return m.recordAutoInsert(d,e,"}"),{text:"{}",selection:[1,1]}}else if("}"==f){k(d);var o=i.substring(h.column,h.column+1);if("}"==o){var p=e.$findOpeningBracket("}",{column:h.column+1,row:h.row});if(null!==p&&m.isAutoInsertedClosing(h,i,f))return m.popAutoInsertedClosing(),{text:"",selection:[1,1]}}}else{if("\n"==f||"\r\n"==f){k(d);var q="";m.isMaybeInsertedClosing(h,i)&&(q=g.stringRepeat("}",c.maybeInsertedBrackets),m.clearMaybeInsertedClosing());var o=i.substring(h.column,h.column+1);if("}"===o){var r=e.findMatchingBracket({row:h.row,column:h.column+1},"}");if(!r)return null;var s=this.$getIndent(e.getLine(r.row))}else{if(!q)return void m.clearMaybeInsertedClosing();var s=this.$getIndent(i)}var t=s+e.getTabString();return{text:"\n"+t+"\n"+s+q,selection:[1,t.length,1,t.length]}}m.clearMaybeInsertedClosing()}}),this.add("braces","deletion",function(a,b,d,e,f){var g=e.doc.getTextRange(f);if(!f.isMultiLine()&&"{"==g){k(d);var h=e.doc.getLine(f.start.row),i=h.substring(f.end.column,f.end.column+1);if("}"==i)return f.end.column++,f;c.maybeInsertedBrackets--}}),this.add("parens","insertion",function(a,b,c,d,e){if("("==e){k(c);var f=c.getSelectionRange(),g=d.doc.getTextRange(f);if(""!==g&&c.getWrapBehavioursEnabled())return l(f,g,"(",")");if(m.isSaneInsertion(c,d))return m.recordAutoInsert(c,d,")"),{text:"()",selection:[1,1]}}else if(")"==e){k(c);var h=c.getCursorPosition(),i=d.doc.getLine(h.row),j=i.substring(h.column,h.column+1);if(")"==j){var n=d.$findOpeningBracket(")",{column:h.column+1,row:h.row});if(null!==n&&m.isAutoInsertedClosing(h,i,e))return m.popAutoInsertedClosing(),{text:"",selection:[1,1]}}}}),this.add("parens","deletion",function(a,b,c,d,e){var f=d.doc.getTextRange(e);if(!e.isMultiLine()&&"("==f){k(c);var g=d.doc.getLine(e.start.row),h=g.substring(e.start.column+1,e.start.column+2);if(")"==h)return e.end.column++,e}}),this.add("brackets","insertion",function(a,b,c,d,e){if("["==e){k(c);var f=c.getSelectionRange(),g=d.doc.getTextRange(f);if(""!==g&&c.getWrapBehavioursEnabled())return l(f,g,"[","]");if(m.isSaneInsertion(c,d))return m.recordAutoInsert(c,d,"]"),{text:"[]",selection:[1,1]}}else if("]"==e){k(c);var h=c.getCursorPosition(),i=d.doc.getLine(h.row),j=i.substring(h.column,h.column+1);if("]"==j){var n=d.$findOpeningBracket("]",{column:h.column+1,row:h.row});if(null!==n&&m.isAutoInsertedClosing(h,i,e))return m.popAutoInsertedClosing(),{text:"",selection:[1,1]}}}}),this.add("brackets","deletion",function(a,b,c,d,e){var f=d.doc.getTextRange(e);if(!e.isMultiLine()&&"["==f){k(c);var g=d.doc.getLine(e.start.row),h=g.substring(e.start.column+1,e.start.column+2);if("]"==h)return e.end.column++,e}}),this.add("string_dquotes","insertion",function(a,b,c,d,e){if('"'==e||"'"==e){k(c);var f=e,g=c.getSelectionRange(),h=d.doc.getTextRange(g);if(""!==h&&"'"!==h&&'"'!=h&&c.getWrapBehavioursEnabled())return l(g,h,f,f);if(!h){var i=c.getCursorPosition(),j=d.doc.getLine(i.row),m=j.substring(i.column-1,i.column),n=j.substring(i.column,i.column+1),o=d.getTokenAt(i.row,i.column),p=d.getTokenAt(i.row,i.column+1);if("\\"==m&&o&&/escape/.test(o.type))return null;var q,r=o&&/string/.test(o.type),s=!p||/string/.test(p.type);if(n==f)q=r!==s;else{if(r&&!s)return null;if(r&&s)return null;var t=d.$mode.tokenRe;t.lastIndex=0;var u=t.test(m);t.lastIndex=0;var v=t.test(m);if(u||v)return null;if(n&&!/[\s;,.})\]\\]/.test(n))return null;q=!0}return{text:q?f+f:"",selection:[1,1]}}}}),this.add("string_dquotes","deletion",function(a,b,c,d,e){var f=d.doc.getTextRange(e);if(!e.isMultiLine()&&('"'==f||"'"==f)){k(c);var g=d.doc.getLine(e.start.row),h=g.substring(e.start.column+1,e.start.column+2);if(h==f)return e.end.column++,e}})};m.isSaneInsertion=function(a,b){var c=a.getCursorPosition(),d=new f(b,c.row,c.column);if(!this.$matchTokenType(d.getCurrentToken()||"text",h)){var e=new f(b,c.row,c.column+1);if(!this.$matchTokenType(e.getCurrentToken()||"text",h))return!1}return d.stepForward(),d.getCurrentTokenRow()!==c.row||this.$matchTokenType(d.getCurrentToken()||"text",i)},m.$matchTokenType=function(a,b){return b.indexOf(a.type||a)>-1},m.recordAutoInsert=function(a,b,d){var e=a.getCursorPosition(),f=b.doc.getLine(e.row);this.isAutoInsertedClosing(e,f,c.autoInsertedLineEnd[0])||(c.autoInsertedBrackets=0),c.autoInsertedRow=e.row,c.autoInsertedLineEnd=d+f.substr(e.column),c.autoInsertedBrackets++},m.recordMaybeInsert=function(a,b,d){var e=a.getCursorPosition(),f=b.doc.getLine(e.row);this.isMaybeInsertedClosing(e,f)||(c.maybeInsertedBrackets=0),c.maybeInsertedRow=e.row,c.maybeInsertedLineStart=f.substr(0,e.column)+d,c.maybeInsertedLineEnd=f.substr(e.column),c.maybeInsertedBrackets++},m.isAutoInsertedClosing=function(a,b,d){return c.autoInsertedBrackets>0&&a.row===c.autoInsertedRow&&d===c.autoInsertedLineEnd[0]&&b.substr(a.column)===c.autoInsertedLineEnd},m.isMaybeInsertedClosing=function(a,b){return c.maybeInsertedBrackets>0&&a.row===c.maybeInsertedRow&&b.substr(a.column)===c.maybeInsertedLineEnd&&b.substr(0,a.column)==c.maybeInsertedLineStart},m.popAutoInsertedClosing=function(){c.autoInsertedLineEnd=c.autoInsertedLineEnd.substr(1),c.autoInsertedBrackets--},m.clearMaybeInsertedClosing=function(){c&&(c.maybeInsertedBrackets=0,c.maybeInsertedRow=-1)},d.inherits(m,e),b.CstyleBehaviour=m}),define("ace/mode/behaviour/lua",["require","exports","module","ace/lib/oop","ace/mode/behaviour","ace/mode/behaviour/cstyle","ace/token_iterator","ace/lib/lang"],function(a,b){"use strict";var c=a("../../lib/oop"),d=a("../behaviour").Behaviour,e=a("../../token_iterator").TokenIterator,f=(a("../../lib/lang"),a("./cstyle").CstyleBehaviour),g=function(){this.inherit(f,["braces","parens","string_dquotes"]),this.add("closekeyword","insertion",function(a,b,c,d,f){if("\n"==f){var g=c.getCursorPosition(),h=d.getLine(g.row),i=this.$getIndent(h),j=d.getLength()<=g.row-1?"":d.getLine(g.row+1),k=this.$getIndent(j);if(!(k>i)){var l=new e(d,g.row,g.column),m=l.getCurrentToken();if(m&&"keyword"==m.type&&("then"==m.value||"do"==m.value)){do m=l.stepBackward();while("keyword"!=m.type);if("elseif"==m.value||"else"==m.value)return;var n=i+d.getTabString();return{text:"\n"+n+"\n"+i+"end",selection:[1,n.length,1,n.length]}}}}}),this.add("closefunction","insertion",function(a,b,c,d,f){if("\n"==f){var g=c.getCursorPosition(),h=d.getLine(g.row),i=this.$getIndent(h),j=d.getLength()<=g.row-1?"":d.getLine(g.row+1),k=this.$getIndent(j);if(!(k>i)){var l=new e(d,g.row,g.column),m=l.getCurrentToken();if(m&&"paren.rparen"==m.type){for(;"paren.lparen"!=m.type;){if(m=l.stepBackward(),!m)return;if("keyword"==m.type)return}if(m=l.stepBackward()){for(;"text"==m.type&&(" "==m.value||"."==m.value)||"keyword.operator"==m.type||"identifier"==m.type;)if(m=l.stepBackward(),!m)return;if(m&&"keyword"==m.type&&"function"==m.value){var n=i+d.getTabString();return{text:"\n"+n+"\n"+i+"end",selection:[1,n.length,1,n.length]}}}}}}}),this.add("smartbackspace","deletion",function(a,b,c,d,e){var f=d.doc.getTextRange(e);if(!e.isMultiLine()&&/\s/.test(f)){var g=d.doc.getLine(e.start.row),h=g.substring(0,e.start.column+1);if(/^\s+$/.test(h)&&e.start.row>0)return e.start.row--,e.start.column=d.doc.getLine(e.start.row).length,e}})};c.inherits(g,d),b.LuaBehaviour=g}),define("ace/mode/lua",["require","exports","module","ace/lib/oop","ace/mode/text","ace/mode/lua_highlight_rules","ace/mode/folding/lua","ace/range","ace/worker/worker_client","ace/mode/behaviour/luastyle"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text").Mode,e=a("./lua_highlight_rules").LuaHighlightRules,f=a("./folding/lua").FoldMode,g=a("../range").Range,h=a("../worker/worker_client").WorkerClient,i=a("./behaviour/lua").LuaBehaviour,j=function(){this.HighlightRules=e,this.$behaviour=new i,this.foldingRules=new f};c.inherits(j,d),function(){function a(a){for(var c=0,d=0;d<a.length;d++){var e=a[d];"keyword"==e.type?e.value in b&&(c+=b[e.value]):"paren.lparen"==e.type?c+=e.value.length:"paren.rparen"==e.type&&(c-=e.value.length)}return 0>c?-1:c>0?1:0}this.lineCommentStart="--",this.blockComment={start:"--[",end:"]--"};var b={"function":1,then:1,"do":1,"else":1,elseif:1,repeat:1,end:-1,until:-1},c=["else","elseif","end","until"];this.getNextLineIndent=function(b,c,d){var e=this.$getIndent(c),f=0,g=this.getTokenizer().getLineTokens(c,b),h=g.tokens;return"start"==b&&(f=a(h)),f>0?e+d:0>f&&e.substr(e.length-d.length)==d&&!this.checkOutdent(b,c,"\n")?e.substr(0,e.length-d.length):e},this.checkOutdent=function(a,b,d){if("\n"!=d&&"\r"!=d&&"\r\n"!=d)return!1;if(b.match(/^\s*[\)\}\]]$/))return!0;var e=this.getTokenizer().getLineTokens(b.trim(),a).tokens;return e&&e.length?"keyword"==e[0].type&&-1!=c.indexOf(e[0].value):!1},this.autoOutdent=function(b,c,d){var e=c.getLine(d-1),f=this.$getIndent(e).length,h=this.getTokenizer().getLineTokens(e,"start").tokens,i=c.getTabString().length,j=f+i*a(h),k=this.$getIndent(c.getLine(d)).length;j>k||c.outdentRows(new g(d,0,d+2,0))},this.createWorker=function(a){var b=new h(["ace"],"ace/mode/lua_worker","Worker");return b.attachToDocument(a.getDocument()),b.on("error",function(b){a.setAnnotations([b.data])}),b.on("ok",function(){a.clearAnnotations()}),b},this.$id="ace/mode/lua"}.call(j.prototype),b.Mode=j});