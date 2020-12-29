--[[
@noindex
This file is a part of "Source-Destination edit" package

gfxu - REAPER GFX utilities Lua library
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

local gfxu = {}

function gfxu.get_color()
  return {
    r = gfx.r,
    g = gfx.g,
    b = gfx.b,
    a = gfx.a
  }
end

function gfxu.set_color(color)
  gfx.set(color.r, color.g, color.b, color.a or gfx.a)
end

function gfxu.fill(color, x, y, w, h)
  gfxu.set_color(color)
  gfx.rect(x or 0, y or 0, w or gfx.w, h or gfx.h, true)
end

function gfxu.go(x, y)
  gfx.x = x
  if y then gfx.y = y end
end

function gfxu.newline(pad)
  gfx.x = pad or 0
  gfx.y = gfx.y + gfx.texth
end

function gfxu.draw_str(str, text_color, bg_color)
  if bg_color then
    gfxu.fill(bg_color, gfx.x, gfx.y, gfx.measurestr(str), gfx.texth)
  end
  if text_color then
    gfxu.set_color(text_color)
  end
  gfx.drawstr(str)
end

function gfxu.rdraw_str(str, text_color, bg_color)
  gfx.x = gfx.x - gfx.measurestr(str)
  gfxu.draw_str(str, text_color, bg_color)
end

-- DPI-aware gfx.setfont() wrapper, which accepts flags as string
function gfxu.set_font(idx, fontface, size, flags_str)
  if flags_str then
    local flags = 0
    for i = 1, flags_str:len() do
      flags = flags*256 + flags_str:byte(i)
    end
    gfx.setfont(idx, fontface, size*gfx.ext_retina, flags)
  elseif size then
    gfx.setfont(idx, fontface, size*gfx.ext_retina)
  elseif fontface then
    gfx.setfont(idx, fontface)
  else
    gfx.setfont(idx)
  end
end

return gfxu
