gace.AddHook("AddActionBarComponents", "ActionBar_HTMLCommunication", function(comps)

	comps:AddCategory("Editor", Color(230, 126, 34))
	comps:AddComponent {
		text = "Ace- editor",
		width = 100,
		fn = function()
			local menu = DermaMenu()

			menu:AddOption("Settings", function() gace.RunJavascript("editor.showSettingsMenu();") end):SetIcon("icon16/wrench.png")
			menu:AddOption("Shortcuts", function() gace.RunJavascript("editor.showKeyboardShortcuts();") end):SetIcon("icon16/keyboard.png")

			local csubmenu, csmpnl = menu:AddSubMenu("Set theme", function() end)
			csmpnl:SetIcon("icon16/map.png")
			do
				local c_theme = cookie.GetString("gace-theme", "ace/theme/tomorrow_night") or "ace/theme/tomorrow_night"
				local theme_name = c_theme:Split("/")[3]

				for _,theme in pairs(gace.AvailableThemes) do
					local opt = csubmenu:AddOption(theme, function() gace.RunJavascript("editor.setTheme('ace/theme/" .. theme .. "')") end)
					if theme_name == theme then
						opt:SetChecked(true)
					end
				end
			end

			local csubmenu, csmpnl = menu:AddSubMenu("Set mode", function() end)
			csmpnl:SetIcon("icon16/page_white_code.png")
			do
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
					local opt = csubmenu:AddOption(mode, function() gace.RunJavascript("editor.getSession().setMode('" .. mode2 .. "')") end)
				end
			end

			menu:Open()

		end
	}

	comps:AddCategoryEnd()
end)
