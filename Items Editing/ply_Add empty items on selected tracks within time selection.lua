--[[
@description Add empty items on selected tracks within time selection
@version 1.0.0
@author Paweł Łyżwa (ply)
@changelog
  Initial version

Copyright (C) 2025 Paweł Łyżwa

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

local selected_tracks_count = reaper.CountSelectedTracks(0)
local time_selection_start, time_selection_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, 0)

if time_selection_end == 0 then
  reaper.ShowMessageBox("Unable to add items: no time selection", "Error", 0)
elseif selected_tracks_count == 0 then
  reaper.ShowMessageBox("Unable to add items: no tracks selected", "Error", 0)
else
  reaper.Undo_BeginBlock()
  for i = 0, selected_tracks_count-1 do
    local track = reaper.GetSelectedTrack(0, i)
    local item = reaper.AddMediaItemToTrack(track)
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", time_selection_start)
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", time_selection_end - time_selection_start)
  end
  if selected_tracks_count == 1 then
    reaper.Undo_EndBlock("Add empty item", 4)
  else
    reaper.Undo_EndBlock("Add empty items", 4)
  end
  reaper.UpdateArrange()
end

-- prevent creating additional undo when no items were added
reaper.defer(function() end)
