local hint_lut = {
	none = 0,
	mono = 1,
	light = 2,
	normal = 3,
	subpixel = 4
};

local lbl_hint_lut = {};
for k,v in pairs(hint_lut) do lbl_hint_lut[v] = k; end

local function set_scalef(mode)
	local wnd = active_display().selected;
	if (wnd) then
		wnd.scalemode = mode;
		wnd:resize(wnd.width, wnd.height);
	end
end

local function set_filterm(mode)
	local wnd = active_display().selected;
	if (mode and wnd) then
		wnd.filtermode = mode;
		image_texfilter(wnd.canvas, mode);
	end
end

local filtermodes = {
	{
		name = "none",
		label = "None",
		kind = "action",
		handler = function() set_filterm(FILTER_NONE); end
	},
	{
		name = "linear",
		label = "Linear",
		kind = "action",
		handler = function() set_filterm(FILTER_LINEAR); end
	},
	{
		name = "bilinear",
		label = "Bilinear",
		kind = "action",
		handler = function() set_filterm(FILTER_BILINEAR); end
	}
};

local scalemodes = {
	{
		name = "normal",
		label = "Normal",
		kind = "action",
		description = "Backing store size will be used if it fits within cell",
		handler = function() set_scalef("normal"); end
	},
	{
		name = "stretch",
		label = "Stretch",
		kind = "action",
		description = "Window will be stretched to fill cell",
		handler = function() set_scalef("stretch"); end
	},
	{
		name = "aspect",
		label = "Aspect",
		kind = "action",
		description = "Window will be stretched to fit, maintaing aspect ratio",
		handler = function() set_scalef("aspect"); end
	},
	{
		name = "client",
		label = "Client",
		kind = "action",
		description = "Window will only be changed when backing store changes",
		handler = function() set_scalef("client"); end
	}
};

local function fs_handler(wnd, sym, iotbl, path)
	if (not sym and not iotbl) then
		local disp = active_display(false, true);
		display_fullscreen(disp.name, BADID, val == "Mode Switch");
		wnd.block_rz_hint = wnd.old_block_rz_hint;
		wnd.old_block_rz_hint = nil;
		target_displayhint(wnd.external, wnd.hint_w, wnd.hint_h);
		return;
	end

	if (valid_vid(wnd.external, TYPE_FRAMESERVER)) then
		target_input(wnd.external, iotbl);
	end

-- HACK: the dispatch- override wasn't intended for this purpose, but
-- will forward mouse samples for us as well. The "ok, outsym,.."
-- value matching in durden_input only interrupts input for digital
-- sources though as that would otherwise break mouse routing, but that
-- is what we want here.
	iotbl.digital = true;
	return true, sym, iotbl, path;
end

local function mouse_lockfun(rx, ry, x, y, wnd, ind, act)
-- simulate the normal mouse motion in the case of constrained input
	if (true) then return; end
	if (ind) then
		wnd:mousebutton(ind, act, x, y);
	else
		wnd:mousemotion(x, y, rx, ry);
	end
end

