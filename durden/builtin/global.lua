--
-- Globally available menus, settings and functions. All code here is just
-- boiler-plate mapping to engine- or support script functions.
--

local function global_valid01_uri(str)
	return true;
end

local function display_rescan()
	video_displaymodes();
end

local function query_synch()
	local lst = video_synchronization();
	if (lst) then
		local res = {};
-- dynamically populated so we don't expose this globally at the moment
		for k,v in ipairs(lst) do
			res[k] = {
				name = "set_synch_" .. tostring(k),
				label = v,
				kind = "action",
				handler = function(ctx)
					video_synchronization(v);
				end
			};
		end
		launch_menu(displays.main, {list = res}, true, "Synchronization:");
	end
end

local display_menu = {
	{
		name = "list_displays",
		label = "Displays",
		kind = "action",
		submenu = true,
		handler = function(ctx)
			warning("enum known displays, list here with dynamic handler to " ..
	"enable / disable or switch resolution");
		end
	},
	{
		name = "display_rescan",
		label = "Rescan",
		kind = "action",
		submenu = false,
		handler = function(ctx)
			video_displaymodes();
		end
	},
	{
		name = "synchronization_strategies",
		label = "Synchronization",
		kind = "action",
		submenu = true,
		handler = function(ctx)
			query_synch();
		end
	},
};

local function query_exit()
	launch_menu(displays.main, {list = {
		{
			name = "shutdown_no",
			label = "No",
			kind = "action",
			handler = function() end
		},
		{
			name = "shutdown_yes",
			label = "Yes",
			kind = "action",
			handler = function() shutdown(); end
		}
	}}, true, "Shutdown?");
end

local function query_reset()
	launch_menu(displays.main, {list = {
		{
			name = "reset_no",
			label = "No",
			kind = "action",
			handler = function() end
		},
		{
			name = "reset_yes",
			label = "Yes",
			kind = "action",
			handler = function() system_collapse(APPLID); end
		},
	}}, true, "Reset?");
end

local function query_dump()
	local bar = tiler_lbar(displays.main, function(ctx, msg, done, set)
		if (done) then
			zap_resource("debug/" .. msg);
			system_snapshot("debug/" .. msg);
		end
		return {};
	end);
	bar:set_label("filename (debug/):");
end

local debug_menu = {
	{
		name = "query_dump",
		label = "Dump State",
		kind = "action",
		handler = query_dump
	}
};

local function show_debugmenu()
	launch_menu(displays.main, {list = debug_menu}, true, "Debug:");
end

local system_menu = {
	{
		name = "shutdown",
		label = "Shutdown",
		kind = "action",
		handler = query_exit
	},
	{
		name = "reset",
		label = "Reset",
		kind = "action",
		handler = query_reset
	},
	{
		name = "debug",
		label = "Debug",
		kind = "action",
		submenu = true,
		handler = show_debugmenu
	}
};

local function show_displaymenu()
	launch_menu(displays.main, {list = display_menu}, true, "Displays:");
end

local function show_systemmenu()
	launch_menu(displays.main, {list = system_menu}, true, "System:");
end

local input_menu = {
	{
		name = "input_rebind_basic",
		label = "Rebind Basic",
		handler = function()
			warning("redo query scheme");
		end
	},
	{
		name = "input_binding_window",
		label = "Bindings Window",
		handler = function()
			warning("spawn binding- window");
		end
	},
	{
		name = "input_save_layout",
		label = "Save Current",
		handler = function()
			warning("query current- save");
		end
	},
	{
		name = "input_keyboard",
		label = "Keyboard",
		submenu = true,
		handler = function()
			warning("keyboard menu");
-- really just repeat- rate we're interested in(?!)
		end
	},
	{
		name = "input_devices",
		label = "Devices",
		submenu = true,
		handler = function()
			warning("input devices menu");
-- match [ inputanalog_query(num, ax, scan), empty gives table ]
-- each device [toggle on / off], filtering requires calibration window
		end,
	},
	{
		name = "mouse",
		label = "Mouse",
		submenu = true,
		handler = function()
			warning("mouse menu");
-- focus follow mouse
-- acceleration rate
-- reverse buttons
-- flip y axis
-- flip x axis
-- drag traction
-- dblclick interval
		end
	},
	{
		name = "load_layout",
		label = "Load Layout",
		submenu = true,
		handler = function()
			warning("list / browse layout");
		end
	},
};

