-- @description Synchronize and heal selected media items
-- @version 0.1
-- @author Paweł Łyżwa (ply)
-- @changelog
--   + Initial release

NAME = "Synchronize and heal selected media items"

n_items = reaper.CountSelectedMediaItems(0)
run = false
if n_items < 2 then
  reaper.ShowMessageBox("You should have selected 2 item to synchronize", "Error", 0)
elseif n_items > 2 then
  ret = reaper.ShowMessageBox("You have selected more than 2 items. This script would synchronize only first 2 of them. Do you want to continue?", "Warning", 4)
  if ret == 6 then
    run = true
  end
else
  run = true
end

if run then
  reaper.Undo_BeginBlock()
  
  item0 = reaper.GetSelectedMediaItem(0, 0)
  take0 = reaper.GetMediaItemTake(item0, reaper.GetMediaItemInfo_Value(item0, "I_CURTAKE"))
  position0 = reaper.GetMediaItemInfo_Value(item0, "D_POSITION")
  take_offset0 = reaper.GetMediaItemTakeInfo_Value(take0, "D_STARTOFFS")
  
  item1 = reaper.GetSelectedMediaItem(0, 1)
  take1 = reaper.GetMediaItemTake(item1, reaper.GetMediaItemInfo_Value(item1, "I_CURTAKE"))
  position1 = reaper.GetMediaItemInfo_Value(item1, "D_POSITION")
  take_offset1 = reaper.GetMediaItemTakeInfo_Value(take1, "D_STARTOFFS")
  
  nudge = position0 - take_offset0 - position1 + take_offset1
  
  reaper.SelectAllMediaItems(0, false)
  reaper.SetMediaItemSelected(item1, true)
  reaper.ApplyNudge(0, 0, 0, 1, nudge, false, 0)
  reaper.SetMediaItemSelected(item0, true)
  
  reaper.Main_OnCommand(40548, 0) -- Heal splits in items
  
  reaper.Undo_EndBlock(NAME, 0)
  reaper.UpdateArrange()
end