--[[
@noindex

Source-Destination editing setup script
This file is a part of "Source-Destination edit" package.
Check "ply_Source-Destination edit.lua" for more information.

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

local TITLE = "Source-Destination - setup"

local answer = reaper.ShowMessageBox(
	"In order to make a copy of the project, this script needs to save current project first. Do you want to continue?",
	TITLE, 4)

if answer == 6 then
	reaper.Main_SaveProject(0, 0)

	local _, src_filename = reaper.EnumProjects(-1)
	reaper.Main_OnCommand(41929, 0) -- New project tab ignoring default template
	reaper.Main_openProject(src_filename)

	reaper.Undo_BeginBlock(0)

	-- Set ripple editing per-track
	reaper.Main_OnCommand(40310, 0)
	-- Set move envelope points with items on
	if reaper.GetToggleCommandState(40070) == 0 then
		reaper.Main_OnCommand(40070, 0)
	end
	-- Disable snap
	reaper.Main_OnCommand(40753, 0)

	-- clear all markers & regions
	repeat until not reaper.DeleteProjectMarkerByIndex(0, 0)

	-- delete all items
	for i = 0, reaper.CountTracks(0)-1 do
		local track = reaper.GetTrack(0, i)
		while reaper.CountTrackMediaItems(track) > 0 do
			local item = reaper.GetTrackMediaItem(track, 0)
			reaper.DeleteTrackMediaItem(track, item)
		end
	end

	-- reset loop, time selection and cusor position
	reaper.GetSet_LoopTimeRange(1, 0, 0, 0, 0)
	reaper.GetSet_LoopTimeRange(1, 1, 0, 0, 0)
	reaper.SetEditCurPos(0, 1, 1)

	reaper.Undo_EndBlock("Set up S/D edit", -1)

	reaper.UpdateArrange()
	reaper.MarkProjectDirty(0)

	reaper.ShowMessageBox(
		"You will be asked to save your destination project. Make sure you don't override existing source project!",
		TITLE, 0)
	reaper.Main_SaveProject(0, 1)
end