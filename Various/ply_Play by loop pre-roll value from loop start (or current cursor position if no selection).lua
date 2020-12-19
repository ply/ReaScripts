--[[ 
@description Play by loop pre-roll value from loop start (or current cursor position if no selection)
@version 1.0.1
@author Paweł Łyżwa (ply)
@changelog
  - change license to GPL 3
  - make all variables local

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

local _, preroll = reaper.get_config_var_string("loopselpr")
preroll = preroll / 1000 -- convert to seconds

local start, end_ = reaper.GetSet_LoopTimeRange(false, true, 0, 0, false)
local cur_pos = reaper.GetCursorPosition()
local play_from
if start == end_ then
  play_from = cur_pos - preroll
else
  play_from = start - preroll
end

cur_pos = reaper.GetCursorPosition()

reaper.SetEditCurPos(play_from, false, true)
reaper.OnPlayButton()
reaper.SetEditCurPos(cur_pos, false, false)