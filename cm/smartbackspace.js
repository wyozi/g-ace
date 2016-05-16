(function(mod) {
  if (typeof exports == "object" && typeof module == "object") // CommonJS
    mod(require("../../lib/codemirror"));
  else if (typeof define == "function" && define.amd) // AMD
    define(["../../lib/codemirror"], mod);
  else // Plain browser env
    mod(CodeMirror);
})(function(CodeMirror) {
  function handleBackspace(cm) {
    var posh = cm.findPosH(cm.getCursor(), -1000, "char", false);
    console.log("xd: ", posh);
  }

  var keyMap = {Backspace: handleBackspace}

  CodeMirror.defineOption("smartBackspace", false, function(cm, val, old) {
    if (old && old != CodeMirror.Init)
      cm.removeKeyMap(keyMap);
    if (val) {
      cm.addKeyMap(keyMap);
    }
  });
});