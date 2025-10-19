--[[
@description Delete marker (1-10)
@version 1.0.0
@author Paweł Łyżwa (ply)
@about Set of scripts to delete a single marker from ID range 1-10.
@changelog
  Initial version
@metapackage
@provides
  [main] ply_Delete marker.lua > ply_Delete marker 01.lua
  [main] ply_Delete marker.lua > ply_Delete marker 02.lua
  [main] ply_Delete marker.lua > ply_Delete marker 03.lua
  [main] ply_Delete marker.lua > ply_Delete marker 04.lua
  [main] ply_Delete marker.lua > ply_Delete marker 05.lua
  [main] ply_Delete marker.lua > ply_Delete marker 06.lua
  [main] ply_Delete marker.lua > ply_Delete marker 07.lua
  [main] ply_Delete marker.lua > ply_Delete marker 08.lua
  [main] ply_Delete marker.lua > ply_Delete marker 09.lua
  [main] ply_Delete marker.lua > ply_Delete marker 10.lua

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

local script_path = ({reaper.get_action_context()})[2]
local marker_id = tonumber(script_path:match('.*[^%d]0*(%d+).lua'))

reaper.Undo_BeginBlock()
if reaper.DeleteProjectMarker(nil, marker_id, false) then
  reaper.Undo_EndBlock('Delete marker '..tostring(marker_id), 8)
else
  -- end undo block without creating undo point when no marker was deleted
  reaper.Undo_EndBlock('', 0)
  -- avoid automatically created undo point being created
  reaper.defer(function() end)
end
