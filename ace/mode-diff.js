define("ace/mode/diff_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text_highlight_rules").TextHighlightRules,e=function(){this.$rules={start:[{regex:"^(?:\\*{15}|={67}|-{3}|\\+{3})$",token:"punctuation.definition.separator.diff",name:"keyword"},{regex:"^(@@)(\\s*.+?\\s*)(@@)(.*)$",token:["constant","constant.numeric","constant","comment.doc.tag"]},{regex:"^(\\d+)([,\\d]+)(a|d|c)(\\d+)([,\\d]+)(.*)$",token:["constant.numeric","punctuation.definition.range.diff","constant.function","constant.numeric","punctuation.definition.range.diff","invalid"],name:"meta."},{regex:"^(\\-{3}|\\+{3}|\\*{3})( .+)$",token:["constant.numeric","meta.tag"]},{regex:"^([!+>])(.*?)(\\s*)$",token:["support.constant","text","invalid"]},{regex:"^([<\\-])(.*?)(\\s*)$",token:["support.function","string","invalid"]},{regex:"^(diff)(\\s+--\\w+)?(.+?)( .+)?$",token:["variable","variable","keyword","variable"]},{regex:"^Index.+$",token:"variable"},{regex:"^\\s+$",token:"text"},{regex:"\\s*$",token:"invalid"},{defaultToken:"invisible",caseInsensitive:!0}]}};c.inherits(e,d),b.DiffHighlightRules=e}),define("ace/mode/folding/diff",["require","exports","module","ace/lib/oop","ace/mode/folding/fold_mode","ace/range"],function(a,b){"use strict";var c=a("../../lib/oop"),d=a("./fold_mode").FoldMode,e=a("../../range").Range,f=b.FoldMode=function(a,b){this.regExpList=a,this.flag=b,this.foldingStartMarker=RegExp("^("+a.join("|")+")",this.flag)};c.inherits(f,d),function(){this.getFoldWidgetRange=function(a,b,c){for(var d=a.getLine(c),f={row:c,column:d.length},g=this.regExpList,h=1;h<=g.length;h++){var i=RegExp("^("+g.slice(0,h).join("|")+")",this.flag);if(i.test(d))break}for(var j=a.getLength();++c<j&&(d=a.getLine(c),!i.test(d)););return c!=f.row+1?e.fromPoints(f,{row:c-1,column:d.length}):void 0}}.call(f.prototype)}),define("ace/mode/diff",["require","exports","module","ace/lib/oop","ace/mode/text","ace/mode/diff_highlight_rules","ace/mode/folding/diff"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text").Mode,e=a("./diff_highlight_rules").DiffHighlightRules,f=a("./folding/diff").FoldMode,g=function(){this.HighlightRules=e,this.foldingRules=new f(["diff","index","\\+{3}","@@|\\*{5}"],"i")};c.inherits(g,d),function(){this.$id="ace/mode/diff"}.call(g.prototype),b.Mode=g});