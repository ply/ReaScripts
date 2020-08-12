--[[
@description Playhead vs selected track item & markers (window)
@version 1.1
@author Paweł Łyżwa (ply)
@changelog add support for default marker color
@about
  Runs a window which shows:
   - which item on selected track is under playhead
   - playhead position relative to item's position and source
   - list of markers before playhead (id, name, color, and position relative to playhead)
]]--

-- globals ---------------------------------------------------------------------

local NAME = "Playhead vs selected track item & markers"
local EXT_STATE_SECTION = "ply: "..NAME
local COL1TXT = "item before playhead:  " -- longest possible label
local col1w -- internal state
local fontsize -- saved settings

-- gfx helpers -----------------------------------------------------------------

local function gfx_set_color(r, g, b, a)
	--[[	gfx_set_color(r, g, b, a)
		gfx_set_color(r, g, b) -- keeps gfx.a unchanged
		gfx_set_color(w, a) -- gray
		gfx_set_color(w) -- keeps gfx.a unchanged	]]--
	gfx.a = a or gfx.a
	gfx.r = r
	gfx.g = g or r
	gfx.b = b or r
	if g and not b then
		gfx.a = g
		gfx.g = r
	end
end

local function gfx_newline()
	gfx.x = 0
	gfx.y = gfx.y + gfx.texth
end

local function gfx_rdraw_str(str)
	gfx.x = gfx.x - gfx.measurestr(str)
	gfx.drawstr(str)
end

-- general helpers -------------------------------------------------------------

local function get_track_item_on_pos(track, pos)
	if not track then return nil, nil end
	local item, item_start, item_end
	for i = 0, reaper.CountTrackMediaItems(track)-1 do
		-- assuming timeline order of item
		item = reaper.GetTrackMediaItem(track, i)
		item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
		item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
		if item_end > pos then
			break
		end
	end
	if item then
		return (item_end >= pos or false), (item_start <= pos and item or nil)
	else
		return nil, nil
	end
end

local function get_markers_before_pos(pos)
	local markers = {}
	local _, proj = reaper.EnumProjects(-1)
	local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)
	for i = 0, (num_markers+num_regions-1) do
		local _, isrgn, mpos, _, mname, mid, mcolor = reaper.EnumProjectMarkers3(proj, i)
		if mpos > pos then break end
		if not isrgn then
			table.insert(markers, {
				["id"] = mid,
				["name"] = mname,
				["pos"] = mpos,
				["color"] = mcolor,
			})
		end
	end
	return markers
end

-- GUI logic -------------------------------------------------------------------

local function set_font()
	gfx.setfont(1, "Arial", fontsize*gfx.ext_retina, "b")
	col1w = gfx.measurestr(COL1TXT)
end

local function init()
	local dock = tonumber(reaper.GetExtState(EXT_STATE_SECTION, "dock")) or 0
	local x = tonumber(reaper.GetExtState(EXT_STATE_SECTION, "x"))
	local y = tonumber(reaper.GetExtState(EXT_STATE_SECTION, "y"))
	local w = tonumber(reaper.GetExtState(EXT_STATE_SECTION, "w")) or 400
	local h = tonumber(reaper.GetExtState(EXT_STATE_SECTION, "h")) or 170
	fontsize = tonumber(reaper.GetExtState(EXT_STATE_SECTION, "fontsize")) or 20

	gfx.ext_retina = 1.0 -- enable high resolution support
	gfx.init(NAME, w, h, dock, x, y)
	if gfx.ext_retina ~= 1.0 then
		gfx.quit()
		gfx.init(NAME, w*gfx.ext_retina, h*gfx.ext_retina, dock, x, y)
	end
	set_font()
	col1w = gfx.measurestr(COL1TXT)
end

local function handle_mouse_events()
	-- resize font if on mouse wheel
	if gfx.mouse_wheel ~= 0 then
		if gfx.mouse_wheel > 0 then
			fontsize = fontsize < 120 and fontsize + 1 or 120
		elseif fontsize > 8 then
			fontsize = fontsize - 1
		end
		gfx.mouse_wheel = 0
		set_font()
	end
end