local function show_inputmenu()
	launch_menu(displays.main, {list = input_menu}, true, "Input:");
end
-- workspace actions:
-- 	swap, background, layout (save, load), display affinity,
-- 	reassign (if multiple displays), layout, share

local function switch_ws_menu()
	local spaces = {};
	for i=1,10 do
		spaces[i] = {
			name = "switch_ws" .. tostring(i),
			kind = "action",
			label = tostring(i),
			handler = grab_global_function("switch_ws" .. tostring(i)),
		};
	end

	launch_menu(displays.main, {list = spaces}, true, "Switch Space:");
end

local workspace_layout_menu = {
	{
		name = "layout_float",
		kind = "action",
		label = "Float",
		handler = function()
			local space = displays.main.spaces[displays.main.space_ind];
			space = space and space:float() or nil;
		end
	},
	{
		name = "layout_tile",
		kind = "action",
		label = "Tile",
		handler = function()
			local space = displays.main.spaces[displays.main.space_ind];
			space = space and space:tile() or nil;
		end
	},
	{
		name = "layout_tab",
		kind = "action",
		label = "Tabbed",
		handler = function()
			local space = displays.main.spaces[displays.main.space_ind];
			space = space and space:tab() or nil;
		end
	},
	{
		name = "layout_vtab",
		kind = "action",
		label = "Tabbed Vertical",
		handler = function()
			local space = displays.main.spaces[displays.main.space_ind];
			space = space and space:vtab() or nil;
		end
	}
};

local function show_workspace_layout_menu()
	launch_menu(displays.main, {list = workspace_layout_menu}, true, "Layout:");
end

local function set_ws_background()
--	browse_file({"png"}, SHARED_RESOURCE, function(fn)
--		local space = displays.main.spaces[displays.main.space_ind];
--		if (space) then
--			local vid = load_image_asynch(fn, function() end);
--		end
--	end);
end

local workspace_menu = {
	{
		name = "workspace_layout",
		label = "Layout",
		kind = "action",
		submenu = true,
		handler = show_workspace_layout_menu
	},
	{
		name = "workspace_background",
		label = "Background",
		kind = "action",
		submenu = true,
		handler = set_ws_background,
	},
	{
		name = "workspace_rename",
		label = "Rename",
		kind = "action",
		handler = grab_global_function("rename_space")
	},
	{
		name = "workspace_switch",
		label = "Switch",
		kind = "action",
		submenu = true,
		handler = switch_ws_menu
	},
};

local function show_workspacemenu()
	launch_menu(displays.main, {list = workspace_menu}, true, "Workspace:");
end

-- Stub for now
local toplevel = {
	{
		name = "open",
		label = "Open",
		kind = "string",
		validator = global_valid01_uri,
		handler = function(ctx, value)
		end
	},
	{
		name = "workspace",
		label = "Workspace",
		kind = "action",
		submenu = true,
		handler = show_workspacemenu
	},
	{
		name = "display",
		label = "Display",
		kind = "action",
		submenu = true,
		handler = show_displaymenu,
	},
	{
		name = "audio",
		label = "Audio",
		kind = "action",
		submenu = true,
		handler = function(ctx, value)
			warning("spawn audio menu");
		end
	},
	{
		name = "input",
		label = "Input",
		kind = "action",
		submenu = true,
		handler = show_inputmenu
	},
	{
		name = "system",
		label = "System",
		kind = "action",
		submenu = true,
		handler = show_systemmenu
	},
};

local function global_actions()
	launch_menu(displays.main, {list = toplevel}, true, "Action:");
end

register_global("global_actions", global_actions);

-- audio
register_global("audio_mute_all", audio_mute);

--display
register_global("display_rescan", display_rescan);
register_global("query_synch", display_synch);

--system
register_global("query_exit", query_exit);
register_global("exit", shutdown);
register_global("query_reset", query_reset);
register_global("reset", function() system_collapse(APPLID); end);
