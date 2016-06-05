var editor = ace.edit("editor");

// Load editor related classes etc
var langTools = ace.require("ace/ext/language_tools");
ace.require('ace/ext/settings_menu').init(editor);
ace.require('ace/ext/keybinding_menu').init(editor);

var snippetManager = ace.require("ace/snippets").snippetManager;
function insertSnippet(snippet) {
	snippetManager.insertSnippetForSelection(editor, snippet);
}

var StatusBar = ace.require('ace/ext/statusbar').StatusBar;
var statusBar = new StatusBar(editor, document.getElementById("status-bar"));
statusBar.updateStatus = function(editor) {
	var status = [];
	function add(str, separator) {
		str && status.push(str, separator || "|");
	}

	add(editor.keyBinding.getStatusText(editor));
	if (editor.commands.recording)
		add("REC");

	var c = editor.selection.lead;
	add(c.row + ":" + c.column, " ");
	if (!editor.selection.isEmpty()) {
		var r = editor.getSelectionRange();
		add("(" + (r.end.row - r.start.row) + ":"  +(r.end.column - r.start.column) + ")", " ");
	}

	var sess = gaceSessions.getSessionId();
	add("Session:(" + sess + ")", " ");

	var otSess = gaceCollaborate.getSession(sess);
	if (otSess != undefined) {
		var stateStr = otSess.client.state.constructor.name;
		add("Collaboration:(rev: " + otSess.lastSentRev + "/" + otSess.client.revision + "; state: " + stateStr + ")", " ");
	}

	var modeId = editor.getSession().getMode().$id;
	add("Mode:(" + modeId.replace("ace/mode/", "") + ")", " ");

	var cursor = editor.getCursorPosition();
	var token = editor.getSession().getTokenAt(cursor.row, cursor.column);
	if (token != null) {
		add("Token:(" + token.type + ")", " ");
	}

	status.pop();
	this.element.textContent = status.join("");
};

// We should remove the old class, but it gets overridden by the new one so meh
editor.renderer.on("themeLoaded", function(e) {
	document.getElementById("status-bar").classList.add(editor.renderer.theme.cssClass);
});

var Search = ace.require("ace/search").Search;

// Enable autocomplete etc
editor.setOptions({
	enableBasicAutocompletion: true,
	enableSnippets: true,
	scrollPastEnd: true,
	dragEnabled: false
});

// Add Gmod automcompletions
var acutil = ace.require("ace/autocomplete/util");

var gmodApiCallbacks = {};
var requestId = 0;
var gmodApiCompleter = {
	getCompletions: function(editor, session, pos, prefix, callback) {
		if ("gace" in window) {
			var ID_REGEX = /[a-zA-Z_0-9\$\-\u00A2-\uFFFF\.:\(\)]/;
			var line = editor.session.getLine(pos.row);
			var codeprefix = acutil.retrievePrecedingIdentifier(line, pos.column, ID_REGEX);

			if (codeprefix.length === 0) { callback(null, []); return }

			var creqid = "request" + (requestId++);
			gmodApiCallbacks[creqid] = callback;
			gace.QueryGModApi(creqid, codeprefix);
		}
	}
}
langTools.addCompleter(gmodApiCompleter);

function ParseGModQueryResponse(requestid, values) {
	gmodApiCallbacks[requestid](null, values);
	delete gmodApiCallbacks[requestid];
}

// Add row highlighting
var AceRange = require("ace/range").Range;
function HighlightRow(rownum) {
	var marker = editor.getSession().addMarker(new AceRange(rownum, 0, rownum, 2000), "gace-highlight", "fullLine", true);

	setTimeout(function() {
		anim(document.querySelector(".gace-highlight"), {opacity: 0}, 3, "ease-in");
	}, 100);

	setTimeout(function() {
		editor.getSession().removeMarker(marker);
	}, 3100);
}

// Add context menu
document.addEventListener("contextmenu", function() {
	if (!("gace" in window && "ContextMenu" in gace)) {
		return;
	}

	var data = {
		cursorpos: editor.getCursorPosition(),
		selection: editor.getSelectionRange(),
		selection_text: editor.getCopyText()
	};
	gace.ContextMenu(JSON.stringify(data));
})

