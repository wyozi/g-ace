gace.AddHook("AddActionBarComponents", "ActionBar_AceEditor", function(comps)

	comps:AddCategory("Editor", Color(230, 126, 34))
	comps:AddComponent {
		text = "Ace- editor",
		width = 100,
		fn = function()
			local menu = DermaMenu()

			menu:AddOption("Settings", function() gace.JSBridge().editor.showSettingsMenu() end):SetIcon("icon16/wrench.png")
			menu:AddOption("Shortcuts", function() gace.JSBridge().editor.showKeyboardShortcuts() end):SetIcon("icon16/keyboard.png")

			local csubmenu, csmpnl = menu:AddSubMenu("Set theme", function() end)
			csmpnl:SetIcon("icon16/map.png")
			do
				local c_theme = cookie.GetString("gace-theme", "ace/theme/tomorrow_night") or "ace/theme/tomorrow_night"
				local theme_name = c_theme:Split("/")[3]

				for _,theme in pairs(gace.AvailableThemes) do
					local opt = csubmenu:AddOption(theme, function() gace.JSBridge().editor.setTheme("ace/theme/" .. theme) end)
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
					local opt = csubmenu:AddOption(mode, function() gace.JSBridge().editor.session.setMode(mode) end)
				end
			end

			local csubmenu, csmpnl = menu:AddSubMenu("Font Family", function() end)
			csmpnl:SetIcon("icon16/font.png")
			do
				local fonts = {
					"sourceCodePro",
					"inconsolata"
				}

				for _,font in pairs(fonts) do
					local opt = csubmenu:AddOption(font, function()
						gace.JSBridge().setCustomEditorFont(font)
						cookie.Set("gace-font", font)
					end)
				end
			end

			local csubmenu, csmpnl = menu:AddSubMenu("Font Size", function() end)
			csmpnl:SetIcon("icon16/text_smallcaps.png")
			do
				for s=10, 22 do
					local opt = csubmenu:AddOption(tostring(s), function()
						gace.JSBridge().setCustomEditorFontSize(s)
						cookie.Set("gace-fontSize", s)
					end)
				end
			end

			menu:Open()

		end
	}

	comps:AddCategoryEnd()
end)
