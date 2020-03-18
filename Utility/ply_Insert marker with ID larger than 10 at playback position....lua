--[[ 
@description Insert marker with ID larger than 10 at playback position...
@version 1.0
@author Paweł Łyżwa (ply)
@changelog Initial version
]]--

proj = reaper.EnumProjects(-1)
pos = (reaper.GetPlayState() == 0) and reaper.GetCursorPosition() or reaper.GetPlayPosition()

_, num_markers, num_regions = reaper.CountProjectMarkers(proj)
markers = {}
name = ""
for i = 0, (num_markers+num_regions-1) do
	_, isrgn, mpos, _, mname, mid = reaper.EnumProjectMarkers(i)
	if not isrgn then 
		table.insert(markers, mid)
		-- set `name` to name of last region before `pos`
		if mpos < pos then
			name = mname
		end
	end
end
table.sort(markers)

-- find first unused id larger than 10
id = 11
for _, v in ipairs(markers) do
	if id == v then 
		id = id + 1
	elseif id < v then
		break
	end
end

ok, csv = reaper.GetUserInputs("insert marker", 2, "name,ID", name..","..tostring(id))
if ok then
	name, id = csv:match("^(.*),%s*(%d+)%s*$")
	if name == nil or id == nil then
		reaper.ShowMessageBox("invalid input", "error", 1)
	else
		reaper.Undo_BeginBlock2(proj)
		reaper.AddProjectMarker(proj, false, pos, 0, name, id) -- uses id if unused or sets it to first unused
		reaper.Undo_EndBlock2(proj, "Insert marker", -1)
		reaper.UpdateTimeline()
	end
end