var emptySessionContent = editor.getSession().getValue();
var emptySession = ace.createEditSession(editor.getSession().getValue(), "ace/mode/rust");

editor.setSession(emptySession);

editor.on("change", function(e) {
	if ("gace" in window) {
		gace.UpdateSessionContent(editor.getSession().getValue());
	}
});

editor.commands.addCommand({
	name: 'Open documentation',
	bindKey: {win: 'Ctrl-Q',  mac: 'Command-Q'},
	exec: function(editor) {
		var pos = editor.getCursorPosition();

		var ID_REGEX = /[a-zA-Z_0-9\$\-\u00A2-\uFFFF\.]/;
		var line = editor.session.getLine(pos.row);
		var codeprefix = acutil.retrievePrecedingIdentifier(line, pos.column, ID_REGEX);
		var codepostfix = acutil.retrieveFollowingIdentifier(line, pos.column, ID_REGEX).join("");

		var codeLibCall = codeprefix + codepostfix;

		if ("gace" in window) {
			gace.OpenDocumentationFor(codeLibCall);
		}
	}
});

editor.commands.addCommand({
	name: 'Save',
	bindKey: {win: 'Ctrl-S',  mac: 'Command-S'},
	exec: function(editor) {
		gace.SaveSession();
	}
});

editor.commands.addCommand({
	name: 'New file',
	bindKey: {win: 'Ctrl-N',  mac: 'Command-N'},
	exec: function(editor) {
		gace.NewSession();
	},
	readOnly: true
});

editor.commands.addCommand({
	name: 'Close file',
	bindKey: {win: 'Ctrl-W',  mac: 'Command-W'},
	exec: function(editor) {
		gace.CloseSession(false);
	},
	readOnly: true
});

editor.commands.removeCommand("removeline"); // Remove existing Ctrl-D binding
editor.commands.addCommand({
	name: 'Add next instance of word to selection',
	bindKey: {win: 'Ctrl-D',  mac: 'Command-D'},
	exec: function(editor) {
		var selectedText = editor.getSession().getTextRange(editor.getSelectionRange());
		var range = editor.find({
			needle: selectedText,
			start: editor.getSelectionRange(),
			preventScroll: true
		});
		editor.getSession().getSelection().addRange(range);
	},
	readOnly: true
});

editor.commands.addCommand({
	name: 'Go to link',
	bindKey: {win: 'Ctrl-enter',  mac: 'Ctrl-enter'},
	exec: function(editor) {
		var selectedText = editor.getSession().getLine(editor.getCursorPosition().row);
		var res = selectedText.match(/goto\[f=([^;]*);r=([^;\]]*)(?:;c=([^\]]*))?/);
		if (res && !isNaN(res[2]))
			gace.GotoPath(res[1], parseInt(res[2]), parseInt(res[3]));
		else if (!res)
			console.log("G-Ace Goto failed: line doesn't seem to be a 'goto' line");
		else
			console.log("G-Ace Goto failed: " + res[2] + " can't be converted to number");
	},
	readOnly: true
});

editor.commands.addCommand({
	name: "Outdent (workaround)",
	bindKey: {win: "Ctrl-Shift-Tab", max: "Ctrl-Shift-Tab"},
	exec: function(editor) { editor.blockOutdent(); },
	multiSelectAction: "forEach",
	scrollIntoView: "selectionPart"
})

// Weirdest hack EU. We need to throw an error in here, or typing right curly brackets won't work
editor.commands.addCommand({
	name: 'Add right curly bracket }',
	bindKey: {win: 'Ctrl-alt-0', mac: 'Ctrl-alt-0'},
	exec: function(editor) {
		//return false;
		throw "dirty hack to make right curly bracket work";
	}
});

// whatever
String.prototype.endsWith = function(suffix) {
	return this.indexOf(suffix, this.length - suffix.length) !== -1;
};

