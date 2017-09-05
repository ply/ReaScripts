-- @description ply: put T marker
-- @version 1.0
-- @author Paweł Łyżwa (ply)
-- @changelog
--   + Initial release

proj, projfn = reaper.EnumProjects(-1, 0)
reaper.OnPauseButtonEx(proj)
pos = reaper.GetCursorPositionEx(proj)
  
ret, idx = reaper.GetUserInputs("Add T Marker", 1, "Marker ID", "");
if (ret) then
  reaper.AddProjectMarker(proj, false, pos, 0, "T", idx)
end
