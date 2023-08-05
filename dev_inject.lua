-- add some missing global variables to make it easier to find actual problems in the log files

-- ArtSpecConfig
ArtSpecConfig = rawget(_G, "ArtSpecConfig") or { ["ArtSets"] = {} }

--[LUA ERROR] Attempt to use an undefined global 'LuaReloadRequest'
--C:\Program Files (x86)\Steam\steamapps\common\Jagged Alliance 3\CommonLua\Core\lib.lua(2178):  <>
LuaReloadRequest = false


-- launch with -dev to use dev_inject
local dev = string.match(GetAppCmdLine() or "", "-dev")

-- greet or exit
if not dev then
	print("MODE: NOT DEV_INJECT")
	goto exit
else
	print("MODE: DEV_INJECT")
end

-- globals
loaded_files = rawget(_G, "loaded_files") or {}
fetched_lua_source = {}
msg_log = {}
dev_applied = rawget(_G, "dev_applied") or {}

-- locals
local dev_setup_xtemplates = nil

-- dev log directory path
dev_log_dir = "C:\\Users\\<username>\\AppData\\Roaming\\Jagged Alliance 3\\logs_dev\\" -- <---- CHANGE THIS

-- decompiled lua directory path
local_files_path = "C:/JA3/1.03/Lua_hpk/Decompiled/" -- <---- CHANGE THIS

-- use local unpacked versions of these files and folders 
use_local_files = {
	--"CommonLua/Ged.lua",
	--"CommonLua/Ged/XTemplates/*",
}

-- skip use local files for these files
-- absolute paths
replace_files = {
	["CommonLua/Core/luadebugger.lua"] = "dev_luadebugger.lua"
}