function guessModeFromPath(path) {
	if (path.endsWith(".moon"))
		return "ace/mode/coffee";

	var mode = ace.require('ace/ext/modelist').getModeForPath(path);

	// We'll assume if ace couldnt figure out the mode, it's Lua
	if (mode.name != "text") {
		return mode.mode;
	}
	return "ace/mode/lua";
}

var gaceSessions = (function() {
	var sessions = {};
	var sessionId = null;

	return {
		exists: function(id) {
			return id in sessions;
		},
		getSession: function(id) {
			return sessions[id];
		},
		setSession: function(id, data) {
			var existedBefore = true;

			if (!this.exists(id)) {
				var mode = (data.mode === undefined ? guessModeFromPath(id) : data.mode);
				sessions[id] = ace.createEditSession("", mode);
				existedBefore = false;
			}

			var session = sessions[id];

			session.setUseWrapMode(false);
			session.setUseSoftTabs(false);

			editor.setSession(session);
			editor.setReadOnly(false);
			sessionId = id;

			var content;
			if ("contentb" in data)
				// Decode base64
				content = btoa(data.contentb);
			else
				content = data.content;

			if (content !== undefined) {
				session.setValue(content);
			}
			else if (data.requestDataIfNotCached && !existedBefore) {
				// If we're setting session without passing contents and contents are not cached in html, request newest content from lua
				gace.RequestSessionContent();
			}

			if (!gaceCollaborate.isSubscribed(id) && /\.ot$/.test(id)) {
				gaceCollaborate.subscribe(id);
			}
		},
		removeSession: function(id) {
			// If closed session is current session, lets clear it by making new empty session
			if (editor.getSession() == sessions[id]) {
				editor.setSession(emptySession);
				editor.setReadOnly(true);
				sessionId = null;
			}
			delete sessions[id];
			gaceCollaborate.removeSession(id);
		},
		getSessionId: function() {
			return sessionId;
		}
	}
})();

// Programmatically create css for different collaboration cursors
(function() {
	var dom = ace.require("ace/lib/dom");
	var cssText = "";

	var cursors = 12;

	var colors = Please.make_color({
		colors_returned: cursors
	});

	for (var i = 0; i < cursors; i++) {
		cssText += ".ot-cursor-" + i + " {\
			position: absolute;\
			background-color: " + colors[i] + ";\
			border-left: 2px solid " + colors[i] + ";\
			z-index: 3;\
			opacity: 0.8;\
		}\n";
	}

	dom.importCssString(cssText, "ot-cursor");
})();

