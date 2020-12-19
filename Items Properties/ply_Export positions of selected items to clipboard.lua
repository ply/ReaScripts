--[[
@description Export positions of selected items to clipboard in TSV format
@version 1.1.1
@author Paweł Łyżwa (ply)
@about
	# Export positions of selected items to clipboard in TSV format

	Columns:
	 - item position
	 - item end (position + length)
	 - take name
	 - source start time
	 - source end time
@changelog
	- make description more descriptive
	- change license to GPL 3
	- add documentation
	- declare variables local

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

local function time2str (t)
	return string.format("% 4d:%06.3f", t//60, t%60)
end

local output = "POSITION\tEND\tNAME\tSRC_START\tSRC_END\n"

local proj = 0 -- active project
for i = 0, reaper.CountSelectedMediaItems(proj)-1, 1 do
	local item = reaper.GetSelectedMediaItem(proj, i)
	local take = reaper.GetMediaItemTake(item, reaper.GetMediaItemInfo_Value(item, "I_CURTAKE"))
	local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
	local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	local src_start = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")

	local cols = {
		time2str(pos),
		time2str(pos + len),
		reaper.GetTakeName(take),
		time2str(src_start),
		time2str(src_start + len)
	}

	output = output..table.concat(cols, "\t").."\n"
end

reaper.CF_SetClipboard(output)