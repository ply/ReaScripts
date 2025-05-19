--[[
@noindex

Source-Destination editing configuration manager
This file is a part of "Source-Destination edit" package.
Check "ply_Source-Destination edit.lua" for more information.

Copyright (C) 2020--2025 Paweł Łyżwa

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

package.path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')..'?.lua'
local config = require("config")
local gfxu = require("gfxu")
local TITLE = "Source-Destination - configure"

local fonts = {} -- font IDs passed to gfx.setfont(), initialized in set_fonts()
local colors = {}
local get_pad = function() return 3 * gfx.ext_retina end
local last_mouse_cap = 0

local function set_fonts()
  if #fonts == 0 then
    for i, v in ipairs({"main", "main_b", "hint", "value", "defvalue"}) do
      fonts[v] = i
    end
  end

  local fontsize = 16
  gfxu.set_font(fonts.main, "verdana", fontsize)
  gfxu.set_font(fonts.main_b, "verdana", fontsize, "b")
  gfxu.set_font(fonts.hint, "verdana", 0.8*fontsize, "i")
  gfxu.set_font(fonts.value, "courier", fontsize, "b")
  gfxu.set_font(fonts.defvalue, "courier", fontsize)
end

local function init()
  gfx.ext_retina = 1.0 -- enable high resolution support
  gfx.init()

  -- colors
  local color_map = {
    text = "col_main_text",
    bg = "col_main_bg",
    hover_bg = "col_main_editbg",
  }
  for k, v in pairs(color_map) do
    local r, g, b = reaper.ColorFromNative(reaper.GetThemeColor(v, 0))
    colors[k] = {
      r = r/255,
      g = g/255,
      b = b/255,
      a = nil,
      set = function() gfx.set(r/255, g/255, b/255) end
    }
    setmetatable(colors[k], { __call = colors[k].set })
  end

  -- window size
  set_fonts()
  local width = gfx.measurestr("x")*70 + 2*get_pad()
  local height = gfx.texth * (#config.params + 1.5) + 2*get_pad()

  gfx.quit()
  gfx.init(TITLE, width, height)
end

local function run()
  if gfx.getchar(-1) == -1 then return end -- window is closed, no need to draw

  -- update mouse event status
  local mouse_evt = 0
  if last_mouse_cap == 0 then
    last_mouse_cap = gfx.mouse_cap
  elseif gfx.mouse_cap == 0 then
    mouse_evt = last_mouse_cap
    last_mouse_cap = 0
  end

  local pad = get_pad()
  set_fonts() -- needs to be updated constantly, because gfx.ext_retina can change
  gfxu.fill(colors.bg)
  gfxu.go(pad, pad)

  local mouse_over_line = nil
  if gfx.mouse_x > 0 and gfx.mouse_x < gfx.w
     and gfx.mouse_y > pad and gfx.mouse_y < (gfx.h - pad)
  then
    mouse_over_line = math.ceil((gfx.mouse_y - pad) / gfx.texth)
  end

  for i, param in ipairs(config.params) do
    gfx.setfont(fonts.main)

    if mouse_over_line == i then
      gfxu.fill(colors.hover_bg, gfx.x, gfx.y, gfx.w-2*pad, gfx.texth)
      if mouse_evt == 1 then -- left click
        if param.enum then
          param:switch()
        else
          local function get_value_from_user()
            local ok, new_value = reaper.GetUserInputs(TITLE, 1, param.name, tostring(param.value or param.default))
            new_value = param:str2value(new_value)
            if ok then
              if new_value == nil then
                reaper.ShowMessageBox("Error: invalid input! Please try again", TITLE, 0)
                get_value_from_user()
                return
              end
              param:set(new_value)
            end
          end
          reaper.defer(get_value_from_user)
        end
      elseif mouse_evt == 2 then -- right click
        param:reset()
      end
    end
    gfxu.draw_str(param.description, colors.text)

    if param.value ~= nil then
      gfx.setfont(fonts.value)
    else
      gfx.setfont(fonts.defvalue)
    end

    gfxu.go(gfx.w-pad)
    gfxu.rdraw_str(param.value_str)
    gfxu.newline(pad)
  end

  gfx.setfont(fonts.hint)
  gfxu.go(gfx.w-pad, gfx.h-pad-gfx.texth)
  gfxu.rdraw_str("Left click to change, right click to reset", colors.text)

  gfx.update()
  reaper.defer(run)
end

init()
run()
