--[[
@description Set time selection with start and end relative to edit cursor (dialog)
@version 1.0.1
@author Paweł Łyżwa (ply)
@screenshot https://ply.github.io/ReaScripts/doc/img/Set_time_selection_relative_to_edit_cursor.png
@changelog
  - rename script
  - change license to GPL 3
  - make all variables local
  - add screenshot

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

local ok, csv = reaper.GetUserInputs("Set time selection relative to cursor position", 2, "start offset,end offset", "")
if ok then
  local comma_pos = string.find(csv, ",")
  local offs_in = reaper.parse_timestr(string.sub(csv, 0, comma_pos-1))
  local offs_out = reaper.parse_timestr(string.sub(csv, comma_pos+1))
  if offs_in and offs_out then
    local pos = reaper.GetCursorPosition()
    reaper.GetSet_LoopTimeRange(true, true, pos+offs_in, pos+offs_out, true)
  else
    reaper.ShowMessageBox("invalid input", "error", 0)
  end
end