local advanced = {
	{
		name = "source_fs",
		label = "Source-Fullscreen",
		description = "Mark the window for dedicated display fullscreen",
		kind = "value",
		eval = function()
			return valid_vid(active_display().selected.external, TYPE_FRAMESERVER);
		end,
		set = {"Stretch", "Hint-Pad", "Mode Switch"},
		handler = function(ctx, val)
			local wnd = active_display().selected;
			local disp = active_display(false, true);
			if (val == "Hint-Pad") then
				target_displayhint(wnd.external, disp.w, disp.h);
				wnd.old_block_rz_hint = wnd.block_rz_hint;
				wnd.block_rz_hint = true;
			end
			display_fullscreen(disp.name, wnd.external, val == "Mode Switch");
			dispatch_toggle(function(sym, iot, path)
				return fs_handler(wnd, sym, iot, path);
			end
			);
		end
	},
	{
		name = "density_override",
		label = "Override Density",
		kind = "value",
		hint = "(10..100)",
		description = "Send a display hint with a user-set density value",
		eval = function(ctx, val)
			local wnd = active_display().selected;
			return (valid_vid(wnd and wnd.external, TYPE_FRAMESERVER));
		end,
		validator = gen_valid_num(15, 100),
		handler = function(ctx, val)
			local wnd = active_display().selected;
			wnd.density_override = tonumber(val);
			target_displayhint(wnd.external,
				0, 0, wnd.dispmask, wnd:display_table(wnd.wm.disptbl));
		end
	},
	{
		name = "source_hpass",
		label = "Toggle Handle Passing",
		kind = "action",
		description = "Toggle accelerated zero-copy handle passing on/off",
		eval = function(ctx, val)
			local wnd = active_display().selected;
			return (valid_vid(wnd and wnd.external, TYPE_FRAMESERVER));
		end,
		handler = function(ctx, val)
			target_flags(active_display().selected.external, TARGET_NOBUFFERPASS, true);
		end
	},
	{
	name = "source_color",
	label = "Color/Gamma Sync",
	kind = "value",
	description = "Toggle privileged color management support on/off",
	set = {"None", "Global"},
	eval = function(ctx, val)
		local wnd = active_display().selected;
			return (valid_vid(wnd and wnd.external, TYPE_FRAMESERVER));
	end,
	handler = function(ctx, val)
		local wnd = active_display().selected;
		wnd.gamma_mode = string.lower(val);
		target_flags(active_display().selected.external, TARGET_ALLOWCM, true);
	end
	},
	{
	name = "override_size",
	label = "Override Size",
	kind = "value",
	description = "Send a manual hint about presentation size, ignores Blocked Resize",
	eval = function()
		return valid_vid(active_display().selected.external, TYPE_FRAMESERVER);
	end,
	hint = string.format("(w,h)(32..%d)(32..%d)", MAX_SURFACEW, MAX_SURFACEH),
	validator = function(val)
		if #val == 0 then
			return false;
		end
		local w, h = string.match(val, "(%d+),(%d+)");
		w = tonumber(w);
		h = tonumber(h);
		if (not w or not h or w < 32 or w > MAX_SURFACEW) then
			return false;
		end
		if (h < 32 or h > MAX_SURFACEH) then
			return false;
		end
		return true;
	end,
	handler = function(ctx, val)
		local w, h = string.match(val, "(%d+),(%d+)");
		local wnd = active_display().selected;
		wnd:displayhint(tonumber(w), tonumber(h), wnd.dispmask);
	end,
	},
	{
	name = "block_rz",
	label = "Block Resize Hints",
	kind = "value",
	description = "Control if clients should be alerted about its surface dimensions or not",
	set = {LBL_YES, LBL_NO, LBL_FLIP},
	initial = function()
		return active_display().selected.block_rz_hint and LBL_YES or LBL_NO;
	end,
	handler = function(ctx, val)
		local wnd = active_display().selected;
		if (val == LBL_FLIP) then
			val = not wnd.block_rz_hint;
		else
			val = val == LBL_YES;
		end
		wnd.block_rz_hint = val;
	end
	},
	{
	name = "fallback",
	label = "Fallback",
	kind = "value",
	description = "Tell the client where to connect in the event of a server crash",
	eval = function()
		return valid_vid(active_display().selected.external, TYPE_FRAMESERVER);
	end,
	validator = function(val)
		return (string.len(val) > 0 and string.len(val) < 32);
	end,
	handler = function(ctx, val)
		target_devicehint(active_display().selected.external, val, false);
	end
	}
};

-- simply copied from display and modified to retrieve from window if possible.
-- this is messier in that we need to manage the font_block property, and work
-- around the fact that terminal uses its own prefix
local font_override = {
	{
		name = "size",
		label = "Size",
		kind = "value",
		description = "Send a request for a different font-size than the global default",
		validator = gen_valid_num(1, 100),
		eval = function() return active_display().selected.last_font ~= nil; end,
		initial = function()
			local wnd = active_display().selected;
			return tostring(wnd.last_font[1]);
		end,
		handler = function(ctx, val)
			local wnd = active_display().selected;
			local ob = wnd.font_block;
			wnd.font_block = false;
			wnd:update_font(tonumber(val), -1);
			wnd.font_block = ob;
		end
	},
	{
		name = "step_size",
		label = "Step Size",
		kind = "value",
		description = "Increment or decrement the current font size",
		validator = gen_valid_num(-6, 6),
		hint = "(-6..6)",
		eval = function() return active_display().selected.last_font ~= nil; end,
		handler =
		function(ctx, val)
			local wnd = active_display().selected;
			local sz = math.clamp(wnd.last_font[1] + tonumber(val), 4, 200)
			local ob = wnd.font_block;
			wnd.font_block = false;
			wnd:update_font(sz, -1);
			wnd.font_block = ob;
		end,
	},
	{
		name = "hinting",
		label = "Hinting",
		kind = "value",
		description = "Send a request for a different anti-aliasing hinting algorithm",
		set = {"none", "mono", "light", "normal", "subpixel"},
		eval = function() return active_display().selected.last_font ~= nil; end,
		initial = function()
			return lbl_hint_lut[active_display().selected.last_font[2]];
		end,
		handler = function(ctx, val)
			local wnd = active_display().selected;
			local ob = wnd.font_block;
			wnd.font_block = false;
			wnd:update_font(-1, hint_lut[val]);
			wnd.font_block = ob;
		end
	},
	{
		name = "name",
		label = "Font",
		kind = "value",
		set = function()
			local set = glob_resource("*", SYS_FONT_RESOURCE);
			set = set ~= nil and set or {};
			return set;
		end,
		description = "Override the default / active font",
		eval = function() return active_display().selected.last_font ~= nil; end,
		initial = function()
			return active_display().selected.last_font[3][1];
		end,
		handler = function(ctx, val)
			local wnd = active_display().selected;
			local ob = wnd.font_block;
			wnd.font_block = false;
			wnd.last_font[3][1] = val;
			wnd:update_font(-1, -1, wnd.last_font[3]);
			wnd.font_block = ob;
		end
	},
	{
		name = "fbfont",
		label = "Fallback",
		kind = "value",
		description = "Override the default fallback font",
		set = function()
			local set = glob_resource("*", SYS_FONT_RESOURCE);
			set = set ~= nil and set or {};
			return set;
		end,
		eval = function() return active_display().selected.last_font ~= nil; end,
		initial = function()
			return active_display().selected.last_font[3][2];
		end,
		handler = function(ctx, val)
			local wnd = active_display().selected;
			local ob = wnd.font_block;
			wnd.font_block = false;
			wnd.last_font[3][2] = val;
			wnd:update_font(-1, -1, wnd.last_font[3]);
			wnd.font_block = ob;
		end
	}
};

