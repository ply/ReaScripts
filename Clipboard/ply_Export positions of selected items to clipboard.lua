--[[
@description Export positions of selected items to clipboard
@version 1.1
@author Paweł Łyżwa (ply)
@changelog fix metadata header comment syntax
]]--

function time2str (t)
	return string.format("% 4d:%06.3f", t//60, t%60)
end

output = "POSITION\tEND\tNAME\tSRC_START\tSRC_END\n"

proj = 0 -- active project
for i = 0, reaper.CountSelectedMediaItems(proj)-1, 1 do
	item = reaper.GetSelectedMediaItem(proj, i)
	take = reaper.GetMediaItemTake(item, reaper.GetMediaItemInfo_Value(item, "I_CURTAKE"))
	len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
	pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	src_start = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")

	cols = {
		time2str(pos), 
		time2str(pos + len),
		reaper.GetTakeName(take),
		time2str(src_start),
		time2str(src_start + len)
	}

	output = output..table.concat(cols, "\t").."\n"
end

reaper.CF_SetClipboard(output)