var gaceCollaborate = (function() {
	var otSessions = {};
	var ignoreEditorChanges = false;
	var _debug = false;
	function debug(b) {
		_debug = b;
	}

	function applyOperationToAce(id, operation) {
		var sess = gaceSessions.getSession(id);

		if (sess === undefined) {
			console.log("trying to apply op to unknown session " + id);
			return;
		}

		ignoreEditorChanges = true;

		var index = 0;
		for (var i in operation.ops) {
			var op = operation.ops[i];
			if (ot.TextOperation.isRetain(op)) {
				index += op;
			}
			else if (ot.TextOperation.isInsert(op)) {
				sess.getDocument().insert(sess.getDocument().indexToPosition(index), op);
				index += op.length;
			}
			else if (ot.TextOperation.isDelete(op)) {
				var from = sess.getDocument().indexToPosition(index);
				var to = sess.getDocument().indexToPosition(index + -op);
				var range = AceRange.fromPoints(from, to);

				sess.getDocument().remove(range);
			}
		}

		ignoreEditorChanges = false;
	}

	function onSubscribed(id, json) {
		var sess = gaceSessions.getSession(id);

		if (sess === undefined) {
			console.log("trying to subscribe to unknown session " + id);
			return;
		}

		var obj = typeof json == "string" ? JSON.parse(json) : json;

		var otSess = {
			cursors: {},
			cursorIndices: []
		};

		var client = new ot.Client(obj.rev);
		otSess.client = client;

		client.applyOperation = function(operation) {
			if (_debug) {
				console.log("Applying op " + operation + " to " + id);
			}
			applyOperationToAce(id, operation);
		};
		client.sendOperation = function(revision, operation) {
			if (_debug) {
				console.log("Sending op [" + operation + "](rev " + revision + ") of " + id);
			}
			otSess.lastSentRev = revision;

			// Working around bugs in GMod's JSONToTable..
			var op_json_arr = operation.toJSON();
			var op_json_obj = {};
			for (var k in op_json_arr) {
				op_json_obj[1+parseInt(k)] = op_json_arr[k];
			}

			if ("gaceot" in window) {
				gaceot.Send(id, revision, JSON.stringify(op_json_obj));
			}
		}

		ignoreEditorChanges = true;
		sess.setValue(obj.doc);
		ignoreEditorChanges = false;

		sess.getSelection().on("changeCursor", function(e) {
			if (ignoreEditorChanges) {
				return; // anchored cursor pos on each client handles this
			}

			var range = sess.getSelection().getRange();
			var start = sess.getDocument().positionToIndex(range.start);
			var end = sess.getDocument().positionToIndex(range.end);

			if ("gaceot" in window && "UpdateCursor" in gaceot) {
				gaceot.UpdateCursor(id, start, end);
			}
		});

		otSessions[id] = otSess;
	}

	function operationReceived(json) {
		var obj = json;
		if (typeof obj === "string") {
			obj = JSON.parse(json);
		}

		var id = obj.id;

		var otSess = otSessions[id];
		if (otSess === undefined) {
			console.log("operationReceived on unknown id " + id);
			return;
		}

		var op_arr = obj.op;

		var operation = ot.TextOperation.fromJSON(op_arr);
		if (obj.user == undefined) {
			otSess.client.serverAck();
		}
		else {
			otSess.client.applyServer(operation);
		}
	}

	function operationFromAceChange(id, change) {
		var sess = gaceSessions.getSession(id);

		if (sess === undefined) {
			console.log("trying to subscribe to unknown session " + id);
			return;
		}

		var delta = change.data;

		var action, text;
		if (delta.action == "insertLines" || delta.action == "removeLines") {
			text = delta.lines.join("\n") + "\n";
			action = delta.action.replace("Lines", "");
		}
		else {
			text = delta.text.replace(sess.getDocument().getNewLineCharacter(), '\n');
			action = delta.action.replace("Text", "");
		}

		// Compute doc length BEFORE edit. Could probably be done in a cleaner way
		var lastDocLength = sess.getDocument().getValue().length;
		if (action == "remove") {
			lastDocLength += text.length;
		}
		else {
			lastDocLength -= text.length;
		}

		var start = sess.getDocument().positionToIndex(delta.range.start);
		var restLength = lastDocLength - start;

		if (action == "remove") {
			restLength -= text.length;
		}

		var operation = new ot.TextOperation().retain(start).insert(text).retain(restLength);
		var inverse = new ot.TextOperation().retain(start).delete(text).retain(restLength);

		var ret;

		if (action == "remove") {
			ret = [inverse, operation];
		}
		else {
			ret = [operation, inverse];
		}

		if (_debug) {
			console.log("operationFromAceChange " + delta.action + ": " + text, ret[0].toJSON());
		}

		return ret;
	}
	function sessionChanged(id, change) {
		if (ignoreEditorChanges) { return; }
		if (id === null) { return; }

		var otSess = otSessions[id];
		if (otSess === undefined) {
			//console.log("sessionChanged on unknown id " + id);
			return;
		}

		var pair = operationFromAceChange(id, change);
		var operation = pair[0];

		otSess.client.applyClient(operation);
	}

	// Credits to Firepad
	// https://github.com/firebase/firepad/blob/master/lib/ace-adapter.coffee
	function updateCursor(id, cursorid, start, end) {
		var otSess = otSessions[id];
		if (otSess === undefined) {
			console.log("cursor update on unknown id " + id);
			return;
		}

		var sess = gaceSessions.getSession(id);
		if (sess === undefined) {
			console.log("cursor update unknown session " + id);
			return;
		}

		var cursorIndex = otSess.cursorIndices.indexOf(cursorid);
		if (cursorIndex == -1) {
			cursorIndex = otSess.cursorIndices.push(cursorid) - 1;
		}

		var clazz = "ot-cursor-" + cursorIndex;

		var startPos = sess.getDocument().indexToPosition(start);
		var endPos = sess.getDocument().indexToPosition(end);

		var cursor = new AceRange(startPos.row, startPos.column, endPos.row, endPos.column);

		cursor.clipRows = function() {
			var range = AceRange.prototype.clipRows.apply(this, arguments);
			range.isEmpty = function() { return false; }
			return range;
		}

		cursor.start = sess.getDocument().createAnchor(cursor.start);
		cursor.end = sess.getDocument().createAnchor(cursor.end);
		cursor.id = sess.addMarker(cursor, clazz, "text");

		if (cursorid in otSess.cursors) {
			otSess.cursors[cursorid].start.detach();
			otSess.cursors[cursorid].end.detach();
			sess.removeMarker(otSess.cursors[cursorid].id);
		}

		otSess.cursors[cursorid] = cursor;
	}

	return  {
		debug: debug,
		getSession: function(id) {
			return otSessions[id];
		},
		removeSession: function(id) {
			if(!(id in otSessions)) {
				return;
			}
			delete otSessions[id];

			if ("gaceot" in window) {
				gaceot.UnSubscribe(id);
			}
		},
		isSubscribed: function(id) {
			return id in otSessions;
		},
		subscribe: function(id) {
			if (!("gaceot" in window)) {
				console.log("gaceCollaborate subscribe failed: no gaceot");
				return;
			}
			gaceot.Subscribe(id);
		},
		onSubscribed: onSubscribed,
		operationReceived: operationReceived,
		sessionChanged: sessionChanged,
		updateCursor: updateCursor
	}
})();