local function color_cb(ind, r, g, b)
	local wnd = active_display().selected;
	wnd.color_table[ind] = {r, g, b};
	target_graphmode(wnd.external, ind + 2, r, g, b);
	target_graphmode(wnd.external, 0);
end

local function color_lookup(ind)
	local ct = active_display().selected.color_table[ind];
	return ct[1], ct[2], ct[3];
end

return {
	{
		name = "scaling",
		label = "Scaling",
		kind = "action",
		description = "Change how client-desired size and window management desired size conflicts are resolved",
		submenu = true,
		handler = scalemodes
	},
	{
		name = "filtering",
		label = "Filtering",
		description = "Control scaling post-processing filters",
		kind = "action",
		submenu = true,
		handler = filtermodes
	},
	{
		name = "screenshot",
		label = "Screenshot",
		kind = "value",
		hint = "(stored in output/)",
		description = "Save the current buffer state as a PNG, suffix counter on collision",
		validator = function(val)
			return string.len(val) > 0 and not string.match(val, "%.%.");
		end,
		handler = function(ctx, val)
			local ind = 0

	-- remove extension if user added it
			if string.sub(val, -4) == ".png" then
				val = string.sub(val, 1, -5)
			end

			val = "output/" .. val
			local tn = val .. ".png"

			while resource(tn) do
				tn = val .. tostring(ind) .. ".png"
				ind = ind + 1
			end

			save_screenshot(tn, FORMAT_PNG, active_display().selected.canvas);
		end
	},
	{
		name = "shader",
		label = "Shader",
		kind = "value",
		description = "Apply or change window canvas postprocessing effects",
		set = function() return shader_list({"effect", "simple"}); end,
		handler = function(ctx, val)
			local key, dom = shader_getkey(val, {"effect", "simple"});

			if (key ~= nil) then
				local wnd = active_display().selected;

-- advanced shaders have custom output, a hook, update and destroy stage
				if (wnd.shader_hook) then
					wnd.shader_hook(true);
					wnd.shader_hook = nil;
					wnd.shader_frame_hook = nil;
					if (valid_vid(wnd.external, TYPE_FRAMESERVER)) then
						image_sharestorage(wnd.external, wnd.canvas);
						target_verbose(wnd.external, false);
					end
					wnd.shader_outvid = nil;
				end

				local a, b, c =
					shader_setup(active_display().selected.canvas, dom, key);

				if (a) then
-- enable per-frame reporting, this needs special support for sliced/interactive
					if (valid_vid(wnd.external)) then
						target_verbose(wnd.external, true);
						wnd.shader_frame_hook = b;
					end
					image_sharestorage(a, wnd.canvas);
					image_set_txcos_default(wnd.canvas, wnd.origo_ll == true);

-- need to reshare the new storage and replace outvid as a resize can trigger
-- the hook to update which can case a delete + rebuild of the effect chain
					wnd.shader_hook = function(destr)
						local res = c(wnd.external, destr);
						if (res) then
							image_sharestorage(res, wnd.canvas);
							image_set_txcos_default(wnd.canvas, wnd.origo_ll == true);
							resize_image(wnd.canvas, wnd.effective_w, wnd.effective_h);
							wnd.shader_outvid = res;
						end
					end;

					wnd.shader_outvid = a;
				end
			end
		end
	},
	{
		name = "opacity",
		label = "Opacity",
		hint = "(0..1)",
		descripton = "Alter the window canvas opacity",
		initial = function()
			return
				image_surface_resolve(active_display().selected.canvas).opacity;
		end,
		kind = "value",
		validator = gen_valid_num(0.0, 1.0),
		handler = function(ctx, val)
			active_display().selected.canvas_opa = tonumber(val);
			blend_image(active_display().selected.canvas, tonumber(val));
		end
	},
	{
		name = "font",
		label = "Font",
		kind = "action",
		description = "Font controls",
		eval = function() return active_display().selected.last_font ~= nil; end,
		submenu = true,
		handler = font_override,
	},
	{
		name = "colors",
		label = "Colors",
		kind = "action",
		submenu = true,
		description = "Color control for clients that support server- defined colors",
		handler = function()
			return suppl_color_menu(active_display().selected.external)
		end
	},
	{
		label = "Advanced",
		name = "advanced",
		description = "Advanced rendering controls",
		submenu = true,
		kind = "action",
		handler = advanced
	}
};
