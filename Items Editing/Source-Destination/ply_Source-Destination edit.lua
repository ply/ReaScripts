--[[
@description Source-Destination edit
@version 1.3.0dev
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

  Check `Source-Destination configuration` script for customization options.
@changelog
  - add configuration possibility
@provides
  [main] ply_Source-Destination edit.lua
  [main] ply_Source-Destination setup.lua
  [main] ply_Source-Destination configuration.lua
  [nomain] config.lua
  [nomain] gfxu.lua

Copyright (C) 2020 Paweł Łyżwa

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

package.path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')..'?.lua'
local config = require("config")

local function insert_empty_item(track, start, end_)
  local item = reaper.AddMediaItemToTrack(track)
  reaper.SetMediaItemPosition(item, start, false)
  reaper.SetMediaItemLength(item, end_-start, false)
  return item
end

local src_proj = reaper.EnumProjects(0)
local dst_proj = reaper.EnumProjects(-1)
local start, end_, track0
if dst_proj == src_proj then
  local i = 1
  while reaper.EnumProjects(i) do i = i + 1 end
  dst_proj = reaper.EnumProjects(i-1)
end

reaper.PreventUIRefresh(1);

-- IN SOURCE PROJECT -----------------------------------------------------------
reaper.SelectProjectInstance(src_proj)

-- copy items from source project
reaper.Undo_BeginBlock2(src_proj)
start, end_ = reaper.GetSet_LoopTimeRange2(src_proj, false, false, 0, 0, false)
local src_length = end_ - start
reaper.InsertTrackAtIndex(0, false)
track0 = reaper.GetTrack(src_proj, 0)
insert_empty_item(track0, start, end_)
reaper.Main_OnCommand(40717, 0) -- Select all items in current time selection
reaper.SetCursorContext(1, 0) -- focus the arrange window
reaper.Main_OnCommand(41383, 0) -- Copy items/tracks/envelope points (depending on focus) within time selection, if any (smart copy)
reaper.DeleteTrack(track0)
reaper.Undo_EndBlock2(src_proj, "Source-Destination edit (source)", -1)
reaper.Undo_DoUndo2(src_proj)

-- store track selection of destination project
local selected_tracks = {}
for i = 1, reaper.CountSelectedTracks2(dst_proj, true) do
  selected_tracks[i] = reaper.GetSelectedTrack2(dst_proj, i-1, true)
end

-- IN DESTINATION PROJECT ------------------------------------------------------
reaper.SelectProjectInstance(dst_proj)

-- store cursor position
local cursor_position = reaper.GetCursorPositionEx(dst_proj)

-- paste items to destination project
reaper.SelectProjectInstance(dst_proj)
reaper.Undo_BeginBlock2(dst_proj)
reaper.InsertTrackAtIndex(0, false)
track0 = reaper.GetTrack(dst_proj, 0)
start, end_ = reaper.GetSet_LoopTimeRange2(dst_proj, false, false, 0, 0, false)
if not config.insert and start == end_ then -- override in destination when on 3-point edit if requested
  start, end_ =reaper.GetSet_LoopTimeRange2(dst_proj, true, false, cursor_position, cursor_position + src_length, false)
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

-- crossfades
local item = reaper.GetSelectedMediaItem(dst_proj, 0)
start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
end_ = start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
reaper.GetSet_LoopTimeRange2(dst_proj, true, false, end_ - config._xfade_len/2, end_ + config._xfade_len/2, false)
reaper.Main_OnCommand(40717, 0) -- Select all items in current time selection
reaper.Main_OnCommand(40916, 0) -- Crossfade items within time selection
reaper.GetSet_LoopTimeRange(true, false, start - config._xfade_len/2, start + config._xfade_len/2, false)
reaper.Main_OnCommand(40717, 0) -- Select all items in current time selection
reaper.Main_OnCommand(40916, 0) -- Crossfade items within time selection

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
  reaper.SetEditCurPos2(dst_proj, cursor_position, true, true)
end

-- cleanup
reaper.DeleteTrack(track0)
-- recall track selection
for _, track in ipairs(selected_tracks) do reaper.SetTrackSelected(track, true) end

reaper.Undo_EndBlock2(dst_proj, "Source-Destination edit", -1)
reaper.PreventUIRefresh(-1);
reaper.UpdateArrange()
reaper.UpdateTimeline()
reaper.MarkProjectDirty(dst_proj)