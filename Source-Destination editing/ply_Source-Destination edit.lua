--[[
@description Source-Destination edit
@version 1.2.2
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

  ## Configuration

  Set cross-fade length by setting `XFADE_LEN` in the script source. Set to `0`
  to disable cross-fades. If not set, uses value from `Preferences -> Project
  -> Media Item Defaults -> Overlap and crossfade items when splitting length`.

@changelog
  - change license to GPL3
  - add documentation
  - make variables local
@provides
  [main] ply_Source-Destination edit.lua
  [main] ply_Source-Destination setup.lua

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


-- Uncomment to set crossfade length [s]
--XFADE_LEN = 0.010
-- otherwise defaults to Preferences -> Project -> Media Item Defaults
--                         -> Overlap and crossfade items when splitting length


-- BEGIN SCRIPT
if not XFADE_LEN then
  local _, defsplitxfadelen = reaper.get_config_var_string("defsplitxfadelen")
  XFADE_LEN = tonumber(defsplitxfadelen)
end

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

-- copy items from source project
reaper.SelectProjectInstance(src_proj)
reaper.Undo_BeginBlock2(src_proj)
start, end_ = reaper.GetSet_LoopTimeRange2(src_proj, false, false, 0, 0, false)
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

-- paste items to destination project
reaper.SelectProjectInstance(dst_proj)
reaper.Undo_BeginBlock2(dst_proj)
reaper.InsertTrackAtIndex(0, false)
track0 = reaper.GetTrack(dst_proj, 0)
start, end_ = reaper.GetSet_LoopTimeRange2(dst_proj, false, false, 0, 0, false)
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
reaper.GetSet_LoopTimeRange2(dst_proj, true, false, end_ - XFADE_LEN/2, end_ + XFADE_LEN/2, false)
reaper.Main_OnCommand(40717, 0) -- Select all items in current time selection
reaper.Main_OnCommand(40916, 0) -- Crossfade items within time selection
reaper.GetSet_LoopTimeRange(true, false, start - XFADE_LEN/2, start + XFADE_LEN/2, false)
reaper.Main_OnCommand(40717, 0) -- Select all items in current time selection
reaper.Main_OnCommand(40916, 0) -- Crossfade items within time selection
reaper.GetSet_LoopTimeRange2(dst_proj, true, false, start, end_, false)

reaper.DeleteTrack(track0)
-- recall track selection
for _, track in ipairs(selected_tracks) do reaper.SetTrackSelected(track, true) end

reaper.Undo_EndBlock2(dst_proj, "Source-Destination edit", -1)
reaper.PreventUIRefresh(-1);
reaper.UpdateArrange()
reaper.UpdateTimeline()
reaper.MarkProjectDirty(dst_proj)