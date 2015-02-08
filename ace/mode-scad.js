define("ace/mode/doc_comment_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text_highlight_rules").TextHighlightRules,e=function(){this.$rules={start:[{token:"comment.doc.tag",regex:"@[\\w\\d_]+"},e.getTagRule(),{defaultToken:"comment.doc",caseInsensitive:!0}]}};c.inherits(e,d),e.getTagRule=function(){return{token:"comment.doc.tag.storage.type",regex:"\\b(?:TODO|FIXME|XXX|HACK)\\b"}},e.getStartRule=function(a){return{token:"comment.doc",regex:"\\/\\*(?=\\*)",next:a}},e.getEndRule=function(a){return{token:"comment.doc",regex:"\\*\\/",next:a}},b.DocCommentHighlightRules=e}),define("ace/mode/scad_highlight_rules",["require","exports","module","ace/lib/oop","ace/lib/lang","ace/mode/doc_comment_highlight_rules","ace/mode/text_highlight_rules"],function(a,b){"use strict";var c=a("../lib/oop"),d=(a("../lib/lang"),a("./doc_comment_highlight_rules").DocCommentHighlightRules),e=a("./text_highlight_rules").TextHighlightRules,f=function(){var a=this.createKeywordMapper({"variable.language":"this",keyword:"module|if|else|for","constant.language":"NULL"},"identifier");this.$rules={start:[{token:"comment",regex:"\\/\\/.*$"},d.getStartRule("start"),{token:"comment",regex:"\\/\\*",next:"comment"},{token:"string",regex:'["](?:(?:\\\\.)|(?:[^"\\\\]))*?["]'},{token:"string",regex:'["].*\\\\$',next:"qqstring"},{token:"string",regex:"['](?:(?:\\\\.)|(?:[^'\\\\]))*?[']"},{token:"string",regex:"['].*\\\\$",next:"qstring"},{token:"constant.numeric",regex:"0[xX][0-9a-fA-F]+\\b"},{token:"constant.numeric",regex:"[+-]?\\d+(?:(?:\\.\\d*)?(?:[eE][+-]?\\d+)?)?\\b"},{token:"constant",regex:"<[a-zA-Z0-9.]+>"},{token:"keyword",regex:"(?:use|include)"},{token:a,regex:"[a-zA-Z_$][a-zA-Z0-9_$]*\\b"},{token:"keyword.operator",regex:"!|\\$|%|&|\\*|\\-\\-|\\-|\\+\\+|\\+|~|==|=|!=|<=|>=|<<=|>>=|>>>=|<>|<|>|!|&&|\\|\\||\\?\\:|\\*=|%=|\\+=|\\-=|&=|\\^=|\\b(?:in|new|delete|typeof|void)"},{token:"paren.lparen",regex:"[[({]"},{token:"paren.rparen",regex:"[\\])}]"},{token:"text",regex:"\\s+"}],comment:[{token:"comment",regex:".*?\\*\\/",next:"start"},{token:"comment",regex:".+"}],qqstring:[{token:"string",regex:'(?:(?:\\\\.)|(?:[^"\\\\]))*?"',next:"start"},{token:"string",regex:".+"}],qstring:[{token:"string",regex:"(?:(?:\\\\.)|(?:[^'\\\\]))*?'",next:"start"},{token:"string",regex:".+"}]},this.embedRules(d,"doc-",[d.getEndRule("start")])};c.inherits(f,e),b.scadHighlightRules=f}),define("ace/mode/matching_brace_outdent",["require","exports","module","ace/range"],function(a,b){"use strict";var c=a("../range").Range,d=function(){};(function(){this.checkOutdent=function(a,b){return/^\s+$/.test(a)?/^\s*\}/.test(b):!1},this.autoOutdent=function(a,b){var d=a.getLine(b),e=d.match(/^(\s*\})/);if(!e)return 0;var f=e[1].length,g=a.findMatchingBracket({row:b,column:f});if(!g||g.row==b)return 0;var h=this.$getIndent(a.getLine(g.row));a.replace(new c(b,0,b,f-1),h)},this.$getIndent=function(a){return a.match(/^\s*/)[0]}}).call(d.prototype),b.MatchingBraceOutdent=d}),define("ace/mode/behaviour/cstyle",["require","exports","module","ace/lib/oop","ace/mode/behaviour","ace/token_iterator","ace/lib/lang"],function(a,b){"use strict";var c,d=a("../../lib/oop"),e=a("../behaviour").Behaviour,f=a("../../token_iterator").TokenIterator,g=a("../../lib/lang"),h=["text","paren.rparen","punctuation.operator"],i=["text","paren.rparen","punctuation.operator","comment"],j={},k=function(a){var b=-1;return a.multiSelect&&(b=a.selection.index,j.rangeCount!=a.multiSelect.rangeCount&&(j={rangeCount:a.multiSelect.rangeCount})),j[b]?c=j[b]:void(c=j[b]={autoInsertedBrackets:0,autoInsertedRow:-1,autoInsertedLineEnd:"",maybeInsertedBrackets:0,maybeInsertedRow:-1,maybeInsertedLineStart:"",maybeInsertedLineEnd:""})},l=function(){this.add("braces","insertion",function(a,b,d,e,f){var h=d.getCursorPosition(),i=e.doc.getLine(h.row);if("{"==f){k(d);var j=d.getSelectionRange(),m=e.doc.getTextRange(j);if(""!==m&&"{"!==m&&d.getWrapBehavioursEnabled())return{text:"{"+m+"}",selection:!1};if(l.isSaneInsertion(d,e))return/[\]\}\)]/.test(i[h.column])||d.inMultiSelectMode?(l.recordAutoInsert(d,e,"}"),{text:"{}",selection:[1,1]}):(l.recordMaybeInsert(d,e,"{"),{text:"{",selection:[1,1]})}else if("}"==f){k(d);var n=i.substring(h.column,h.column+1);if("}"==n){var o=e.$findOpeningBracket("}",{column:h.column+1,row:h.row});if(null!==o&&l.isAutoInsertedClosing(h,i,f))return l.popAutoInsertedClosing(),{text:"",selection:[1,1]}}}else{if("\n"==f||"\r\n"==f){k(d);var p="";l.isMaybeInsertedClosing(h,i)&&(p=g.stringRepeat("}",c.maybeInsertedBrackets),l.clearMaybeInsertedClosing());var n=i.substring(h.column,h.column+1);if("}"===n){var q=e.findMatchingBracket({row:h.row,column:h.column+1},"}");if(!q)return null;var r=this.$getIndent(e.getLine(q.row))}else{if(!p)return void l.clearMaybeInsertedClosing();var r=this.$getIndent(i)}var s=r+e.getTabString();return{text:"\n"+s+"\n"+r+p,selection:[1,s.length,1,s.length]}}l.clearMaybeInsertedClosing()}}),this.add("braces","deletion",function(a,b,d,e,f){var g=e.doc.getTextRange(f);if(!f.isMultiLine()&&"{"==g){k(d);var h=e.doc.getLine(f.start.row),i=h.substring(f.end.column,f.end.column+1);if("}"==i)return f.end.column++,f;c.maybeInsertedBrackets--}}),this.add("parens","insertion",function(a,b,c,d,e){if("("==e){k(c);var f=c.getSelectionRange(),g=d.doc.getTextRange(f);if(""!==g&&c.getWrapBehavioursEnabled())return{text:"("+g+")",selection:!1};if(l.isSaneInsertion(c,d))return l.recordAutoInsert(c,d,")"),{text:"()",selection:[1,1]}}else if(")"==e){k(c);var h=c.getCursorPosition(),i=d.doc.getLine(h.row),j=i.substring(h.column,h.column+1);if(")"==j){var m=d.$findOpeningBracket(")",{column:h.column+1,row:h.row});if(null!==m&&l.isAutoInsertedClosing(h,i,e))return l.popAutoInsertedClosing(),{text:"",selection:[1,1]}}}}),this.add("parens","deletion",function(a,b,c,d,e){var f=d.doc.getTextRange(e);if(!e.isMultiLine()&&"("==f){k(c);var g=d.doc.getLine(e.start.row),h=g.substring(e.start.column+1,e.start.column+2);if(")"==h)return e.end.column++,e}}),this.add("brackets","insertion",function(a,b,c,d,e){if("["==e){k(c);var f=c.getSelectionRange(),g=d.doc.getTextRange(f);if(""!==g&&c.getWrapBehavioursEnabled())return{text:"["+g+"]",selection:!1};if(l.isSaneInsertion(c,d))return l.recordAutoInsert(c,d,"]"),{text:"[]",selection:[1,1]}}else if("]"==e){k(c);var h=c.getCursorPosition(),i=d.doc.getLine(h.row),j=i.substring(h.column,h.column+1);if("]"==j){var m=d.$findOpeningBracket("]",{column:h.column+1,row:h.row});if(null!==m&&l.isAutoInsertedClosing(h,i,e))return l.popAutoInsertedClosing(),{text:"",selection:[1,1]}}}}),this.add("brackets","deletion",function(a,b,c,d,e){var f=d.doc.getTextRange(e);if(!e.isMultiLine()&&"["==f){k(c);var g=d.doc.getLine(e.start.row),h=g.substring(e.start.column+1,e.start.column+2);if("]"==h)return e.end.column++,e}}),this.add("string_dquotes","insertion",function(a,b,c,d,e){if('"'==e||"'"==e){k(c);var f=e,g=c.getSelectionRange(),h=d.doc.getTextRange(g);if(""!==h&&"'"!==h&&'"'!=h&&c.getWrapBehavioursEnabled())return{text:f+h+f,selection:!1};var i=c.getCursorPosition(),j=d.doc.getLine(i.row),l=j.substring(i.column-1,i.column),m=j.substring(i.column,i.column+1),n=d.getTokenAt(i.row,i.column),o=d.getTokenAt(i.row,i.column+1);if("\\"==l&&n&&/escape/.test(n.type))return null;var p,q=n&&/string/.test(n.type),r=!o||/string/.test(o.type);if(m==f)p=q!==r;else{if(q&&!r)return null;if(q&&r)return null;var s=d.$mode.tokenRe;s.lastIndex=0;var t=s.test(l);s.lastIndex=0;var u=s.test(l);if(t||u)return null;if(m&&!/[\s;,.})\]\\]/.test(m))return null;p=!0}return{text:p?f+f:"",selection:[1,1]}}}),this.add("string_dquotes","deletion",function(a,b,c,d,e){var f=d.doc.getTextRange(e);if(!e.isMultiLine()&&('"'==f||"'"==f)){k(c);var g=d.doc.getLine(e.start.row),h=g.substring(e.start.column+1,e.start.column+2);if(h==f)return e.end.column++,e}})};l.isSaneInsertion=function(a,b){var c=a.getCursorPosition(),d=new f(b,c.row,c.column);if(!this.$matchTokenType(d.getCurrentToken()||"text",h)){var e=new f(b,c.row,c.column+1);if(!this.$matchTokenType(e.getCurrentToken()||"text",h))return!1}return d.stepForward(),d.getCurrentTokenRow()!==c.row||this.$matchTokenType(d.getCurrentToken()||"text",i)},l.$matchTokenType=function(a,b){return b.indexOf(a.type||a)>-1},l.recordAutoInsert=function(a,b,d){var e=a.getCursorPosition(),f=b.doc.getLine(e.row);this.isAutoInsertedClosing(e,f,c.autoInsertedLineEnd[0])||(c.autoInsertedBrackets=0),c.autoInsertedRow=e.row,c.autoInsertedLineEnd=d+f.substr(e.column),c.autoInsertedBrackets++},l.recordMaybeInsert=function(a,b,d){var e=a.getCursorPosition(),f=b.doc.getLine(e.row);this.isMaybeInsertedClosing(e,f)||(c.maybeInsertedBrackets=0),c.maybeInsertedRow=e.row,c.maybeInsertedLineStart=f.substr(0,e.column)+d,c.maybeInsertedLineEnd=f.substr(e.column),c.maybeInsertedBrackets++},l.isAutoInsertedClosing=function(a,b,d){return c.autoInsertedBrackets>0&&a.row===c.autoInsertedRow&&d===c.autoInsertedLineEnd[0]&&b.substr(a.column)===c.autoInsertedLineEnd},l.isMaybeInsertedClosing=function(a,b){return c.maybeInsertedBrackets>0&&a.row===c.maybeInsertedRow&&b.substr(a.column)===c.maybeInsertedLineEnd&&b.substr(0,a.column)==c.maybeInsertedLineStart},l.popAutoInsertedClosing=function(){c.autoInsertedLineEnd=c.autoInsertedLineEnd.substr(1),c.autoInsertedBrackets--},l.clearMaybeInsertedClosing=function(){c&&(c.maybeInsertedBrackets=0,c.maybeInsertedRow=-1)},d.inherits(l,e),b.CstyleBehaviour=l}),define("ace/mode/folding/cstyle",["require","exports","module","ace/lib/oop","ace/range","ace/mode/folding/fold_mode"],function(a,b){"use strict";var c=a("../../lib/oop"),d=a("../../range").Range,e=a("./fold_mode").FoldMode,f=b.FoldMode=function(a){a&&(this.foldingStartMarker=new RegExp(this.foldingStartMarker.source.replace(/\|[^|]*?$/,"|"+a.start)),this.foldingStopMarker=new RegExp(this.foldingStopMarker.source.replace(/\|[^|]*?$/,"|"+a.end)))};c.inherits(f,e),function(){this.foldingStartMarker=/(\{|\[)[^\}\]]*$|^\s*(\/\*)/,this.foldingStopMarker=/^[^\[\{]*(\}|\])|^[\s\*]*(\*\/)/,this.singleLineBlockCommentRe=/^\s*(\/\*).*\*\/\s*$/,this.tripleStarBlockCommentRe=/^\s*(\/\*\*\*).*\*\/\s*$/,this.startRegionRe=/^\s*(\/\*|\/\/)#region\b/,this._getFoldWidgetBase=this.getFoldWidget,this.getFoldWidget=function(a,b,c){var d=a.getLine(c);if(this.singleLineBlockCommentRe.test(d)&&!this.startRegionRe.test(d)&&!this.tripleStarBlockCommentRe.test(d))return"";var e=this._getFoldWidgetBase(a,b,c);return!e&&this.startRegionRe.test(d)?"start":e},this.getFoldWidgetRange=function(a,b,c,d){var e=a.getLine(c);if(this.startRegionRe.test(e))return this.getCommentRegionBlock(a,e,c);var f=e.match(this.foldingStartMarker);if(f){var g=f.index;if(f[1])return this.openingBracketBlock(a,f[1],c,g);var h=a.getCommentFoldRange(c,g+f[0].length,1);return h&&!h.isMultiLine()&&(d?h=this.getSectionRange(a,c):"all"!=b&&(h=null)),h}if("markbegin"!==b){var f=e.match(this.foldingStopMarker);if(f){var g=f.index+f[0].length;return f[1]?this.closingBracketBlock(a,f[1],c,g):a.getCommentFoldRange(c,g,-1)}}},this.getSectionRange=function(a,b){var c=a.getLine(b),e=c.search(/\S/),f=b,g=c.length;b+=1;for(var h=b,i=a.getLength();++b<i;){c=a.getLine(b);var j=c.search(/\S/);if(-1!==j){if(e>j)break;var k=this.getFoldWidgetRange(a,"all",b);if(k){if(k.start.row<=f)break;if(k.isMultiLine())b=k.end.row;else if(e==j)break}h=b}}return new d(f,g,h,a.getLine(h).length)},this.getCommentRegionBlock=function(a,b,c){for(var e=b.search(/\s*$/),f=a.getLength(),g=c,h=/^\s*(?:\/\*|\/\/)#(end)?region\b/,i=1;++c<f;){b=a.getLine(c);var j=h.exec(b);if(j&&(j[1]?i--:i++,!i))break}var k=c;return k>g?new d(g,e,k,b.length):void 0}}.call(f.prototype)}),define("ace/mode/scad",["require","exports","module","ace/lib/oop","ace/mode/text","ace/mode/scad_highlight_rules","ace/mode/matching_brace_outdent","ace/range","ace/mode/behaviour/cstyle","ace/mode/folding/cstyle"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text").Mode,e=a("./scad_highlight_rules").scadHighlightRules,f=a("./matching_brace_outdent").MatchingBraceOutdent,g=(a("../range").Range,a("./behaviour/cstyle").CstyleBehaviour),h=a("./folding/cstyle").FoldMode,i=function(){this.HighlightRules=e,this.$outdent=new f,this.$behaviour=new g,this.foldingRules=new h};c.inherits(i,d),function(){this.lineCommentStart="//",this.blockComment={start:"/*",end:"*/"},this.getNextLineIndent=function(a,b,c){var d=this.$getIndent(b),e=this.getTokenizer().getLineTokens(b,a),f=e.tokens,g=e.state;if(f.length&&"comment"==f[f.length-1].type)return d;if("start"==a){var h=b.match(/^.*[\{\(\[]\s*$/);h&&(d+=c)}else if("doc-start"==a){if("start"==g)return"";var h=b.match(/^\s*(\/?)\*/);h&&(h[1]&&(d+=" "),d+="* ")}return d},this.checkOutdent=function(a,b,c){return this.$outdent.checkOutdent(b,c)},this.autoOutdent=function(a,b,c){this.$outdent.autoOutdent(b,c)},this.$id="ace/mode/scad"}.call(i.prototype),b.Mode=i});