--
-- Menus and fglobal registration for functions that are shared between all
-- windows that has an external connection. Additional ones can be superimposed
-- based on archetype or even windows identification for entirely custom
-- handling (integrating senseye sensors for instance).
--

local function shared_valid01_float(inv)
	if (string.len(inv) == 0) then
		return true;
	end

	local val = tonumber(inv);
	return val and (val >= 0.0 and val <= 1.0) or false;
end

local function shared_reset(wnd)
	if (wnd.external) then
		reset_target(wnd.external);
	end
end

local function shared_resume(wnd)
	if (wnd.external) then
		resume_target(wnd.external);
	end
end

local function shared_suspend(wnd)
	if (wnd.external) then
		suspend_target(wnd.external);
	end
end

local function gain_stepv(gainv, abs)
	local wnd = displays.main.selected;
	if (not wnd or not wnd.source_audio) then
		return;
	end

	if (not abs) then
		gainv = gainv + (wnd.source_gain and wnd.source_gain or 1.0);
	end

	gainv = gainv < 0.0 and 0.0 or gainv;
	gainv = gainv > 1.0 and 1.0 or gainv;
	wnd.source_gain = gainv;
	audio_gain(wnd.source_audio, gconfig_get("global_gain") * gainv,
		gconfig_get("gain_fade"));
end

local audio_menu = {
	{
		name = "target_audio",
		label = "Toggle On/Off",
		kind = "action",
		handler = toggle_audio
	},
	{
		name = "gain_add10",
		label = "+10%",
		kind = "action",
		handler = function() gain_stepv(0.1); end
	},
	{
		name = "gain_sub10",
		label = "-10%",
		kind = "action",
		handler = function() gain_stepv(-0.1); end
	},
	{
		name ="target_audio_gain",
		label = "Gain",
		hint = "(0..1)",
		kind = "value",
		validator = shared_valid01_float,
		handler = function(ctx, val) gain_stepv(tonumber(val), true); end
	},
};

local function set_scalef(mode)
	local wnd = displays.main.selected;
	if (wnd) then
		wnd.scalemode = mode;
		wnd.settings.scalemode = mode;
		wnd:resize(wnd.width, wnd.height);
	end
end

local function set_filterm(mode)
	local wnd = displays.main.selected;
	if (mode and wnd) then
		wnd.settings.filtermode = mode;
		image_texfilter(wnd.canvas, mode);
	end
end

local filtermodes = {
	{
		name = "target_filter_none",
		label = "None",
		kind = "action",
		handler = function() set_filterm(FILTER_NONE); end
	},
	{
		name = "target_filter_linear",
		label = "Linear",
		kind = "action",
		handler = function() set_filterm(FILTER_LINEAR); end
	},
	{
		name = "target_filter_bilinear",
		label = "Bilinear",
		kind = "action",
		handler = function() set_filterm(FILTER_BILINEAR); end
	},
	{
		name = "target_filter_trilinear",
		label = "Trilinear",
		kind = "action",
		handler = function() set_filterm(FILTER_TRILINEAR); end
	}
};

local scalemodes = {
	{
		name = "target_scale_normal",
		label = "Normal",
		kind = "action",
		handler = function() set_scalef("normal"); end
	},
	{
		name = "target_scale_stretch",
		label = "Stretch",
		kind = "action",
		handler = function() set_scalef("stretch"); end
	},
	{
		name = "target_scale_aspect",
		label = "Aspect",
		kind = "action",
		handler = function() set_scalef("aspect"); end
	}
};

local video_menu = {
	{
		name = "target_scaling",
		label = "Scaling",
		kind = "action",
		hint = "Scale Mode:",
		submenu = true,
		force = true,
		handler = scalemodes
	},
	{
		name = "target_filtering",
		label = "Filtering",
		kind = "action",
		hint = "Basic Filter:",
		submenu = true,
		force = true,
		handler = filtermodes
	},
	{
		name = "Opacity",
		label = "Opacity",
		kind = "value",
		hint = "(0..1)",
		validator = gen_valid_num(0, 1),
		handler = function(ctx, val)
			local wnd = displays.main.selected;
			if (wnd) then
				local opa = tonumber(val);
				wnd.settings.opacity = opa;
				blend_image(wnd.border, opa);
				blend_image(wnd.canvas, opa);
			end
		end
	},
-- good place to add advanced upscalers (xBR, CRT etc.)
};

local window_menu = {
	{
		name = "window_prefix",
		label = "Tag",
		kind = "value",
		validator = function() return true; end,
		handler = function(ctx, val)
			local wnd = displays.main.selected;
			if (wnd) then
				wnd:set_prefix(string.gsub(val, "\\", "\\\\"));
			end
		end
	}
};

-- Will be presented in order, not sorted. Make sure they come in order
-- useful:safe -> uncommon:dangerous to reduce the change of some quick
-- mispress doing something damaging
local shared_actions = {
	{
		name = "shared_suspend",
		label = "Suspend",
		kind = "action",
		handler = shared_suspend
	},
	{
		name = "shared_resume",
		label = "Resume",
		kind = "action",
		handler = shared_resume
	},
	{
		name = "shared_audio",
		label = "Audio",
		submenu = true,
		kind = "action",
		handler = audio_menu,
		force = true,
		eval = function(ctx)
			return displays.main.selected and displays.main.selected.source_audio
		end
	},
	{
		name = "shared_video",
		label = "Video",
		kind = "action",
		submenu = true,
		force = true,
		handler = video_menu,
		hint = "Video:"
	},
	{
		name = "shared_window",
		label = "Window",
		kind = "action",
		submenu = true,
		force = true,
		handler = window_menu,
		Hint = "Window: "
	},
	{
		name = "reset",
		label = "Reset",
		kind = "action",
		dangerous = true,
		handler = shared_reset
	},
};

local function query_tracetag()
	local bar = tiler_lbar(displays.main, function(ctx,msg,done,set)
		if (done and displays.main.selected) then
			image_tracetag(displays.main.selected.canvas, msg);
		end
		return {};
	end);
	bar:set_label("tracetag (wnd.canvas):");
end

local debug_menu = {
	{
		name = "query_tracetag",
		label = "Tracetag",
		kind = "action",
		handler = query_tracetag
	}
};

if (DEBUGLEVEL > 0) then
	table.insert(shared_actions, {
		name = "debug",
		label = "Debug",
		kind = "action",
		hint = "Debug:",
		submenu = true,
		force = true,
		handler = debug_menu
	});
end

--
-- Missing:
-- Input (local binding / rebinding or call once)
--  [atype game: frame management,
--   special filtering,
--   preaudio,
--   block opposing,
--  ]
-- State Management (if state-size is known)
-- Advanced (spawn debug, autojoin workspace)
-- Clone
--

local sdisp = {
	input_label = function(wnd, source, tbl)
		if (not wnd.input_labels) then wnd.input_labels = {}; end
		if (#wnd.input_labels < 100) then
			table.insert(wnd.input_labels, {tbl.labelinfo, tbl.idatatype});
		end
	end
};

function shared_dispatch()
	return sdisp;
end

-- the handler maneuver is to make sure that the callback that is triggered
-- matches the format in gfunc/shared so that we can reuse both for scripting
-- and for menu navigation.
local function show_shmenu(wnd)
	wnd = wnd == nil and displays.main or wnd;
	if (wnd == nil) then
		return;
	end

	local ctx = {
		list = merge_menu(wnd.no_shared and {} or shared_actions, wnd.actions),
		handler = wnd
	};

	launch_menu(wnd.wm, ctx, true, "Action:");
end

register_shared("target_actions", show_shmenu);
