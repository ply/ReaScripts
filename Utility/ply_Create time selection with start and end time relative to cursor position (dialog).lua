-- @description ply: Create time selection with start and end time relative to cursor position (dialog)
-- @version 1.0
-- @author Paweł Łyżwa (ply)
-- @changelog
--   + Initial release

ok, csv = reaper.GetUserInputs("sd edit helper", 2, "start offset,end offset", "")
if ok then
	comma_pos = string.find(csv, ",")
	offs_in = reaper.parse_timestr(string.sub(csv, 0, comma_pos-1))
	offs_out = reaper.parse_timestr(string.sub(csv, comma_pos+1))
	if offs_in and offs_out then
		pos = reaper.GetCursorPosition()
		start, end_ = reaper.GetSet_LoopTimeRange(true, true, pos+offs_in, pos+offs_out, true)
	else
		reaper.ShowMessageBox("invalid input", "error", 0)
	end
end