local function run()
	-- check if window exists
	if gfx.getchar(-1) == -1 then -- window is closed
		-- save settings, window size & dock status
		reaper.SetExtState(EXT_STATE_SECTION, "fontsize", tostring(fontsize), true)
		local dock, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0)
		reaper.SetExtState(EXT_STATE_SECTION, "dock", tostring(dock), true)
		reaper.SetExtState(EXT_STATE_SECTION, "x", tostring(x), true)
		reaper.SetExtState(EXT_STATE_SECTION, "y", tostring(y), true)
		reaper.SetExtState(EXT_STATE_SECTION, "w", tostring(w/gfx.ext_retina), true)
		reaper.SetExtState(EXT_STATE_SECTION, "h", tostring(h/gfx.ext_retina), true)
		return
	end

	set_font() -- because gfx.ext_retina can change
	handle_mouse_events()

	local default_marker_color = reaper.GetThemeColor("marker", 0)
	local track = reaper.GetSelectedTrack(0, 0)
	local pos = (reaper.GetPlayState() == 0) and reaper.GetCursorPosition() or reaper.GetPlayPosition()

	gfx.x = 0
	gfx.y = 0

	gfx_set_color(0.7)
	gfx.drawstr("Selected track:  ")
	gfx.x = col1w
	if track then
		local _, track_name = reaper.GetTrackName(track)
		gfx_set_color(0.9)
		gfx.drawstr(track_name)
	else
		gfx.drawstr("[no track selected]")
	end

	gfx_newline()
	local under, item = get_track_item_on_pos(track, pos)
	gfx_set_color(0.7)
	gfx.drawstr("Item ")
	if under then
		gfx_set_color(0, 1, 0)
		gfx.drawstr("under ")
	else
		gfx_set_color(1, 0, 0)
		gfx.drawstr("before ")
	end
	gfx_set_color(0.7)
	gfx.drawstr("playhead:  ")
	if item then
		local take = reaper.GetActiveTake(item)
		if take then
			gfx_set_color(1, 1, 0)
			gfx.x = col1w
			gfx.drawstr(reaper.GetTakeName(take))
		end
	end

	local item_pos = item and reaper.GetMediaItemInfo_Value(item, "D_POSITION") or nil

	gfx_newline()
	gfx_set_color(0.7)
	gfx.drawstr("Position within item:  ")
	if item and under then
		gfx_set_color(0.9)
		gfx.x = col1w
		gfx.drawstr(reaper.format_timestr_pos(pos - item_pos, "", -1))
	end

	gfx_newline()
	gfx_set_color(0.7)
	gfx.drawstr("Source time position:  ")
	if item and under then
		local take = reaper.GetActiveTake(item)
		if take then
			gfx_set_color(0.9)
			gfx.x = col1w
			gfx.drawstr(reaper.format_timestr_pos(
				pos - item_pos + reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS"),
				"",
				-1))
		end
	end

	gfx_newline()
	gfx.y = gfx.y + gfx.texth/2
	gfx_set_color(0.9)
	gfx.drawstr("Last markers (reverse order):")
	gfx_newline()
	local markers = get_markers_before_pos(pos)
	local pos_w = gfx.measurestr("-"..reaper.format_timestr_pos(3600000, "", -1))
	while gfx.y < gfx.h and #markers > 0 do
		local marker = table.remove(markers)
		-- time elapsed
		gfx_set_color(0.5)
		gfx.x = pos_w
		gfx_rdraw_str("-"..reaper.format_timestr_pos(pos-marker.pos, "", -1))
		-- color indicator
		local color = marker.color
		if color == 0 then
			color = default_marker_color
		end
		local r, g, b = reaper.ColorFromNative(color)
		gfx_set_color(r/255, g/255, b/255)
		gfx.x = gfx.x+gfx.measurestr("v")
		gfx.rect(gfx.x, gfx.y+1, gfx.measurestr("v"), gfx.texth-1)
		-- id (number)
		gfx_set_color(0.9)
		gfx.x = gfx.x + gfx.measurestr( "v000   ")
		gfx_rdraw_str(marker.id.."  ")
		-- name
		gfx_set_color(0.7)
		gfx.drawstr(marker.name)
		gfx_newline()
	end

	gfx.update()
	reaper.defer(run)
end

init()
run()
