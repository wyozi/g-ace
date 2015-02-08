define("ace/mode/logiql_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text_highlight_rules").TextHighlightRules,e=function(){this.$rules={start:[{token:"comment.block",regex:"/\\*",push:[{token:"comment.block",regex:"\\*/",next:"pop"},{defaultToken:"comment.block"}]},{token:"comment.single",regex:"//.*"},{token:"constant.numeric",regex:"\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?[fd]?"},{token:"string",regex:'"',push:[{token:"string",regex:'"',next:"pop"},{defaultToken:"string"}]},{token:"constant.language",regex:"\\b(true|false)\\b"},{token:"entity.name.type.logicblox",regex:"`[a-zA-Z_:]+(\\d|\\a)*\\b"},{token:"keyword.start",regex:"->",comment:"Constraint"},{token:"keyword.start",regex:"-->",comment:"Level 1 Constraint"},{token:"keyword.start",regex:"<-",comment:"Rule"},{token:"keyword.start",regex:"<--",comment:"Level 1 Rule"},{token:"keyword.end",regex:"\\.",comment:"Terminator"},{token:"keyword.other",regex:"!",comment:"Negation"},{token:"keyword.other",regex:",",comment:"Conjunction"},{token:"keyword.other",regex:";",comment:"Disjunction"},{token:"keyword.operator",regex:"<=|>=|!=|<|>",comment:"Equality"},{token:"keyword.other",regex:"@",comment:"Equality"},{token:"keyword.operator",regex:"\\+|-|\\*|/",comment:"Arithmetic operations"},{token:"keyword",regex:"::",comment:"Colon colon"},{token:"support.function",regex:"\\b(agg\\s*<<)",push:[{include:"$self"},{token:"support.function",regex:">>",next:"pop"}]},{token:"storage.modifier",regex:"\\b(lang:[\\w:]*)"},{token:["storage.type","text"],regex:"(export|sealed|clauses|block|alias|alias_all)(\\s*\\()(?=`)"},{token:"entity.name",regex:"[a-zA-Z_][a-zA-Z_0-9:]*(@prev|@init|@final)?(?=(\\(|\\[))"},{token:"variable.parameter",regex:"([a-zA-Z][a-zA-Z_0-9]*|_)\\s*(?=(,|\\.|<-|->|\\)|\\]|=))"}]},this.normalizeRules()};c.inherits(e,d),b.LogiQLHighlightRules=e}),define("ace/mode/folding/coffee",["require","exports","module","ace/lib/oop","ace/mode/folding/fold_mode","ace/range"],function(a,b){"use strict";var c=a("../../lib/oop"),d=a("./fold_mode").FoldMode,e=a("../../range").Range,f=b.FoldMode=function(){};c.inherits(f,d),function(){this.getFoldWidgetRange=function(a,b,c){var d=this.indentationBlock(a,c);if(d)return d;var f=/\S/,g=a.getLine(c),h=g.search(f);if(-1!=h&&"#"==g[h]){for(var i=g.length,j=a.getLength(),k=c,l=c;++c<j;){g=a.getLine(c);var m=g.search(f);if(-1!=m){if("#"!=g[m])break;l=c}}if(l>k){var n=a.getLine(l).length;return new e(k,i,l,n)}}},this.getFoldWidget=function(a,b,c){var d=a.getLine(c),e=d.search(/\S/),f=a.getLine(c+1),g=a.getLine(c-1),h=g.search(/\S/),i=f.search(/\S/);if(-1==e)return a.foldWidgets[c-1]=-1!=h&&i>h?"start":"","";if(-1==h){if(e==i&&"#"==d[e]&&"#"==f[e])return a.foldWidgets[c-1]="",a.foldWidgets[c+1]="","start"}else if(h==e&&"#"==d[e]&&"#"==g[e]&&-1==a.getLine(c-2).search(/\S/))return a.foldWidgets[c-1]="start",a.foldWidgets[c+1]="","";return a.foldWidgets[c-1]=-1!=h&&e>h?"start":"",i>e?"start":""}}.call(f.prototype)}),define("ace/mode/behaviour/cstyle",["require","exports","module","ace/lib/oop","ace/mode/behaviour","ace/token_iterator","ace/lib/lang"],function(a,b){"use strict";var c,d=a("../../lib/oop"),e=a("../behaviour").Behaviour,f=a("../../token_iterator").TokenIterator,g=a("../../lib/lang"),h=["text","paren.rparen","punctuation.operator"],i=["text","paren.rparen","punctuation.operator","comment"],j={},k=function(a){var b=-1;return a.multiSelect&&(b=a.selection.index,j.rangeCount!=a.multiSelect.rangeCount&&(j={rangeCount:a.multiSelect.rangeCount})),j[b]?c=j[b]:void(c=j[b]={autoInsertedBrackets:0,autoInsertedRow:-1,autoInsertedLineEnd:"",maybeInsertedBrackets:0,maybeInsertedRow:-1,maybeInsertedLineStart:"",maybeInsertedLineEnd:""})},l=function(){this.add("braces","insertion",function(a,b,d,e,f){var h=d.getCursorPosition(),i=e.doc.getLine(h.row);if("{"==f){k(d);var j=d.getSelectionRange(),m=e.doc.getTextRange(j);if(""!==m&&"{"!==m&&d.getWrapBehavioursEnabled())return{text:"{"+m+"}",selection:!1};if(l.isSaneInsertion(d,e))return/[\]\}\)]/.test(i[h.column])||d.inMultiSelectMode?(l.recordAutoInsert(d,e,"}"),{text:"{}",selection:[1,1]}):(l.recordMaybeInsert(d,e,"{"),{text:"{",selection:[1,1]})}else if("}"==f){k(d);var n=i.substring(h.column,h.column+1);if("}"==n){var o=e.$findOpeningBracket("}",{column:h.column+1,row:h.row});if(null!==o&&l.isAutoInsertedClosing(h,i,f))return l.popAutoInsertedClosing(),{text:"",selection:[1,1]}}}else{if("\n"==f||"\r\n"==f){k(d);var p="";l.isMaybeInsertedClosing(h,i)&&(p=g.stringRepeat("}",c.maybeInsertedBrackets),l.clearMaybeInsertedClosing());var n=i.substring(h.column,h.column+1);if("}"===n){var q=e.findMatchingBracket({row:h.row,column:h.column+1},"}");if(!q)return null;var r=this.$getIndent(e.getLine(q.row))}else{if(!p)return void l.clearMaybeInsertedClosing();var r=this.$getIndent(i)}var s=r+e.getTabString();return{text:"\n"+s+"\n"+r+p,selection:[1,s.length,1,s.length]}}l.clearMaybeInsertedClosing()}}),this.add("braces","deletion",function(a,b,d,e,f){var g=e.doc.getTextRange(f);if(!f.isMultiLine()&&"{"==g){k(d);var h=e.doc.getLine(f.start.row),i=h.substring(f.end.column,f.end.column+1);if("}"==i)return f.end.column++,f;c.maybeInsertedBrackets--}}),this.add("parens","insertion",function(a,b,c,d,e){if("("==e){k(c);var f=c.getSelectionRange(),g=d.doc.getTextRange(f);if(""!==g&&c.getWrapBehavioursEnabled())return{text:"("+g+")",selection:!1};if(l.isSaneInsertion(c,d))return l.recordAutoInsert(c,d,")"),{text:"()",selection:[1,1]}}else if(")"==e){k(c);var h=c.getCursorPosition(),i=d.doc.getLine(h.row),j=i.substring(h.column,h.column+1);if(")"==j){var m=d.$findOpeningBracket(")",{column:h.column+1,row:h.row});if(null!==m&&l.isAutoInsertedClosing(h,i,e))return l.popAutoInsertedClosing(),{text:"",selection:[1,1]}}}}),this.add("parens","deletion",function(a,b,c,d,e){var f=d.doc.getTextRange(e);if(!e.isMultiLine()&&"("==f){k(c);var g=d.doc.getLine(e.start.row),h=g.substring(e.start.column+1,e.start.column+2);if(")"==h)return e.end.column++,e}}),this.add("brackets","insertion",function(a,b,c,d,e){if("["==e){k(c);var f=c.getSelectionRange(),g=d.doc.getTextRange(f);if(""!==g&&c.getWrapBehavioursEnabled())return{text:"["+g+"]",selection:!1};if(l.isSaneInsertion(c,d))return l.recordAutoInsert(c,d,"]"),{text:"[]",selection:[1,1]}}else if("]"==e){k(c);var h=c.getCursorPosition(),i=d.doc.getLine(h.row),j=i.substring(h.column,h.column+1);if("]"==j){var m=d.$findOpeningBracket("]",{column:h.column+1,row:h.row});if(null!==m&&l.isAutoInsertedClosing(h,i,e))return l.popAutoInsertedClosing(),{text:"",selection:[1,1]}}}}),this.add("brackets","deletion",function(a,b,c,d,e){var f=d.doc.getTextRange(e);if(!e.isMultiLine()&&"["==f){k(c);var g=d.doc.getLine(e.start.row),h=g.substring(e.start.column+1,e.start.column+2);if("]"==h)return e.end.column++,e}}),this.add("string_dquotes","insertion",function(a,b,c,d,e){if('"'==e||"'"==e){k(c);var f=e,g=c.getSelectionRange(),h=d.doc.getTextRange(g);if(""!==h&&"'"!==h&&'"'!=h&&c.getWrapBehavioursEnabled())return{text:f+h+f,selection:!1};var i=c.getCursorPosition(),j=d.doc.getLine(i.row),l=j.substring(i.column-1,i.column),m=j.substring(i.column,i.column+1),n=d.getTokenAt(i.row,i.column),o=d.getTokenAt(i.row,i.column+1);if("\\"==l&&n&&/escape/.test(n.type))return null;var p,q=n&&/string/.test(n.type),r=!o||/string/.test(o.type);if(m==f)p=q!==r;else{if(q&&!r)return null;if(q&&r)return null;var s=d.$mode.tokenRe;s.lastIndex=0;var t=s.test(l);s.lastIndex=0;var u=s.test(l);if(t||u)return null;if(m&&!/[\s;,.})\]\\]/.test(m))return null;p=!0}return{text:p?f+f:"",selection:[1,1]}}}),this.add("string_dquotes","deletion",function(a,b,c,d,e){var f=d.doc.getTextRange(e);if(!e.isMultiLine()&&('"'==f||"'"==f)){k(c);var g=d.doc.getLine(e.start.row),h=g.substring(e.start.column+1,e.start.column+2);if(h==f)return e.end.column++,e}})};l.isSaneInsertion=function(a,b){var c=a.getCursorPosition(),d=new f(b,c.row,c.column);if(!this.$matchTokenType(d.getCurrentToken()||"text",h)){var e=new f(b,c.row,c.column+1);if(!this.$matchTokenType(e.getCurrentToken()||"text",h))return!1}return d.stepForward(),d.getCurrentTokenRow()!==c.row||this.$matchTokenType(d.getCurrentToken()||"text",i)},l.$matchTokenType=function(a,b){return b.indexOf(a.type||a)>-1},l.recordAutoInsert=function(a,b,d){var e=a.getCursorPosition(),f=b.doc.getLine(e.row);this.isAutoInsertedClosing(e,f,c.autoInsertedLineEnd[0])||(c.autoInsertedBrackets=0),c.autoInsertedRow=e.row,c.autoInsertedLineEnd=d+f.substr(e.column),c.autoInsertedBrackets++},l.recordMaybeInsert=function(a,b,d){var e=a.getCursorPosition(),f=b.doc.getLine(e.row);this.isMaybeInsertedClosing(e,f)||(c.maybeInsertedBrackets=0),c.maybeInsertedRow=e.row,c.maybeInsertedLineStart=f.substr(0,e.column)+d,c.maybeInsertedLineEnd=f.substr(e.column),c.maybeInsertedBrackets++},l.isAutoInsertedClosing=function(a,b,d){return c.autoInsertedBrackets>0&&a.row===c.autoInsertedRow&&d===c.autoInsertedLineEnd[0]&&b.substr(a.column)===c.autoInsertedLineEnd},l.isMaybeInsertedClosing=function(a,b){return c.maybeInsertedBrackets>0&&a.row===c.maybeInsertedRow&&b.substr(a.column)===c.maybeInsertedLineEnd&&b.substr(0,a.column)==c.maybeInsertedLineStart},l.popAutoInsertedClosing=function(){c.autoInsertedLineEnd=c.autoInsertedLineEnd.substr(1),c.autoInsertedBrackets--},l.clearMaybeInsertedClosing=function(){c&&(c.maybeInsertedBrackets=0,c.maybeInsertedRow=-1)},d.inherits(l,e),b.CstyleBehaviour=l}),define("ace/mode/matching_brace_outdent",["require","exports","module","ace/range"],function(a,b){"use strict";var c=a("../range").Range,d=function(){};(function(){this.checkOutdent=function(a,b){return/^\s+$/.test(a)?/^\s*\}/.test(b):!1},this.autoOutdent=function(a,b){var d=a.getLine(b),e=d.match(/^(\s*\})/);if(!e)return 0;var f=e[1].length,g=a.findMatchingBracket({row:b,column:f});if(!g||g.row==b)return 0;var h=this.$getIndent(a.getLine(g.row));a.replace(new c(b,0,b,f-1),h)},this.$getIndent=function(a){return a.match(/^\s*/)[0]}}).call(d.prototype),b.MatchingBraceOutdent=d}),define("ace/mode/logiql",["require","exports","module","ace/lib/oop","ace/mode/text","ace/mode/logiql_highlight_rules","ace/mode/folding/coffee","ace/token_iterator","ace/range","ace/mode/behaviour/cstyle","ace/mode/matching_brace_outdent"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text").Mode,e=a("./logiql_highlight_rules").LogiQLHighlightRules,f=a("./folding/coffee").FoldMode,g=a("../token_iterator").TokenIterator,h=a("../range").Range,i=a("./behaviour/cstyle").CstyleBehaviour,j=a("./matching_brace_outdent").MatchingBraceOutdent,k=function(){this.HighlightRules=e,this.foldingRules=new f,this.$outdent=new j,this.$behaviour=new i};c.inherits(k,d),function(){this.lineCommentStart="//",this.blockComment={start:"/*",end:"*/"},this.getNextLineIndent=function(a,b,c){var d=this.$getIndent(b),e=this.getTokenizer().getLineTokens(b,a),f=e.tokens,g=e.state;if(/comment|string/.test(g))return d;if(f.length&&"comment.single"==f[f.length-1].type)return d;b.match();return/(-->|<--|<-|->|{)\s*$/.test(b)&&(d+=c),d},this.checkOutdent=function(a,b,c){return this.$outdent.checkOutdent(b,c)?!0:"\n"!==c&&"\r\n"!==c?!1:/^\s+/.test(b)?!0:!1},this.autoOutdent=function(a,b,c){if(!this.$outdent.autoOutdent(b,c)){var d=b.getLine(c),e=d.match(/^\s+/),f=d.lastIndexOf(".")+1;if(!e||!c||!f)return 0;var g=(b.getLine(c+1),this.getMatching(b,{row:c,column:f}));if(!g||g.start.row==c)return 0;f=e[0].length;var i=this.$getIndent(b.getLine(g.start.row));b.replace(new h(c+1,0,c+1,f),i)}},this.getMatching=function(a,b,c){void 0==b&&(b=a.selection.lead),"object"==typeof b&&(c=b.column,b=b.row);var d,e=a.getTokenAt(b,c),f="keyword.start",i="keyword.end";if(e){if(e.type==f){var j=new g(a,b,c);j.step=j.stepForward}else{if(e.type!=i)return;var j=new g(a,b,c);j.step=j.stepBackward}for(;(d=j.step())&&d.type!=f&&d.type!=i;);if(d&&d.type!=e.type){var k=j.getCurrentTokenColumn(),b=j.getCurrentTokenRow();return new h(b,k,b,k+d.value.length)}}},this.$id="ace/mode/logiql"}.call(k.prototype),b.Mode=k});