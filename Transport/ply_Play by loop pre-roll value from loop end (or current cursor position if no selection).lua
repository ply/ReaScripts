--[[ 
@description Play by loop pre-roll value from loop start (or current cursor position if no selection)
@version 1.0
@author Paweł Łyżwa (ply)
@changelog Initial release
]]--

_, preroll = reaper.get_config_var_string("loopselpr")
preroll = preroll / 1000 -- convert to seconds

start, end_ = reaper.GetSet_LoopTimeRange(false, true, 0, 0, false)
cur_pos = reaper.GetCursorPosition()
if start == end_ then
  play_from = cur_pos - preroll
else
  play_from = end_ - preroll
end

cur_pos = reaper.GetCursorPosition()

reaper.SetEditCurPos(play_from, false, true)
reaper.OnPlayButton()
reaper.SetEditCurPos(cur_pos, false, false)