define("ace/ext/elastic_tabstops_lite",["require","exports","module","ace/editor","ace/config"],function(a,b){"use strict";var c=function(a){this.$editor=a;var b=this,c=[],d=!1;this.onAfterExec=function(){d=!1,b.processRows(c),c=[]},this.onExec=function(){d=!0},this.onChange=function(a){var b=a.data.range;d&&(-1==c.indexOf(b.start.row)&&c.push(b.start.row),b.end.row!=b.start.row&&c.push(b.end.row))}};(function(){this.processRows=function(a){this.$inChange=!0;for(var b=[],c=0,d=a.length;d>c;c++){var e=a[c];if(!(b.indexOf(e)>-1))for(var f=this.$findCellWidthsForBlock(e),g=this.$setBlockCellWidthsToMax(f.cellWidths),h=f.firstRow,i=0,j=g.length;j>i;i++){var k=g[i];b.push(h),this.$adjustRow(h,k),h++}}this.$inChange=!1},this.$findCellWidthsForBlock=function(a){for(var b,c=[],d=a;d>=0&&(b=this.$cellWidthsForRow(d),0!=b.length);)c.unshift(b),d--;var e=d+1;d=a;for(var f=this.$editor.session.getLength();f-1>d&&(d++,b=this.$cellWidthsForRow(d),0!=b.length);)c.push(b);return{cellWidths:c,firstRow:e}},this.$cellWidthsForRow=function(a){for(var b=this.$selectionColumnsForRow(a),c=[-1].concat(this.$tabsForRow(a)),d=c.map(function(){return 0}).slice(1),e=this.$editor.session.getLine(a),f=0,g=c.length-1;g>f;f++){var h=c[f]+1,i=c[f+1],j=this.$rightmostSelectionInCell(b,i),k=e.substring(h,i);d[f]=Math.max(k.replace(/\s+$/g,"").length,j-h)}return d},this.$selectionColumnsForRow=function(a){var b=[],c=this.$editor.getCursorPosition();return this.$editor.session.getSelection().isEmpty()&&a==c.row&&b.push(c.column),b},this.$setBlockCellWidthsToMax=function(a){for(var b,c,d,e=!0,f=this.$izip_longest(a),g=0,h=f.length;h>g;g++){var i=f[g];if(i.push){i.push(0/0);for(var j=0,k=i.length;k>j;j++){var l=i[j];if(e&&(b=j,d=0,e=!1),isNaN(l)){c=j;for(var m=b;c>m;m++)a[m][g]=d;e=!0}d=Math.max(d,l)}}else console.error(i)}return a},this.$rightmostSelectionInCell=function(a,b){var c=0;if(a.length){for(var d=[],e=0,f=a.length;f>e;e++)d.push(a[e]<=b?e:0);c=Math.max.apply(Math,d)}return c},this.$tabsForRow=function(a){for(var b,c=[],d=this.$editor.session.getLine(a),e=/\t/g;null!=(b=e.exec(d));)c.push(b.index);return c},this.$adjustRow=function(a,b){var c=this.$tabsForRow(a);if(0!=c.length)for(var d=0,e=-1,f=this.$izip(b,c),g=0,h=f.length;h>g;g++){var i=f[g][0],j=f[g][1];e+=1+i,j+=d;var k=e-j;if(0!=k){var l=this.$editor.session.getLine(a).substr(0,j),m=l.replace(/\s*$/g,""),n=l.length-m.length;k>0&&(this.$editor.session.getDocument().insertInLine({row:a,column:j+1},Array(k+1).join(" ")+"	"),this.$editor.session.getDocument().removeInLine(a,j,j+1),d+=k),0>k&&n>=-k&&(this.$editor.session.getDocument().removeInLine(a,j+k,j),d+=k)}}},this.$izip_longest=function(a){if(!a[0])return[];for(var b=a[0].length,c=a.length,d=1;c>d;d++){var e=a[d].length;e>b&&(b=e)}for(var f=[],g=0;b>g;g++){for(var h=[],d=0;c>d;d++)h.push(""===a[d][g]?0/0:a[d][g]);f.push(h)}return f},this.$izip=function(a,b){for(var c=a.length>=b.length?b.length:a.length,d=[],e=0;c>e;e++){var f=[a[e],b[e]];d.push(f)}return d}}).call(c.prototype),b.ElasticTabstopsLite=c;var d=a("../editor").Editor;a("../config").defineOptions(d.prototype,"editor",{useElasticTabstops:{set:function(a){a?(this.elasticTabstops||(this.elasticTabstops=new c(this)),this.commands.on("afterExec",this.elasticTabstops.onAfterExec),this.commands.on("exec",this.elasticTabstops.onExec),this.on("change",this.elasticTabstops.onChange)):this.elasticTabstops&&(this.commands.removeListener("afterExec",this.elasticTabstops.onAfterExec),this.commands.removeListener("exec",this.elasticTabstops.onExec),this.removeListener("change",this.elasticTabstops.onChange))}}})}),function(){window.require(["ace/ext/elastic_tabstops_lite"],function(){})}();