-- adds files from directory wildcards to use_local_files
for i = #use_local_files, 1, -1 do
	local name = use_local_files[i]
	if string.ends_with(name, "/*") then
		local files = io.listfiles(local_files_path .. string.sub(name, 1, #name - 1), "*.lua", "non recursive")
		for _, f in ipairs(files) do
			table.insert(use_local_files, string.sub(f, #local_files_path + 1))
		end
		table.remove(use_local_files, i)
	end
end

-- return local path for files in use_local_files
function modify_loading_path(name)
	if replace_files[name] then
		name = replace_files[name]
	elseif table.find(use_local_files, name) then
		name = local_files_path .. name
	end

	return name
end

-- callback when msg have called all staticfunc
function dev_onmsg_after_last(message, ...)
	if message == "ModsReloaded" then
		-- inc console history
		const.nConsoleHistoryMaxSize = 500
	elseif message == "Autorun" then
		-- force load files that could not be replaced
		for k, v in pairs(replace_files) do
			if loaded_files[v] == nil then
				dofile(v)
			end
		end

		-- break the console sandbox
		g_ConsoleFENV = {__run = g_ConsoleFENV.__run, hello = true}
		setmetatable(g_ConsoleFENV, {
			__index = function(_, key)
				return rawget(_G, key)
			end,
			__newindex = function(_, key, value)
				rawset(_G, key, value)
			end
		})

		-- setup xtemplates
		--if string.ends_with(name, "CommonLua/Ged/XTemplates/ModManager.lua") then
			dev_setup_xtemplates()
		--end
	end
end

-- called after each source file is loaded
-- lets us modify stuff in each file before subsequent files are loaded
function dev_file_was_loaded(name)
	-- if you want to check which file paths are loaded in console
	table.insert(loaded_files, name)

	-- hook dofile functions after CommonLua/Core/lib.lua
	if string.ends_with(name, "CommonLua/Core/lib.lua") then
		dofile = dofile_new
		pdofile = pdofile_new
	end

	-- hook preset loading functions
	if string.ends_with(name, "CommonLua/Preset.lua") then
		local instrument_loading_new = function(fn_name)
			return function(...)
				local old_fn = dofile
				function dofile(name, fenv)
					name = modify_loading_path(name)
					PresetsLoadingFileName = name
					old_fn(name, fenv)
					PresetsLoadingFileName = false
				end
				_G[fn_name](...)
				dofile = old_fn
			end
		end
		LoadPresetFiles = instrument_loading_new("dofolder_files")
		LoadPresetFolders = instrument_loading_new("dofolder_folders")
		LoadPresetFolder = instrument_loading_new("dofolder")
		LoadPresets = function (name, fenv)
			name = modify_loading_path(name)
			PresetsLoadingFileName = name
			pdofile(name, fenv)
			PresetsLoadingFileName = false
		end
	end

	-- add tag support to mod editor
	if string.ends_with(name, "Lua/Mod.lua") then
		PredefinedModTags = {
			{ id = "TagBalancing", display_name = "Balancing" },
			{ id = "TagGameSettings", display_name = "Game Settings" },
			{ id = "TagIMPCharacter", display_name = "IMP Character" },
			{ id = "TagLocalization", display_name = "Localization" },
			{ id = "TagMercs", display_name = "Mercs"},
			{ id = "TagMines", display_name = "Mines" },
			{ id = "TagOther", display_name = "Other"},
			{ id = "TagUI", display_name = "UI" },
			{ id = "TagWeapons&Items", display_name = "Weapons & Items"}
		}
	end

	-- add sub-category and enabled_if to ModItemOption
	if string.ends_with(name, "CommonLua/Classes/Mod.lua") then
		AppendClass.ModItemOption = {
			properties = {
				{
					id = "SubCategory",
					name = "Sub-Category",
					editor = "text",
					translate = false,
					default = false
				},
				{
					id = "enabled_if",
					name = "Enabled If",
					editor = "func",
					params = "options",
					default = false
				},
			}
		}

		-- add tag support to mod editor
		AppendClass.ModDef = {
			properties = {
				{
					category = "Tags",
					id = "TagBalancing",
					name = "Balancing",
					editor = "bool",
					default = false
				},
				{
					category = "Tags",
					id = "TagGameSettings",
					name = "Game Settings",
					editor = "bool",
					default = false
				},
				{
					category = "Tags",
					id = "TagIMPCharacter",
					name = "IMP Character",
					editor = "bool",
					default = false
				},
				{
					category = "Tags",
					id = "TagLocalization",
					name = "Localization",
					editor = "bool",
					default = false
				},
				{
					category = "Tags",
					id = "TagMercs",
					name = "Mercs",
					editor = "bool",
					default = false
				},
				{
					category = "Tags",
					id = "TagMines",
					name = "Mines",
					editor = "bool",
					default = false
				},
				{
					category = "Tags",
					id = "TagOther",
					name = "Other",
					editor = "bool",
					default = false
				},
				{
					category = "Tags",
					id = "TagUI",
					name = "UI",
					editor = "bool",
					default = false
				},
				{
					category = "Tags",
					id = "TagWeapons&Items",
					name = "Weapons & Items",
					editor = "bool",
					default = false
				}
			}
		}
	end

	-- hook msg handler
	if string.ends_with(name, "CommonLua/Core/cthreads.lua") then
		local Msg_old = Msg
		function Msg(message, ...)
			-- save to msg log
			if type(message) == "string" then
				msg_log[message] = (msg_log[message] or 0) + 1
			end

			Msg_old(message, ...)

			dev_onmsg_after_last(message, ...)
		end
	end

	-- modify FetchLuaSource to use local paths
	if string.ends_with(name, "CommonLua/Core/ToLuaCode.lua") then
		FetchLuaSource_old = FetchLuaSource
		FetchLuaSource = function(file_name)
			local use_local = false
			if io.exists(local_files_path .. file_name) then
				file_name = local_files_path .. file_name
				use_local = true
			end

			fetched_lua_source = rawget(_G, "fetched_lua_source") or {}
			table.insert(fetched_lua_source, { ["file_name"] = file_name, ["use_local"] = use_local})

			return FetchLuaSource_old(file_name)
		end
	end
end


-- dofile helpers
local parse_error = function(err)
	local file, line, err = string.match(tostring(err), "(.-%.lua):(%d+): (.*)")
	if file and line and io.exists(file) then
		return file, line, err
	end
end

local procall_helper = function(ok, ...)
	if not ok then
		return
	end
	return ...
end

-- store old
dofile_old = dofile

-- dofile functions
pdofile_new = function(name, fenv, mode)
	name = modify_loading_path(name)

	local func, err = loadfile(name, mode, fenv or _ENV)
	if not func then
		return false, err
	end
	local result, err = pcall(func)

	dev_file_was_loaded(name)

	return result, err
end

dofile_new = function(name, fenv)
	name = modify_loading_path(name)

	local func, err = loadfile(name, nil, fenv or _ENV)
	if not func then
		local parsed_err = parse_error(err)
		syntax_error(err, parsed_err)
		if parsed_err and GetIgnoreDebugErrors() then
			syntax_error(string.format("[Compile Error]: Lua compilation error in '%s'!", name))
			FlushLogFile()
			quit(1)
		end
		return
	end
	local result = procall_helper(procall(func))

	dev_file_was_loaded(name)

	return result
end

dofile_temp = function(name)
	name = modify_loading_path(name)

	local result = dofile_old(name)

	dev_file_was_loaded(name)

	return result
end

-- hook dofile before override in CommonLua/Core/lib.lua
dofile = dofile_temp


-- setup dev and set console always enabled
local DevUpdateThread = CreateRealTimeThread(function()
	while true do
		if Platform.ged == true then
			Platform.developer = true
			Platform.goldmaster = false

			-- not 100 sure why these setting are the way they are
			if rawget(_G, "config") then
				config.ConsoleDim = 0
			end

			if not ConsoleEnabled then
				ConsoleSetEnabled(true)
			end
		else
			Platform.developer = true

			-- not 100 sure why these setting are the way they are
			ConsoleEnabled = true
			if not rawget(_G, "dlgConsole") then
				CreateConsole()
			end
			
			--ShowConsoleLog(true)
		end

		Sleep(500)
	end
end)

-- make table
local function dev_make_table(...)
	local result = {}
	for _, v in ipairs(table.pack(...)) do
		if type(v) == "table" then
			for _, v2 in ipairs(v) do
				result[#result + 1] = v2   
			end
		else
			result[#result + 1] = v
		end
	end

	return result
end

-- xtemplate find elements
function dev_XTemplate_FindElementsByProp(curr, prop, value, multi, ancestors, indices)
	local results = {}

	if type(curr) ~= "table" then
		return false
	end

	if curr[prop] and curr[prop] == value then
		local r = { ["element"] = curr, ["ancestors"] = ancestors, ["indices"] = indices }
		if multi == "all" then
			results = { r }
		else
			return multi == "first_on_branch" and { r } or r
		end
	end

	if curr[1] then
		local new_ancestors = dev_make_table({ curr }, ancestors and ancestors or nil)
		for i, v in ipairs(curr) do
			local new_indices = dev_make_table({ i }, indices and indices or nil)
			local result = dev_XTemplate_FindElementsByProp(v, prop, value, multi, new_ancestors, new_indices)
			if result ~= false then
				if multi then
					for i, r in ipairs(result) do
						table.insert(results, r)
					end
				else
					return result
				end
			end
		end
	end

	return multi and #results > 0 and results or false
end

-- setup xtemplates
dev_setup_xtemplates = function()
	-- add console hotkey to ged apps
	if Platform.ged == true then
		if dev_applied["GedApps"] ~= true then
			-- only modify once
			dev_applied["GedApps"] = true

			for k, v in pairs(XTemplates) do
				if v.group == "GedApps" then
		
					local x_mm_file = dev_XTemplate_FindElementsByProp(v, "__class", "GedApp")

					if x_mm_file.element ~= nil then
						table.insert(x_mm_file.element, PlaceObj("XTemplateAction", {
							"ActionId",
							"Console",
							"ActionName",
							"Console",
							"ActionToolbar",
							"main",
							"ActionShortcut",
							"Ctrl-C",
							"ActionShortcut2",
							"Alt-Enter",
							"ActionState",
							function(self, host)
							return "hidden"
							end,
							"OnAction",
							function(self, host, source, ...)
								local show = rawget(_G, "dlgConsoleLog") and not dlgConsoleLog:IsVisible() or true
								ShowConsole(show)
							end,
							"ActionContexts",
							{
							"ChildActions"
							}
						})
						)
					end
				end
			end
		end
	end

	-- devlog template
	PlaceObj('XTemplate', {
		__is_kind_of = "XDialog",
		id = "DevDebug1",
		PlaceObj('XTemplateWindow', {
			'__class', "XDialog",
			'Padding', box(64, 32, 64, 32),
			'LayoutMethod', "VList",
		}, {
			PlaceObj('XTemplateWindow', {
				'Padding', box(8, 8, 8, 8),
				'HAlign', "center",
				'VAlign', "center",
				'MaxWidth', 1400,
				'Background', RGBA(32, 35, 47, 233),
			}, {
				PlaceObj('XTemplateWindow', {
					'__class', "MessengerScrollbar",
					'Id', "idOutputScroll",
					'ZOrder', 2,
					'Margins', box(0, 0, 0, 0),
					'Dock', "right",
					'AutoHide', true,
					'Target', "idOutputText",
				}),
				PlaceObj('XTemplateWindow', {
					'__class', "MessengerScrollbarHorizontal",
					'Id', "idOutputScrollH",
					'ZOrder', 2,
					'Margins', box(0, 0, 0, 0),
					'Dock', "bottom",
					'AutoHide', true,
					'Target', "idOutputText",
				}),
				PlaceObj('XTemplateWindow', {
					'__class', "XMultiLineEdit",
					'Id', "idOutputText",
					'Padding', box(8, 4, 8, 8),
					'MinWidth', 800,
					'MinHeight', 500,
					'MaxWidth', 1400,
					'MaxHeight', 800,
					'HScroll', "idOutputScrollH",
					'VScroll', "idOutputScroll",
					'TextStyle', "GedConsole",
					'AllowTabs', true,
					'MinVisibleLines', 50,
					'MaxVisibleLines', 50,
					'MaxLines', 100000,
					'MaxLen', 655360,
				}, {
					PlaceObj("XTemplateFunc", {
					  "name",
					  "Open(self, ...)",
					  "func",
					  function(self, ...)
					  end
					})
				}),
				}),
			PlaceObj('XTemplateWindow', {
				'__class', "XToolBar",
				'Id', "idToolbar",
				'BorderWidth', 1,
				'Padding', box(4, 0, 4, 0),
				'Dock', "bottom",
				'HAlign', "center",
				'VAlign', "bottom",
				'MinWidth', 80,
				'MinHeight', 40,
				'LayoutHSpacing', 40,
				'BorderColor', RGBA(0, 0, 0, 0),
				'Background', RGBA(52, 55, 61, 0),
				'Toolbar', "Toolbar",
				'ButtonTemplate', "PDACommonButtonClass",
				'ToolbarSectionTemplate', "",
			}),
			PlaceObj('XTemplateAction', {
				'ActionId', "idClose",
				'ActionName', T(849468960409, --[[ModItemXTemplate DevDebug1 ActionName]] "Close"),
				'ActionToolbar', "Toolbar",
				'ActionShortcut', "Escape",
				'ActionGamepad', "ButtonB",
				'OnActionEffect', "close",
			}),
			PlaceObj('XTemplateAction', {
				'ActionId', "idRun",
				'ActionName', "Run",
				'ActionToolbar', "Toolbar",
				'OnAction', function (self, host, source, ...)
					local str = host:ResolveId("idOutputText"):GetText()
					if dlgConsole then
						dlgConsole:Exec(str)
					end
				end,
			}),
			}),
	})

	-- dev hotkeys
	table.insert(XTemplates.GameShortcuts, PlaceObj('XTemplateAction', {
		'comment', "Show/Hide the User Actions menu",
		'ActionId', "DevMod_actionIdToggleUserActionsMenu",
		'ActionSortKey', "9000",
		'ActionName', "Show/Hide the User Actions menu",
		'ActionDescription', "",
		'ActionShortcut', "Alt-Shift-U",
		'OnAction', function(self, host, source, ...)
			if IsEditorActive() then
			XShortcutsTarget:FocusSearch()
			else
			XShortcutsTarget:Toggle()
			end
		  end,
		'IgnoreRepeated', true,
		'replace_matching_id', true,
	}))
	
	table.insert(XTemplates.GameShortcuts, PlaceObj('XTemplateAction', {
		'comment', "Open Console",
		'ActionId', "DevMod_actionIdOpenConsole",
		'ActionSortKey', "9001",
		'ActionName', "Open Console",
		'ActionDescription', "",
		'ActionShortcut', "Alt-Shift-C",
		'OnAction', function(self, host, source, ...)
			ConsoleEnabled = true
			if not rawget(_G, "dlgConsole") then
				CreateConsole()
			end
			if rawget(_G, "dlgConsole") then
				dlgConsole:Show(true)
			end
	
			ShowConsoleLog(true)
		  end,
		'IgnoreRepeated', true,
		'replace_matching_id', true,
	}))
	
	table.insert(XTemplates.GameShortcuts, PlaceObj('XTemplateAction', {
		'comment', "Open XWindow Inspector",
		'ActionId', "DevMod_actionIdOpenXWindowInspector",
		'ActionSortKey', "9002",
		'ActionName', "Open XWindow Inspector",
		'ActionDescription', "",
		'ActionShortcut', "Alt-Shift-I",
		'OnAction', function(self, host, source, ...)
			OpenXWindowInspector()
		  end,
		'IgnoreRepeated', true,
		'replace_matching_id', true,
	}))
	
	table.insert(XTemplates.GameShortcuts, PlaceObj('XTemplateAction', {
		'comment', "Open Mod Manager",
		'ActionId', "DevMod_actionIdOpenModManager",
		'ActionSortKey', "9003",
		'ActionName', "Open Mod Manager",
		'ActionDescription', "",
		'ActionShortcut', "Alt-Shift-M",
		'OnAction', function(self, host, source, ...)
			ModEditorOpen()
		  end,
		'IgnoreRepeated', true,
		'replace_matching_id', true,
	}))
end

-- log to dev log
function DevLog(code, levels, charsperline)
	levels = levels or 3
	charsperline = charsperline or 175

	if not GetDialog("DevDebug1") then
		OpenDialog("DevDebug1")
	end
	local dialog = GetDialog("DevDebug1")
	dialog.ZOrder = 20000000

	if type(code) == "table" then
		dialog.idOutputText:SetText(table.format(code, levels, charsperline))
	else
		dialog.idOutputText:SetText(print_format(code))
	end
end

-- log anything to file
-- LogToFile(log_name, data, levels, charsperline)
-- LogToFile(data, levels, charsperline)
function LogToFile(...)
	local args = table.pack(...)
	local data = nil
	local name = "log"
	local levels = 3
	local charsperline = 175
	if #args >= 2 and type(args[1]) == "string" and type(args[2]) ~= "number" then
		name = args[1]
		data = args[2]
		levels = args[3] or levels
		charsperline = args[4] or levels
	else
		data = args[1]
		levels = args[2] or levels
		charsperline = args[3] or levels
	end

	local str = ""
	if type(data) == "string" then
		str = data
	elseif type(data) == "table" then
		str = table.format(data, levels, charsperline)
	else
		str = print_format(data)
	end

	local filename = ""
	local exists = true
	local i = 1
	while exists and (i < 100) do
		local suffix = "_" .. i
		if i == 1 then
			suffix = ""
		end
		filename = string.format("%s_%s%s", name, os.date("%Y_%m_%d_%H_%M_%S"), suffix)
		exists = io.exists(dev_log_dir .. filename .. ".txt")
		i = i + 1
	end
	
	local err = AsyncStringToFile(dev_log_dir .. filename .. ".txt", str)
	if err then
		print("Failed to save log:", err)
	else
		print("Log saved:", dev_log_dir .. filename .. ".txt")
	end
end

-- define tracing
Tracing = rawget(_G, "Tracing") or {}
Tracing.Log = Tracing.Log or {}

-- callback, logs to Tracing.Log table
function Tracing.Trace(event)
	local args_str = ""
	local func_name = debug.getinfo(2, 'n').name
	local source = debug.getinfo(2, 'S').source
	local line = debug.getinfo(2, 'l').currentline

	local nparams = debug.getinfo(2).nparams
	if nparams >= 1 then
		for i = 1, nparams do
		local ln, lv = debug.getlocal(2, i)
		local param = ln .. ((ln == "self") and "" or ("=" .. tostring(lv)))
		args_str = args_str .. ((i > 1) and ", " or "") .. param
		end
	end
	if #args_str > 0 then
		args_str = " [" .. args_str .. "]"
	end
	local s = string.format("%s:%s:%s%s", source, line, func_name, args_str)
	table.insert(Tracing.Log, s)
end

-- trace calls for a set delay
function Tracing.TraceFor(seconds)
	debug.sethook(Tracing.Trace, "c")

	DelayedCall(seconds * 1000, function()
		Tracing.RemoveHook()
		Tracing.SaveLog()
	end)
end

-- set hook on call
function Tracing.SetHook()
	debug.sethook(Tracing.Trace, "c")
end

-- remove a prev set hook
function Tracing.RemoveHook()
	debug.sethook()
end

-- save logged calls
function Tracing.SaveLog()
	LogToFile(table.concat(Tracing.Log, "\n"))
end




::exit::