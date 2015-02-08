define("ace/mode/vala_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text_highlight_rules").TextHighlightRules,e=function(){this.$rules={start:[{token:["meta.using.vala","keyword.other.using.vala","meta.using.vala","storage.modifier.using.vala","meta.using.vala","punctuation.terminator.vala"],regex:"^(\\s*)(using)\\b(?:(\\s*)([^ ;$]+)(\\s*)((?:;)?))?"},{include:"#code"}],"#all-types":[{include:"#primitive-arrays"},{include:"#primitive-types"},{include:"#object-types"}],"#annotations":[{token:["storage.type.annotation.vala","punctuation.definition.annotation-arguments.begin.vala"],regex:"(@[^ (]+)(\\()",push:[{token:"punctuation.definition.annotation-arguments.end.vala",regex:"\\)",next:"pop"},{token:["constant.other.key.vala","text","keyword.operator.assignment.vala"],regex:"(\\w*)(\\s*)(=)"},{include:"#code"},{token:"punctuation.seperator.property.vala",regex:","},{defaultToken:"meta.declaration.annotation.vala"}]},{token:"storage.type.annotation.vala",regex:"@\\w*"}],"#anonymous-classes-and-new":[{token:"keyword.control.new.vala",regex:"\\bnew\\b",push_disabled:[{token:"text",regex:"(?<=\\)|\\])(?!\\s*{)|(?<=})|(?=;)",TODO:"FIXME: regexp doesn't have js equivalent",originalRegex:"(?<=\\)|\\])(?!\\s*{)|(?<=})|(?=;)",next:"pop"},{token:["storage.type.vala","text"],regex:"(\\w+)(\\s*)(?=\\[)",push:[{token:"text",regex:"}|(?=;|\\))",next:"pop"},{token:"text",regex:"\\[",push:[{token:"text",regex:"\\]",next:"pop"},{include:"#code"}]},{token:"text",regex:"{",push:[{token:"text",regex:"(?=})",next:"pop"},{include:"#code"}]}]},{token:"text",regex:"(?=\\w.*\\()",push:[{token:"text",regex:"(?<=\\))",TODO:"FIXME: regexp doesn't have js equivalent",originalRegex:"(?<=\\))",next:"pop"},{include:"#object-types"},{token:"text",regex:"\\(",push:[{token:"text",regex:"\\)",next:"pop"},{include:"#code"}]}]},{token:"meta.inner-class.vala",regex:"{",push:[{token:"meta.inner-class.vala",regex:"}",next:"pop"},{include:"#class-body"},{defaultToken:"meta.inner-class.vala"}]}]}],"#assertions":[{token:["keyword.control.assert.vala","meta.declaration.assertion.vala"],regex:"\\b(assert|requires|ensures)(\\s)",push:[{token:"meta.declaration.assertion.vala",regex:"$",next:"pop"},{token:"keyword.operator.assert.expression-seperator.vala",regex:":"},{include:"#code"},{defaultToken:"meta.declaration.assertion.vala"}]}],"#class":[{token:"meta.class.vala",regex:"(?=\\w?[\\w\\s]*(?:class|(?:@)?interface|enum|struct|namespace)\\s+\\w+)",push:[{token:"paren.vala",regex:"}",next:"pop"},{include:"#storage-modifiers"},{include:"#comments"},{token:["storage.modifier.vala","meta.class.identifier.vala","entity.name.type.class.vala"],regex:"(class|(?:@)?interface|enum|struct|namespace)(\\s+)([\\w\\.]+)"},{token:"storage.modifier.extends.vala",regex:":",push:[{token:"meta.definition.class.inherited.classes.vala",regex:"(?={|,)",next:"pop"},{include:"#object-types-inherited"},{include:"#comments"},{defaultToken:"meta.definition.class.inherited.classes.vala"}]},{token:["storage.modifier.implements.vala","meta.definition.class.implemented.interfaces.vala"],regex:"(,)(\\s)",push:[{token:"meta.definition.class.implemented.interfaces.vala",regex:"(?=\\{)",next:"pop"},{include:"#object-types-inherited"},{include:"#comments"},{defaultToken:"meta.definition.class.implemented.interfaces.vala"}]},{token:"paren.vala",regex:"{",push:[{token:"paren.vala",regex:"(?=})",next:"pop"},{include:"#class-body"},{defaultToken:"meta.class.body.vala"}]},{defaultToken:"meta.class.vala"}],comment:"attempting to put namespace in here."}],"#class-body":[{include:"#comments"},{include:"#class"},{include:"#enums"},{include:"#methods"},{include:"#annotations"},{include:"#storage-modifiers"},{include:"#code"}],"#code":[{include:"#comments"},{include:"#class"},{token:"text",regex:"{",push:[{token:"text",regex:"}",next:"pop"},{include:"#code"}]},{include:"#assertions"},{include:"#parens"},{include:"#constants-and-special-vars"},{include:"#anonymous-classes-and-new"},{include:"#keywords"},{include:"#storage-modifiers"},{include:"#strings"},{include:"#all-types"}],"#comments":[{token:"punctuation.definition.comment.vala",regex:"/\\*\\*/"},{include:"text.html.javadoc"},{include:"#comments-inline"}],"#comments-inline":[{token:"punctuation.definition.comment.vala",regex:"/\\*",push:[{token:"punctuation.definition.comment.vala",regex:"\\*/",next:"pop"},{defaultToken:"comment.block.vala"}]},{token:["text","punctuation.definition.comment.vala","comment.line.double-slash.vala"],regex:"(\\s*)(//)(.*$)"}],"#constants-and-special-vars":[{token:"constant.language.vala",regex:"\\b(?:true|false|null)\\b"},{token:"variable.language.vala",regex:"\\b(?:this|base)\\b"},{token:"constant.numeric.vala",regex:"\\b(?:0(?:x|X)[0-9a-fA-F]*|(?:[0-9]+\\.?[0-9]*|\\.[0-9]+)(?:(?:e|E)(?:\\+|-)?[0-9]+)?)(?:[LlFfUuDd]|UL|ul)?\\b"},{token:["keyword.operator.dereference.vala","constant.other.vala"],regex:"((?:\\.)?)\\b([A-Z][A-Z0-9_]+)(?!<|\\.class|\\s*\\w+\\s*=)\\b"}],"#enums":[{token:"text",regex:"^(?=\\s*[A-Z0-9_]+\\s*(?:{|\\(|,))",push:[{token:"text",regex:"(?=;|})",next:"pop"},{token:"constant.other.enum.vala",regex:"\\w+",push:[{token:"meta.enum.vala",regex:"(?=,|;|})",next:"pop"},{include:"#parens"},{token:"text",regex:"{",push:[{token:"text",regex:"}",next:"pop"},{include:"#class-body"}]},{defaultToken:"meta.enum.vala"}]}]}],"#keywords":[{token:"keyword.control.catch-exception.vala",regex:"\\b(?:try|catch|finally|throw)\\b"},{token:"keyword.control.vala",regex:"\\?|:|\\?\\?"},{token:"keyword.control.vala",regex:"\\b(?:return|break|case|continue|default|do|while|for|foreach|switch|if|else|in|yield|get|set|value)\\b"},{token:"keyword.operator.vala",regex:"\\b(?:typeof|is|as)\\b"},{token:"keyword.operator.comparison.vala",regex:"==|!=|<=|>=|<>|<|>"},{token:"keyword.operator.assignment.vala",regex:"="},{token:"keyword.operator.increment-decrement.vala",regex:"\\-\\-|\\+\\+"},{token:"keyword.operator.arithmetic.vala",regex:"\\-|\\+|\\*|\\/|%"},{token:"keyword.operator.logical.vala",regex:"!|&&|\\|\\|"},{token:"keyword.operator.dereference.vala",regex:"\\.(?=\\S)",originalRegex:"(?<=\\S)\\.(?=\\S)"},{token:"punctuation.terminator.vala",regex:";"},{token:"keyword.operator.ownership",regex:"owned|unowned"}],"#methods":[{token:"meta.method.vala",regex:"(?!new)(?=\\w.*\\s+)(?=[^=]+\\()",push:[{token:"paren.vala",regex:"}|(?=;)",next:"pop"},{include:"#storage-modifiers"},{token:["entity.name.function.vala","meta.method.identifier.vala"],regex:"([\\~\\w\\.]+)(\\s*\\()",push:[{token:"meta.method.identifier.vala",regex:"\\)",next:"pop"},{include:"#parameters"},{defaultToken:"meta.method.identifier.vala"}]},{token:"meta.method.return-type.vala",regex:"(?=\\w.*\\s+\\w+\\s*\\()",push:[{token:"meta.method.return-type.vala",regex:"(?=\\w+\\s*\\()",next:"pop"},{include:"#all-types"},{defaultToken:"meta.method.return-type.vala"}]},{include:"#throws"},{token:"paren.vala",regex:"{",push:[{token:"paren.vala",regex:"(?=})",next:"pop"},{include:"#code"},{defaultToken:"meta.method.body.vala"}]},{defaultToken:"meta.method.vala"}]}],"#namespace":[{token:"text",regex:"^(?=\\s*[A-Z0-9_]+\\s*(?:{|\\(|,))",push:[{token:"text",regex:"(?=;|})",next:"pop"},{token:"constant.other.namespace.vala",regex:"\\w+",push:[{token:"meta.namespace.vala",regex:"(?=,|;|})",next:"pop"},{include:"#parens"},{token:"text",regex:"{",push:[{token:"text",regex:"}",next:"pop"},{include:"#code"}]},{defaultToken:"meta.namespace.vala"}]}],comment:"This is not quite right. See the class grammar right now"}],"#object-types":[{token:"storage.type.generic.vala",regex:"\\b(?:[a-z]\\w*\\.)*[A-Z]+\\w*<",push:[{token:"storage.type.generic.vala",regex:">|[^\\w\\s,\\?<\\[()\\]]",TODO:"FIXME: regexp doesn't have js equivalent",originalRegex:">|[^\\w\\s,\\?<\\[(?:[,]+)\\]]",next:"pop"},{include:"#object-types"},{token:"storage.type.generic.vala",regex:"<",push:[{token:"storage.type.generic.vala",regex:">|[^\\w\\s,\\[\\]<]",next:"pop"},{defaultToken:"storage.type.generic.vala"}],comment:"This is just to support <>'s with no actual type prefix"},{defaultToken:"storage.type.generic.vala"}]},{token:"storage.type.object.array.vala",regex:"\\b(?:[a-z]\\w*\\.)*[A-Z]+\\w*(?=\\[)",push:[{token:"storage.type.object.array.vala",regex:"(?=[^\\]\\s])",next:"pop"},{token:"text",regex:"\\[",push:[{token:"text",regex:"\\]",next:"pop"},{include:"#code"}]},{defaultToken:"storage.type.object.array.vala"}]},{token:["storage.type.vala","keyword.operator.dereference.vala","storage.type.vala"],regex:"\\b(?:([a-z]\\w*)(\\.))*([A-Z]+\\w*\\b)"}],"#object-types-inherited":[{token:"entity.other.inherited-class.vala",regex:"\\b(?:[a-z]\\w*\\.)*[A-Z]+\\w*<",push:[{token:"entity.other.inherited-class.vala",regex:">|[^\\w\\s,<]",next:"pop"},{include:"#object-types"},{token:"storage.type.generic.vala",regex:"<",push:[{token:"storage.type.generic.vala",regex:">|[^\\w\\s,<]",next:"pop"},{defaultToken:"storage.type.generic.vala"}],comment:"This is just to support <>'s with no actual type prefix"},{defaultToken:"entity.other.inherited-class.vala"}]},{token:["entity.other.inherited-class.vala","keyword.operator.dereference.vala","entity.other.inherited-class.vala"],regex:"\\b(?:([a-z]\\w*)(\\.))*([A-Z]+\\w*)"}],"#parameters":[{token:"storage.modifier.vala",regex:"final"},{include:"#primitive-arrays"},{include:"#primitive-types"},{include:"#object-types"},{token:"variable.parameter.vala",regex:"\\w+"}],"#parens":[{token:"text",regex:"\\(",push:[{token:"text",regex:"\\)",next:"pop"},{include:"#code"}]}],"#primitive-arrays":[{token:"storage.type.primitive.array.vala",regex:"\\b(?:bool|byte|sbyte|char|decimal|double|float|int|uint|long|ulong|object|short|ushort|string|void|int8|int16|int32|int64|uint8|uint16|uint32|uint64)(?:\\[\\])*\\b"}],"#primitive-types":[{token:"storage.type.primitive.vala",regex:"\\b(?:var|bool|byte|sbyte|char|decimal|double|float|int|uint|long|ulong|object|short|ushort|string|void|signal|int8|int16|int32|int64|uint8|uint16|uint32|uint64)\\b",comment:"var is not really a primitive, but acts like one in most cases"}],"#storage-modifiers":[{token:"storage.modifier.vala",regex:"\\b(?:public|private|protected|internal|static|final|sealed|virtual|override|abstract|readonly|volatile|dynamic|async|unsafe|out|ref|weak|owned|unowned|const)\\b",comment:"Not sure about unsafe and readonly"}],"#strings":[{token:"punctuation.definition.string.begin.vala",regex:'@"',push:[{token:"punctuation.definition.string.end.vala",regex:'"',next:"pop"},{token:"constant.character.escape.vala",regex:"\\\\.|%[\\w\\.\\-]+|\\$(?:\\w+|\\([\\w\\s\\+\\-\\*\\/]+\\))"},{defaultToken:"string.quoted.interpolated.vala"}]},{token:"punctuation.definition.string.begin.vala",regex:'"',push:[{token:"punctuation.definition.string.end.vala",regex:'"',next:"pop"},{token:"constant.character.escape.vala",regex:"\\\\."},{token:"constant.character.escape.vala",regex:"%[\\w\\.\\-]+"},{defaultToken:"string.quoted.double.vala"}]},{token:"punctuation.definition.string.begin.vala",regex:"'",push:[{token:"punctuation.definition.string.end.vala",regex:"'",next:"pop"},{token:"constant.character.escape.vala",regex:"\\\\."},{defaultToken:"string.quoted.single.vala"}]},{token:"punctuation.definition.string.begin.vala",regex:'"""',push:[{token:"punctuation.definition.string.end.vala",regex:'"""',next:"pop"},{token:"constant.character.escape.vala",regex:"%[\\w\\.\\-]+"},{defaultToken:"string.quoted.triple.vala"}]}],"#throws":[{token:"storage.modifier.vala",regex:"throws",push:[{token:"meta.throwables.vala",regex:"(?={|;)",next:"pop"},{include:"#object-types"},{defaultToken:"meta.throwables.vala"}]}],"#values":[{include:"#strings"},{include:"#object-types"},{include:"#constants-and-special-vars"}]},this.normalizeRules()};e.metaData={comment:"Based heavily on the Java bundle's language syntax. TODO:\n* Closures\n* Delegates\n* Properties: Better support for properties.\n* Annotations\n* Error domains\n* Named arguments\n* Array slicing, negative indexes, multidimensional\n* construct blocks\n* lock blocks?\n* regex literals\n* DocBlock syntax highlighting. (Currently importing javadoc)\n* Folding rule for comments.\n",fileTypes:["vala"],foldingStartMarker:"(\\{\\s*(//.*)?$|^\\s*// \\{\\{\\{)",foldingStopMarker:"^\\s*(\\}|// \\}\\}\\}$)",name:"Vala",scopeName:"source.vala"},c.inherits(e,d),b.ValaHighlightRules=e}),define("ace/mode/folding/cstyle",["require","exports","module","ace/lib/oop","ace/range","ace/mode/folding/fold_mode"],function(a,b){"use strict";var c=a("../../lib/oop"),d=a("../../range").Range,e=a("./fold_mode").FoldMode,f=b.FoldMode=function(a){a&&(this.foldingStartMarker=new RegExp(this.foldingStartMarker.source.replace(/\|[^|]*?$/,"|"+a.start)),this.foldingStopMarker=new RegExp(this.foldingStopMarker.source.replace(/\|[^|]*?$/,"|"+a.end)))};c.inherits(f,e),function(){this.foldingStartMarker=/(\{|\[)[^\}\]]*$|^\s*(\/\*)/,this.foldingStopMarker=/^[^\[\{]*(\}|\])|^[\s\*]*(\*\/)/,this.singleLineBlockCommentRe=/^\s*(\/\*).*\*\/\s*$/,this.tripleStarBlockCommentRe=/^\s*(\/\*\*\*).*\*\/\s*$/,this.startRegionRe=/^\s*(\/\*|\/\/)#region\b/,this._getFoldWidgetBase=this.getFoldWidget,this.getFoldWidget=function(a,b,c){var d=a.getLine(c);if(this.singleLineBlockCommentRe.test(d)&&!this.startRegionRe.test(d)&&!this.tripleStarBlockCommentRe.test(d))return"";var e=this._getFoldWidgetBase(a,b,c);return!e&&this.startRegionRe.test(d)?"start":e},this.getFoldWidgetRange=function(a,b,c,d){var e=a.getLine(c);if(this.startRegionRe.test(e))return this.getCommentRegionBlock(a,e,c);var f=e.match(this.foldingStartMarker);if(f){var g=f.index;if(f[1])return this.openingBracketBlock(a,f[1],c,g);var h=a.getCommentFoldRange(c,g+f[0].length,1);return h&&!h.isMultiLine()&&(d?h=this.getSectionRange(a,c):"all"!=b&&(h=null)),h}if("markbegin"!==b){var f=e.match(this.foldingStopMarker);if(f){var g=f.index+f[0].length;return f[1]?this.closingBracketBlock(a,f[1],c,g):a.getCommentFoldRange(c,g,-1)}}},this.getSectionRange=function(a,b){var c=a.getLine(b),e=c.search(/\S/),f=b,g=c.length;b+=1;for(var h=b,i=a.getLength();++b<i;){c=a.getLine(b);var j=c.search(/\S/);if(-1!==j){if(e>j)break;var k=this.getFoldWidgetRange(a,"all",b);if(k){if(k.start.row<=f)break;if(k.isMultiLine())b=k.end.row;else if(e==j)break}h=b}}return new d(f,g,h,a.getLine(h).length)},this.getCommentRegionBlock=function(a,b,c){for(var e=b.search(/\s*$/),f=a.getLength(),g=c,h=/^\s*(?:\/\*|\/\/)#(end)?region\b/,i=1;++c<f;){b=a.getLine(c);var j=h.exec(b);if(j&&(j[1]?i--:i++,!i))break}var k=c;return k>g?new d(g,e,k,b.length):void 0}}.call(f.prototype)}),define("ace/mode/behaviour/cstyle",["require","exports","module","ace/lib/oop","ace/mode/behaviour","ace/token_iterator","ace/lib/lang"],function(a,b){"use strict";var c,d=a("../../lib/oop"),e=a("../behaviour").Behaviour,f=a("../../token_iterator").TokenIterator,g=a("../../lib/lang"),h=["text","paren.rparen","punctuation.operator"],i=["text","paren.rparen","punctuation.operator","comment"],j={},k=function(a){var b=-1;return a.multiSelect&&(b=a.selection.index,j.rangeCount!=a.multiSelect.rangeCount&&(j={rangeCount:a.multiSelect.rangeCount})),j[b]?c=j[b]:void(c=j[b]={autoInsertedBrackets:0,autoInsertedRow:-1,autoInsertedLineEnd:"",maybeInsertedBrackets:0,maybeInsertedRow:-1,maybeInsertedLineStart:"",maybeInsertedLineEnd:""})},l=function(){this.add("braces","insertion",function(a,b,d,e,f){var h=d.getCursorPosition(),i=e.doc.getLine(h.row);if("{"==f){k(d);var j=d.getSelectionRange(),m=e.doc.getTextRange(j);if(""!==m&&"{"!==m&&d.getWrapBehavioursEnabled())return{text:"{"+m+"}",selection:!1};if(l.isSaneInsertion(d,e))return/[\]\}\)]/.test(i[h.column])||d.inMultiSelectMode?(l.recordAutoInsert(d,e,"}"),{text:"{}",selection:[1,1]}):(l.recordMaybeInsert(d,e,"{"),{text:"{",selection:[1,1]})}else if("}"==f){k(d);var n=i.substring(h.column,h.column+1);if("}"==n){var o=e.$findOpeningBracket("}",{column:h.column+1,row:h.row});if(null!==o&&l.isAutoInsertedClosing(h,i,f))return l.popAutoInsertedClosing(),{text:"",selection:[1,1]}}}else{if("\n"==f||"\r\n"==f){k(d);var p="";l.isMaybeInsertedClosing(h,i)&&(p=g.stringRepeat("}",c.maybeInsertedBrackets),l.clearMaybeInsertedClosing());var n=i.substring(h.column,h.column+1);if("}"===n){var q=e.findMatchingBracket({row:h.row,column:h.column+1},"}");if(!q)return null;var r=this.$getIndent(e.getLine(q.row))}else{if(!p)return void l.clearMaybeInsertedClosing();var r=this.$getIndent(i)}var s=r+e.getTabString();return{text:"\n"+s+"\n"+r+p,selection:[1,s.length,1,s.length]}}l.clearMaybeInsertedClosing()}}),this.add("braces","deletion",function(a,b,d,e,f){var g=e.doc.getTextRange(f);if(!f.isMultiLine()&&"{"==g){k(d);var h=e.doc.getLine(f.start.row),i=h.substring(f.end.column,f.end.column+1);if("}"==i)return f.end.column++,f;c.maybeInsertedBrackets--}}),this.add("parens","insertion",function(a,b,c,d,e){if("("==e){k(c);var f=c.getSelectionRange(),g=d.doc.getTextRange(f);if(""!==g&&c.getWrapBehavioursEnabled())return{text:"("+g+")",selection:!1};if(l.isSaneInsertion(c,d))return l.recordAutoInsert(c,d,")"),{text:"()",selection:[1,1]}}else if(")"==e){k(c);var h=c.getCursorPosition(),i=d.doc.getLine(h.row),j=i.substring(h.column,h.column+1);if(")"==j){var m=d.$findOpeningBracket(")",{column:h.column+1,row:h.row});if(null!==m&&l.isAutoInsertedClosing(h,i,e))return l.popAutoInsertedClosing(),{text:"",selection:[1,1]}}}}),this.add("parens","deletion",function(a,b,c,d,e){var f=d.doc.getTextRange(e);if(!e.isMultiLine()&&"("==f){k(c);var g=d.doc.getLine(e.start.row),h=g.substring(e.start.column+1,e.start.column+2);if(")"==h)return e.end.column++,e}}),this.add("brackets","insertion",function(a,b,c,d,e){if("["==e){k(c);var f=c.getSelectionRange(),g=d.doc.getTextRange(f);if(""!==g&&c.getWrapBehavioursEnabled())return{text:"["+g+"]",selection:!1};if(l.isSaneInsertion(c,d))return l.recordAutoInsert(c,d,"]"),{text:"[]",selection:[1,1]}}else if("]"==e){k(c);var h=c.getCursorPosition(),i=d.doc.getLine(h.row),j=i.substring(h.column,h.column+1);if("]"==j){var m=d.$findOpeningBracket("]",{column:h.column+1,row:h.row});if(null!==m&&l.isAutoInsertedClosing(h,i,e))return l.popAutoInsertedClosing(),{text:"",selection:[1,1]}}}}),this.add("brackets","deletion",function(a,b,c,d,e){var f=d.doc.getTextRange(e);if(!e.isMultiLine()&&"["==f){k(c);var g=d.doc.getLine(e.start.row),h=g.substring(e.start.column+1,e.start.column+2);if("]"==h)return e.end.column++,e}}),this.add("string_dquotes","insertion",function(a,b,c,d,e){if('"'==e||"'"==e){k(c);var f=e,g=c.getSelectionRange(),h=d.doc.getTextRange(g);if(""!==h&&"'"!==h&&'"'!=h&&c.getWrapBehavioursEnabled())return{text:f+h+f,selection:!1};var i=c.getCursorPosition(),j=d.doc.getLine(i.row),l=j.substring(i.column-1,i.column),m=j.substring(i.column,i.column+1),n=d.getTokenAt(i.row,i.column),o=d.getTokenAt(i.row,i.column+1);if("\\"==l&&n&&/escape/.test(n.type))return null;var p,q=n&&/string/.test(n.type),r=!o||/string/.test(o.type);if(m==f)p=q!==r;else{if(q&&!r)return null;if(q&&r)return null;var s=d.$mode.tokenRe;s.lastIndex=0;var t=s.test(l);s.lastIndex=0;var u=s.test(l);if(t||u)return null;if(m&&!/[\s;,.})\]\\]/.test(m))return null;p=!0}return{text:p?f+f:"",selection:[1,1]}}}),this.add("string_dquotes","deletion",function(a,b,c,d,e){var f=d.doc.getTextRange(e);if(!e.isMultiLine()&&('"'==f||"'"==f)){k(c);var g=d.doc.getLine(e.start.row),h=g.substring(e.start.column+1,e.start.column+2);if(h==f)return e.end.column++,e}})};l.isSaneInsertion=function(a,b){var c=a.getCursorPosition(),d=new f(b,c.row,c.column);if(!this.$matchTokenType(d.getCurrentToken()||"text",h)){var e=new f(b,c.row,c.column+1);if(!this.$matchTokenType(e.getCurrentToken()||"text",h))return!1}return d.stepForward(),d.getCurrentTokenRow()!==c.row||this.$matchTokenType(d.getCurrentToken()||"text",i)},l.$matchTokenType=function(a,b){return b.indexOf(a.type||a)>-1},l.recordAutoInsert=function(a,b,d){var e=a.getCursorPosition(),f=b.doc.getLine(e.row);this.isAutoInsertedClosing(e,f,c.autoInsertedLineEnd[0])||(c.autoInsertedBrackets=0),c.autoInsertedRow=e.row,c.autoInsertedLineEnd=d+f.substr(e.column),c.autoInsertedBrackets++},l.recordMaybeInsert=function(a,b,d){var e=a.getCursorPosition(),f=b.doc.getLine(e.row);this.isMaybeInsertedClosing(e,f)||(c.maybeInsertedBrackets=0),c.maybeInsertedRow=e.row,c.maybeInsertedLineStart=f.substr(0,e.column)+d,c.maybeInsertedLineEnd=f.substr(e.column),c.maybeInsertedBrackets++},l.isAutoInsertedClosing=function(a,b,d){return c.autoInsertedBrackets>0&&a.row===c.autoInsertedRow&&d===c.autoInsertedLineEnd[0]&&b.substr(a.column)===c.autoInsertedLineEnd},l.isMaybeInsertedClosing=function(a,b){return c.maybeInsertedBrackets>0&&a.row===c.maybeInsertedRow&&b.substr(a.column)===c.maybeInsertedLineEnd&&b.substr(0,a.column)==c.maybeInsertedLineStart},l.popAutoInsertedClosing=function(){c.autoInsertedLineEnd=c.autoInsertedLineEnd.substr(1),c.autoInsertedBrackets--},l.clearMaybeInsertedClosing=function(){c&&(c.maybeInsertedBrackets=0,c.maybeInsertedRow=-1)},d.inherits(l,e),b.CstyleBehaviour=l}),define("ace/mode/matching_brace_outdent",["require","exports","module","ace/range"],function(a,b){"use strict";var c=a("../range").Range,d=function(){};(function(){this.checkOutdent=function(a,b){return/^\s+$/.test(a)?/^\s*\}/.test(b):!1},this.autoOutdent=function(a,b){var d=a.getLine(b),e=d.match(/^(\s*\})/);if(!e)return 0;var f=e[1].length,g=a.findMatchingBracket({row:b,column:f});if(!g||g.row==b)return 0;var h=this.$getIndent(a.getLine(g.row));a.replace(new c(b,0,b,f-1),h)},this.$getIndent=function(a){return a.match(/^\s*/)[0]}}).call(d.prototype),b.MatchingBraceOutdent=d}),define("ace/mode/vala",["require","exports","module","ace/lib/oop","ace/mode/text","ace/tokenizer","ace/mode/vala_highlight_rules","ace/mode/folding/cstyle","ace/mode/behaviour/cstyle","ace/mode/folding/cstyle","ace/mode/matching_brace_outdent"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text").Mode,e=(a("../tokenizer").Tokenizer,a("./vala_highlight_rules").ValaHighlightRules),f=(a("./folding/cstyle").FoldMode,a("./behaviour/cstyle").CstyleBehaviour),g=a("./folding/cstyle").FoldMode,h=a("./matching_brace_outdent").MatchingBraceOutdent,i=function(){this.HighlightRules=e,this.$outdent=new h,this.$behaviour=new f,this.foldingRules=new g};c.inherits(i,d),function(){this.lineCommentStart="//",this.blockComment={start:"/*",end:"*/"},this.getNextLineIndent=function(a,b,c){var d=this.$getIndent(b),e=this.getTokenizer().getLineTokens(b,a),f=e.tokens,g=e.state;if(f.length&&"comment"==f[f.length-1].type)return d;if("start"==a||"no_regex"==a){var h=b.match(/^.*(?:\bcase\b.*\:|[\{\(\[])\s*$/);h&&(d+=c)}else if("doc-start"==a){if("start"==g||"no_regex"==g)return"";var h=b.match(/^\s*(\/?)\*/);h&&(h[1]&&(d+=" "),d+="* ")}return d},this.checkOutdent=function(a,b,c){return this.$outdent.checkOutdent(b,c)},this.autoOutdent=function(a,b,c){this.$outdent.autoOutdent(b,c)},this.$id="ace/mode/vala"}.call(i.prototype),b.Mode=i});