define("ace/mode/abap_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"],function(a,b){"use strict";var c=a("../lib/oop"),d=a("./text_highlight_rules").TextHighlightRules,e=function(){var a=this.createKeywordMapper({"variable.language":"this",keyword:"ADD ALIAS ALIASES ASSERT ASSIGN ASSIGNING AT BACK CALL CASE CATCH CHECK CLASS CLEAR CLOSE CNT COLLECT COMMIT COMMUNICATION COMPUTE CONCATENATE CONDENSE CONSTANTS CONTINUE CONTROLS CONVERT CREATE CURRENCY DATA DEFINE DEFINITION DEFERRED DELETE DESCRIBE DETAIL DIVIDE DO ELSE ELSEIF ENDAT ENDCASE ENDCLASS ENDDO ENDEXEC ENDFORM ENDFUNCTION ENDIF ENDIFEND ENDINTERFACE ENDLOOP ENDMETHOD ENDMODULE ENDON ENDPROVIDE ENDSELECT ENDTRY ENDWHILE EVENT EVENTS EXEC EXIT EXPORT EXPORTING EXTRACT FETCH FIELDS FORM FORMAT FREE FROM FUNCTION GENERATE GET HIDE IF IMPORT IMPORTING INDEX INFOTYPES INITIALIZATION INTERFACE INTERFACES INPUT INSERT IMPLEMENTATION LEAVE LIKE LINE LOAD LOCAL LOOP MESSAGE METHOD METHODS MODIFY MODULE MOVE MULTIPLY ON OVERLAY OPTIONAL OTHERS PACK PARAMETERS PERFORM POSITION PROGRAM PROVIDE PUT RAISE RANGES READ RECEIVE RECEIVING REDEFINITION REFERENCE REFRESH REJECT REPLACE REPORT RESERVE RESTORE RETURNING ROLLBACK SCAN SCROLL SEARCH SELECT SET SHIFT SKIP SORT SORTED SPLIT STANDARD STATICS STEP STOP SUBMIT SUBTRACT SUM SUMMARY SUPPRESS TABLES TIMES TRANSFER TRANSLATE TRY TYPE TYPES UNASSIGN ULINE UNPACK UPDATE WHEN WHILE WINDOW WRITE OCCURS STRUCTURE OBJECT PROPERTY CASTING APPEND RAISING VALUE COLOR CHANGING EXCEPTION EXCEPTIONS DEFAULT CHECKBOX COMMENT ID NUMBER FOR TITLE OUTPUT WITH EXIT USING INTO WHERE GROUP BY HAVING ORDER BY SINGLE APPENDING CORRESPONDING FIELDS OF TABLE LEFT RIGHT OUTER INNER JOIN AS CLIENT SPECIFIED BYPASSING BUFFER UP TO ROWS CONNECTING EQ NE LT LE GT GE NOT AND OR XOR IN LIKE BETWEEN","constant.language":"TRUE FALSE NULL SPACE","support.type":"c n i p f d t x string xstring decfloat16 decfloat34","keyword.operator":"abs sign ceil floor trunc frac acos asin atan cos sin tan abapOperator cosh sinh tanh exp log log10 sqrt strlen xstrlen charlen numofchar dbmaxlen lines"},"text",!0," "),b="WITH\\W+(?:HEADER\\W+LINE|FRAME|KEY)|NO\\W+STANDARD\\W+PAGE\\W+HEADING|EXIT\\W+FROM\\W+STEP\\W+LOOP|BEGIN\\W+OF\\W+(?:BLOCK|LINE)|BEGIN\\W+OF|END\\W+OF\\W+(?:BLOCK|LINE)|END\\W+OF|NO\\W+INTERVALS|RESPECTING\\W+BLANKS|SEPARATED\\W+BY|USING\\W+(?:EDIT\\W+MASK)|WHERE\\W+(?:LINE)|RADIOBUTTON\\W+GROUP|REF\\W+TO|(?:PUBLIC|PRIVATE|PROTECTED)(?:\\W+SECTION)?|DELETING\\W+(?:TRAILING|LEADING)(?:ALL\\W+OCCURRENCES)|(?:FIRST|LAST)\\W+OCCURRENCE|INHERITING\\W+FROM|LINE-COUNT|ADD-CORRESPONDING|AUTHORITY-CHECK|BREAK-POINT|CLASS-DATA|CLASS-METHODS|CLASS-METHOD|DIVIDE-CORRESPONDING|EDITOR-CALL|END-OF-DEFINITION|END-OF-PAGE|END-OF-SELECTION|FIELD-GROUPS|FIELD-SYMBOLS|FUNCTION-POOL|MOVE-CORRESPONDING|MULTIPLY-CORRESPONDING|NEW-LINE|NEW-PAGE|NEW-SECTION|PRINT-CONTROL|RP-PROVIDE-FROM-LAST|SELECT-OPTIONS|SELECTION-SCREEN|START-OF-SELECTION|SUBTRACT-CORRESPONDING|SYNTAX-CHECK|SYNTAX-TRACE|TOP-OF-PAGE|TYPE-POOL|TYPE-POOLS|LINE-SIZE|LINE-COUNT|MESSAGE-ID|DISPLAY-MODE|READ(?:-ONLY)?|IS\\W+(?:NOT\\W+)?(?:ASSIGNED|BOUND|INITIAL|SUPPLIED)";this.$rules={start:[{token:"string",regex:"`",next:"string"},{token:"string",regex:"'",next:"qstring"},{token:"doc.comment",regex:/^\*.+/},{token:"comment",regex:/".+$/},{token:"invalid",regex:"\\.{2,}"},{token:"keyword.operator",regex:/\W[\-+\%=<>*]\W|\*\*|[~:,\.&$]|->*?|=>/},{token:"paren.lparen",regex:"[\\[({]"},{token:"paren.rparen",regex:"[\\])}]"},{token:"constant.numeric",regex:"[+-]?\\d+\\b"},{token:"variable.parameter",regex:/sy|pa?\d\d\d\d\|t\d\d\d\.|innnn/},{token:"keyword",regex:b},{token:"variable.parameter",regex:/\w+-\w+(?:-\w+)*/},{token:a,regex:"\\b\\w+\\b"},{caseInsensitive:!0}],qstring:[{token:"constant.language.escape",regex:"''"},{token:"string",regex:"'",next:"start"},{defaultToken:"string"}],string:[{token:"constant.language.escape",regex:"``"},{token:"string",regex:"`",next:"start"},{defaultToken:"string"}]}};c.inherits(e,d),b.AbapHighlightRules=e}),define("ace/mode/folding/coffee",["require","exports","module","ace/lib/oop","ace/mode/folding/fold_mode","ace/range"],function(a,b){"use strict";var c=a("../../lib/oop"),d=a("./fold_mode").FoldMode,e=a("../../range").Range,f=b.FoldMode=function(){};c.inherits(f,d),function(){this.getFoldWidgetRange=function(a,b,c){var d=this.indentationBlock(a,c);if(d)return d;var f=/\S/,g=a.getLine(c),h=g.search(f);if(-1!=h&&"#"==g[h]){for(var i=g.length,j=a.getLength(),k=c,l=c;++c<j;){g=a.getLine(c);var m=g.search(f);if(-1!=m){if("#"!=g[m])break;l=c}}if(l>k){var n=a.getLine(l).length;return new e(k,i,l,n)}}},this.getFoldWidget=function(a,b,c){var d=a.getLine(c),e=d.search(/\S/),f=a.getLine(c+1),g=a.getLine(c-1),h=g.search(/\S/),i=f.search(/\S/);if(-1==e)return a.foldWidgets[c-1]=-1!=h&&i>h?"start":"","";if(-1==h){if(e==i&&"#"==d[e]&&"#"==f[e])return a.foldWidgets[c-1]="",a.foldWidgets[c+1]="","start"}else if(h==e&&"#"==d[e]&&"#"==g[e]&&-1==a.getLine(c-2).search(/\S/))return a.foldWidgets[c-1]="start",a.foldWidgets[c+1]="","";return a.foldWidgets[c-1]=-1!=h&&e>h?"start":"",i>e?"start":""}}.call(f.prototype)}),define("ace/mode/abap",["require","exports","module","ace/mode/abap_highlight_rules","ace/mode/folding/coffee","ace/range","ace/mode/text","ace/lib/oop"],function(a,b){"use strict";function c(){this.HighlightRules=d,this.foldingRules=new e}var d=a("./abap_highlight_rules").AbapHighlightRules,e=a("./folding/coffee").FoldMode,f=a("../range").Range,g=a("./text").Mode,h=a("../lib/oop");h.inherits(c,g),function(){this.getNextLineIndent=function(a,b){var c=this.$getIndent(b);return c},this.toggleCommentLines=function(a,b,c,d){for(var e=new f(0,0,0,0),g=c;d>=g;++g){var h=b.getLine(g);hereComment.test(h)||(h=commentLine.test(h)?h.replace(commentLine,"$1"):h.replace(indentation,"$&#"),e.end.row=e.start.row=g,e.end.column=h.length+1,b.replace(e,h))}},this.$id="ace/mode/abap"}.call(c.prototype),b.Mode=c});