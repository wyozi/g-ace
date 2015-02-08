define("ace/mode/ada_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text_highlight_rules").TextHighlightRules,e=function(){var a="abort|else|new|return|abs|elsif|not|reverse|abstract|end|null|accept|entry|select|access|exception|of|separate|aliased|exit|or|some|all|others|subtype|and|for|out|synchronized|array|function|overriding|at|tagged|generic|package|task|begin|goto|pragma|terminate|body|private|then|if|procedure|type|case|in|protected|constant|interface|until||is|raise|use|declare|range|delay|limited|record|when|delta|loop|rem|while|digits|renames|with|do|mod|requeue|xor",b="true|false|null",c="count|min|max|avg|sum|rank|now|coalesce|main",d=this.createKeywordMapper({"support.function":c,keyword:a,"constant.language":b},"identifier",!0);this.$rules={start:[{token:"comment",regex:"--.*$"},{token:"string",regex:'".*?"'},{token:"string",regex:"'.*?'"},{token:"constant.numeric",regex:"[+-]?\\d+(?:(?:\\.\\d*)?(?:[eE][+-]?\\d+)?)?\\b"},{token:d,regex:"[a-zA-Z_$][a-zA-Z0-9_$]*\\b"},{token:"keyword.operator",regex:"\\+|\\-|\\/|\\/\\/|%|<@>|@>|<@|&|\\^|~|<|>|<=|=>|==|!=|<>|="},{token:"paren.lparen",regex:"[\\(]"},{token:"paren.rparen",regex:"[\\)]"},{token:"text",regex:"\\s+"}]}};c.inherits(e,d),b.AdaHighlightRules=e}),define("ace/mode/ada",["require","exports","module","ace/lib/oop","ace/mode/text","ace/mode/ada_highlight_rules","ace/range"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text").Mode,e=a("./ada_highlight_rules").AdaHighlightRules,f=(a("../range").Range,function(){this.HighlightRules=e});c.inherits(f,d),function(){this.lineCommentStart="--",this.$id="ace/mode/ada"}.call(f.prototype),b.Mode=f});