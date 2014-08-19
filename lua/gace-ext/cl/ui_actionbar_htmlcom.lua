gace.AddHook("AddActionBarComponents", "ActionBar_HTMLCommunication", function(comps)
	
	comps:AddComponent { text = "Editor", width = 35 },
	comps:AddComponent {
		text = "Settings",
		fn = function()
			gace.RunEditorJS("editor.showSettingsMenu();")
		end
	}
	comps:AddComponent {
		text = "Shortcuts",
		fn = function()
			gace.RunEditorJS("editor.showKeyboardShortcuts();")
		end,
		width = 75
	}
	comps:AddComponent {
		text = "Theme",
		fn = function()
			local menu = DermaMenu()

			local c_theme = cookie.GetString("gace-theme", "ace/theme/tomorrow_night") or "ace/theme/tomorrow_night"
			local theme_name = c_theme:Split("/")[3]

			for _,theme in pairs(gace.AvailableThemes) do
				local opt = menu:AddOption(theme, function() gace.RunEditorJS("editor.setTheme('ace/theme/" .. theme .. "')") end)
				if theme_name == theme then
					opt:SetChecked(true)
				end
			end
			menu:Open()
		end
	}
	comps:AddComponent {
		text = "Mode",
		fn = function()
			local menu = DermaMenu()

			local modes = {
				"abap", "actionscript", "ada", "apache_conf", "asciidoc", "assembly_x86", "autohotkey",
				"batchfile", "c9search", "c_cpp", "clojure", "cobol", "coffee", "coldfusion", "csharp",
				"css", "curly", "d", "dart", "diff", "django", "dot", "ejs", "erlang", "forth", "ftl",
				"glsl", "glua", "golang", "groovy", "haml", "handlebars", "haskell", "haxe", "html", "ini",
				"jack", "jade", "java", "javascript", "json","jsoniq", "jsp", "jsx", "julia", "latex", "less",
				"liquid", "lisp", "livescript", "logiql", "lsl", "lua", "luapage", "lucene", "makefile", "markdown",
				"matlab", "mel", "mushcode", "mysql", "nix", "objectivec", "ocaml", "pascal", "perl", "pgsql", "php",
				"plain_text", "powershell", "prolog", "properties", "protobuf", "python", "r", "rdoc", "rhtml", "ruby",
				"rust", "sass", "scad", "scala", "scheme", "scss", "sh", "sjs", "snippets", "soy_template", "space",
				"sql", "stylus", "svg", "tcl", "tex", "text", "textile", "tmsnippet", "toml", "twig", "typescript",
				"vbscript", "velocity", "verilog", "vhdl", "xml", "xquery", "yaml",
			}

			for _,mode in pairs(modes) do
				local mode2 = "ace/mode/" .. mode
				local opt = menu:AddOption(mode, function() gace.RunEditorJS("editor.getSession().setMode('" .. mode2 .. "')") end)
				if gace.GetSessionMode() == mode2 then
					opt:SetChecked(true)
				end
			end
			menu:Open()
		end
	}
end)