--[[
@description Source-Destination edit
@version 1.4.0
@author Paweł Łyżwa (ply)
@about
  # Source-Destination edit

  3- & 4-point editing for REAPER. This package is very inspired
  by [pelleke's actions](https://forum.cockos.com/showthread.php?t=116213)
  (thank you).

  ## Usage

  First, open the source project and use `Source-Destination setup` script.
  It opens a duplicate of the currently opened project in a new tab (reads last
  saved version), removes all items, markers and regions and sets all necessary
  options. It will ask you for a filename to save the destination project.

  Use `Source-Destination edit` to do the actual edits. It can do both
  3- and 4-point edits. It copies audio from time selection in source project to:
   - time selection in destination project if there is any time selection
   - inserts audio at edit cursor otherwise

  The script assumes the source project to be the leftmost tab, and destination
  project to be in the currently opened project tab. In case the leftmost tab
  is opened, it works with the rightmost tab as the destination.

  Use `Source-Destination configuration` script for customization.
@changelog
  - add marker copying option
  - edit: refactor edit
  - configure: check window bounds in mouse-over highlighting
@provides
  [main] ply_Source-Destination edit.lua
  [main] ply_Source-Destination setup.lua
  [main] ply_Source-Destination configuration.lua
  [nomain] config.lua
  [nomain] gfxu.lua

Copyright (C) 2020--2021 Paweł Łyżwa

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
]]--

local TITLE = "Source-Destination edit"
package.path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')..'?.lua'
local config = require("config")


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function insert_empty_item(track, start, end_)
  local item = reaper.AddMediaItemToTrack(track)
  reaper.SetMediaItemPosition(item, start, false)
  reaper.SetMediaItemLength(item, end_-start, false)
  return item
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function get_time_selection_length (proj)
  local start, end_ = reaper.GetSet_LoopTimeRange2(proj, false, false, 0, 0, false)
  return end_ - start
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function get_selected_tracks (proj)
  local selected_tracks = {}
  for i = 1, reaper.CountSelectedTracks2(proj, true) do
      selected_tracks[i] = reaper.GetSelectedTrack2(proj, i-1, true)
  end
  return selected_tracks
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function set_selected_tracks (selected_tracks)
  for _, track in ipairs(selected_tracks) do reaper.SetTrackSelected(track, true) end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function get_markers_relative_to_time_selection (proj)
  local markers = {}
  local start, end_ = reaper.GetSet_LoopTimeRange2(proj, false, false, 0, 0, false)
  for idx = 0, reaper.CountProjectMarkers(proj)-1 do
    local _, isrgn, pos, _, name, _, color = reaper.EnumProjectMarkers3(proj, idx)
    if not isrgn and pos >= start and pos < end_ then
      markers[#markers+1] = {
        pos = pos - start,
        name = name,
        color = color
      }
    end
  end
  return markers
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function add_markers_relative_to_position (proj, markers, position)
  for _, marker in ipairs(markers) do
    reaper.AddProjectMarker2(proj, false, position + marker.pos, 0, marker.name, -1, marker.color)
  end
end

---------------------------------------------------------------------------------------
-- Copy items form current time selection to clipboard (with dummy item on added track)
-- Note: changes time selection
---------------------------------------------------------------------------------------
local function copy_items_from_current_time_selection (src_proj)
  local start, end_ = reaper.GetSet_LoopTimeRange2(src_proj, false, false, 0, 0, false)
  -- copy items from source project
  reaper.InsertTrackAtIndex(0, false)
  local track0 = reaper.GetTrack(src_proj, 0)
  insert_empty_item(track0, start, end_)
  reaper.Main_OnCommand(40717, 0) -- Select all items in current time selection
  reaper.SetCursorContext(1, 0) -- focus the arrange window
  reaper.Main_OnCommand(41383, 0) -- Copy items/tracks/envelope points (depending on focus) within time selection, if any (smart copy)
  reaper.DeleteTrack(track0)
end


--------------------------------------------------------------------------------------
-- Paste items from clipboard (3- or 4-point, depending on time selection in project).
-- Expects dummy tiem on added track in the clipboard
-- Note: changes cursor position and time selection
--
-- @param dst_proj    Destination project
-- @param src_length  Length of pasted items (needed for 3-point edit)
--
-- @return start      Paste start time
-- @return end_       Paste end time
--------------------------------------------------------------------------------------
local function paste_items (dst_proj, src_length)
  -- return
  reaper.InsertTrackAtIndex(0, false)
  local track0 = reaper.GetTrack(dst_proj, 0)
  local start, end_ = reaper.GetSet_LoopTimeRange2(dst_proj, false, false, 0, 0, false)
  if not config.insert and start == end_ then -- override in destination when on 3-point edit if requested
    local cursor_pos = reaper.GetCursorPositionEx(dst_proj)
    start, end_ = reaper.GetSet_LoopTimeRange2(dst_proj, true, false, cursor_pos, cursor_pos + src_length, false)
  end
  if start == end_ then
    reaper.Main_OnCommand(40182, 0) -- Select all items
    reaper.Main_OnCommand(40757, 0) -- Split items at edit cursor (no change selection)
  else
    insert_empty_item(track0, start, end_)
    reaper.Main_OnCommand(40717, 0) -- Select all items in current time selection
    reaper.Main_OnCommand(40061, 0) -- Split items at time selection (selects these splitted items)
    reaper.SetCursorContext(1, 0) -- focus the arrange window
    reaper.Main_OnCommand(40697, 0) -- Remove items/tracks/envelope points (depending on focus)
    reaper.SetEditCurPos2(dst_proj, start, true, true)
  end
  reaper.SetOnlyTrackSelected(track0)
  reaper.Main_OnCommand(40058, 0) -- Paste items/tracks
  local item = reaper.GetSelectedMediaItem(dst_proj, 0)
  start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  end_ = start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  reaper.DeleteTrack(track0)
  return start, end_
end


--------------------------------------------------------------------------------
-- Make cross-fade.
-- Note: sets time selection to cross-fade
-- Note: selects edited items
--------------------------------------------------------------------------------
local function make_crossfade (dst_proj, centre, length)
  reaper.GetSet_LoopTimeRange2(dst_proj, true, false, centre - length/2, centre + length/2, false)
  reaper.Main_OnCommand(40717, 0) -- Select all items in current time selection
  reaper.Main_OnCommand(40916, 0) -- Crossfade items within time selection
end


--------------------------------------------------------------------------------
-- Entry point
--------------------------------------------------------------------------------
local function main()
  local src_proj = reaper.EnumProjects(0)
  local dst_proj = reaper.EnumProjects(-1)
  if dst_proj == src_proj then
    local i = 1
    while reaper.EnumProjects(i) do i = i + 1 end
    dst_proj = reaper.EnumProjects(i-1)
  end

  reaper.PreventUIRefresh(1);
  reaper.SelectProjectInstance(src_proj)
  local src_length = get_time_selection_length(src_proj)

  if src_length == 0 then
    reaper.ShowMessageBox("Error: no time selection in source project. Aborting", TITLE, 0)
    return
  else
    -- IN SOURCE PROJECT ---------------------------------------------------------
    reaper.SelectProjectInstance(src_proj)
    local markers = nil
    if config.copy_markers then
      markers = get_markers_relative_to_time_selection(src_proj)
    end
    copy_items_from_current_time_selection (src_proj)
    reaper.Undo_EndBlock2(src_proj, "Source-Destination edit (source)", -1)
    reaper.Undo_DoUndo2(src_proj)

    -- IN DESTINATION PROJECT ----------------------------------------------------
    reaper.SelectProjectInstance(dst_proj)

    -- store track selection and cursor position
    local selected_tracks = get_selected_tracks(dst_proj)
    local cursor_pos = reaper.GetCursorPositionEx(dst_proj)
    -- paste items to destination project
    reaper.SelectProjectInstance(dst_proj)
    reaper.Undo_BeginBlock2(dst_proj)
    local start, end_ = paste_items(dst_proj, src_length)
    -- crossfades
    make_crossfade(dst_proj, end_, config._xfade_len)
    make_crossfade(dst_proj, start, config._xfade_len) -- selects edited items
    -- markers
    if markers then
      add_markers_relative_to_position (dst_proj, markers, start)
    end

    -- manage time selection in destination project
    if config.select_edit_in_dst then
      -- select edit on the timeline
      reaper.GetSet_LoopTimeRange2(dst_proj, true, false, start, end_, false)
    else
      -- clear time selection
      reaper.GetSet_LoopTimeRange2(dst_proj, true, false, 0, 0, false)
    end

    -- recall cursor position if not requesting cursor at the end of the edit
    if not config.dst_cur_to_edit_end then
      reaper.SetEditCurPos2(dst_proj, cursor_pos, true, true)
    end
    -- recall track selection
    set_selected_tracks(selected_tracks)

    reaper.Undo_EndBlock2(dst_proj, "Source-Destination edit", -1)
    reaper.MarkProjectDirty(dst_proj)
  end

  reaper.PreventUIRefresh(-1);
  reaper.UpdateArrange()
  reaper.UpdateTimeline()
end

main()