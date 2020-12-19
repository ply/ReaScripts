--[[
@description Insert marker with ID larger than 10 at playback position (dialog)
@version 1.2.1
@author Paweł Łyżwa (ply)
@changelog
 - rename script
 - change license to GPL3

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

local proj = reaper.EnumProjects(-1)
local pos = (reaper.GetPlayState() == 0) and reaper.GetCursorPosition() or reaper.GetPlayPosition()

local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)
local markers = {}
local name = ""
for i = 0, (num_markers+num_regions-1) do
	local _, isrgn, mpos, _, mname, mid = reaper.EnumProjectMarkers(i)
	if not isrgn then
		table.insert(markers, mid)
		-- set `name` to name of last region before or on `pos`
		if mpos <= pos and mid > 10 then
			name = mname
		end
	end
end
table.sort(markers)

-- find first unused id larger than 10
local id = 11
for _, v in ipairs(markers) do
	if id == v then
		id = id + 1
	elseif id < v then
		break
	end
end

-- reaper.GetUserInputs() ignores field separator, when it gets unbalanced ' or "
-- the hack below appends ' or " to name to retain balance
local odd = { ["'"] = false, ['"'] = false }
for char in name:gmatch("['\"]") do
	odd[char] = not odd[char]
end
local append = ""
for char, put in pairs(odd) do
	if put then append = append..char end
end
if append ~= "" then
	name = name.." |"..append
end

local ok, csv = reaper.GetUserInputs("insert marker", 2,
                                     "name,ID,extrawidth=200,separator=\n",
                                     name.."\n"..tostring(id))
if ok then
	local name, id = csv:match("(.*)\n(.*)")
	if name == nil or id == nil then
		reaper.ShowMessageBox("invalid input", "error", 1)
	else
		reaper.Undo_BeginBlock2(proj)
		reaper.AddProjectMarker(proj, false, pos, 0, name, id) -- uses id if unused or sets it to first unused
		reaper.Undo_EndBlock2(proj, "Insert marker", -1)
		reaper.UpdateTimeline()
	end
end