--[[
@description Synchronize and heal selected media items
@version 0.2.1
@author Paweł Łyżwa (ply)
@changelog
  - change license to GPL3
  - remove "ply: " from description
  - declare all variables local

Copyright (C) 2019-2020 Paweł Łyżwa

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

local NAME = "Synchronize and heal selected media items"

local n_items = reaper.CountSelectedMediaItems(0)
local run = false
if n_items < 2 then
  reaper.ShowMessageBox("You should have selected 2 item to synchronize", "Error", 0)
elseif n_items > 2 then
  local ret = reaper.ShowMessageBox("You have selected more than 2 items. This script would synchronize only first two, and attempt to heal splits in all of them. Do you want to continue?", "Warning", 4)
  if ret == 6 then
    run = true
  end
else
  run = true
end

if run then
  reaper.Undo_BeginBlock()

  local items = {}
  for i = 1, n_items do
    items[i] = reaper.GetSelectedMediaItem(0, i-1)
  end

  local item0 = items[1]
  local take0 = reaper.GetMediaItemTake(item0, reaper.GetMediaItemInfo_Value(item0, "I_CURTAKE"))
  local position0 = reaper.GetMediaItemInfo_Value(item0, "D_POSITION")
  local take_offset0 = reaper.GetMediaItemTakeInfo_Value(take0, "D_STARTOFFS")

  local item1 = items[2]
  local take1 = reaper.GetMediaItemTake(item1, reaper.GetMediaItemInfo_Value(item1, "I_CURTAKE"))
  local position1 = reaper.GetMediaItemInfo_Value(item1, "D_POSITION")
  local take_offset1 = reaper.GetMediaItemTakeInfo_Value(take1, "D_STARTOFFS")

  local nudge = position0 - take_offset0 - position1 + take_offset1

  reaper.SelectAllMediaItems(0, false)
  reaper.SetMediaItemSelected(item1, true)
  reaper.ApplyNudge(0, 0, 0, 1, nudge, false, 0)
  reaper.SetMediaItemSelected(item0, true)

  for i = 3, n_items do
    reaper.SetMediaItemSelected(items[i], true)
  end
  reaper.Main_OnCommand(40548, 0) -- Heal splits in items

  reaper.Undo_EndBlock(NAME, 0)
  reaper.UpdateArrange()
end