editor.on("change", function(e) {
	gaceCollaborate.sessionChanged(gaceSessions.getSessionId(), e);
})

// Ugly hack, required because theme id isn't passed to themeLoaded
var changingToTheme;
editor.renderer.on("themeChange", function(e) {
	changingToTheme = e.theme;
});
editor.renderer.on("themeLoaded", function(e) {
	setTimeout(function() {
		var editorStyle = getComputedStyle(document.querySelector(".ace_editor"));
		var gutterStyle = getComputedStyle(document.querySelector(".ace_gutter"));

		var bgColor = editorStyle.backgroundColor.match(/\d+/g).slice(0,3);
		var fgColor = editorStyle.color.match(/\d+/g).slice(0,3);

		var gutterBgColor = gutterStyle.backgroundColor.match(/\d+/g).slice(0,3);

		if ("gace" in window) {
			gace.ThemeChanged(changingToTheme, bgColor.join(":"), fgColor.join(":"), gutterBgColor.join(":"));
		}
	}, 500);
});

editor.on("changeMode", function(e) {
	if ("gace" in window) {
		gace.ModeChanged(editor.getSession().getMode().$id);
	}
});

function setCustomEditorFontSize(size) {
	document.getElementById('editor').style.fontSize = size + "px";
}

var customFontMap = {
	sourceCodePro: "Source Code Pro",
	inconsolata: "Inconsolata"
};

function setCustomEditorFont(id) {
	var fontName = customFontMap[id];
	if (!fontName) {
		console.log("Invalid font id " + id);
		return;
	}

	var el = document.getElementById("gace-font-" + id);
	if (!el) {
		var link = document.createElement("link");
		link.setAttribute("rel", "stylesheet");
		link.setAttribute("type", "text/css");
		link.setAttribute("href", "http://fonts.googleapis.com/css?family=" + encodeURIComponent(fontName));
		link.setAttribute("id", "gace-font-" + id);
		document.body.appendChild(link);
	}

	document.getElementById('editor').style.fontFamily = fontName;
}

document.addEventListener('DOMContentLoaded', function() {
	if ("gace" in window) {
		gace.EditorReady();
	} else {
		// we're debugging
		gaceSessions.setSession("debug.lua", {});
	}
});