define("ace/mode/lisp_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text_highlight_rules").TextHighlightRules,e=function(){var a="case|do|let|loop|if|else|when",b="eq|neq|and|or",c="null|nil",d="cons|car|cdr|cond|lambda|format|setq|setf|quote|eval|append|list|listp|memberp|t|load|progn",e=this.createKeywordMapper({"keyword.control":a,"keyword.operator":b,"constant.language":c,"support.function":d},"identifier",!0);this.$rules={start:[{token:"comment",regex:";.*$"},{token:["storage.type.function-type.lisp","text","entity.name.function.lisp"],regex:"(?:\\b(?:(defun|defmethod|defmacro))\\b)(\\s+)((?:\\w|\\-|\\!|\\?)*)"},{token:["punctuation.definition.constant.character.lisp","constant.character.lisp"],regex:"(#)((?:\\w|[\\\\+-=<>'\"&#])+)"},{token:["punctuation.definition.variable.lisp","variable.other.global.lisp","punctuation.definition.variable.lisp"],regex:"(\\*)(\\S*)(\\*)"},{token:"constant.numeric",regex:"0[xX][0-9a-fA-F]+(?:L|l|UL|ul|u|U|F|f|ll|LL|ull|ULL)?\\b"},{token:"constant.numeric",regex:"[+-]?\\d+(?:(?:\\.\\d*)?(?:[eE][+-]?\\d+)?)?(?:L|l|UL|ul|u|U|F|f|ll|LL|ull|ULL)?\\b"},{token:e,regex:"[a-zA-Z_$][a-zA-Z0-9_$]*\\b"},{token:"string",regex:'"(?=.)',next:"qqstring"}],qqstring:[{token:"constant.character.escape.lisp",regex:"\\\\."},{token:"string",regex:'[^"\\\\]+'},{token:"string",regex:"\\\\$",next:"qqstring"},{token:"string",regex:'"|$',next:"start"}]}};c.inherits(e,d),b.LispHighlightRules=e}),define("ace/mode/lisp",["require","exports","module","ace/lib/oop","ace/mode/text","ace/mode/lisp_highlight_rules"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text").Mode,e=a("./lisp_highlight_rules").LispHighlightRules,f=function(){this.HighlightRules=e};c.inherits(f,d),function(){this.lineCommentStart=";",this.$id="ace/mode/lisp"}.call(f.prototype),b.Mode=f});