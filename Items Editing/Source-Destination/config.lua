--[[
@noindex
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

local config = {}
config.params = {}
config.SECTION = "ply_sd_edit"

-- parameters and defaults
config.params = {
  {
    name = "xfade_len_ms",
    description = "Cross-fade length in miliseconds. When negative uses media item defaults",
    default = -1,
    boolean = false,
    number = true,
    on_change = function ()
      -- create helper parameter for cross-fade length
      if config.xfade_len_ms < 0 then
        -- Preferences -> Project -> Media Item Defaults -> Overlap and crossfade items when splitting length
        local _, defsplitxfadelen = reaper.get_config_var_string("defsplitxfadelen")
        config._xfade_len = tonumber(defsplitxfadelen)
      else
        config._xfade_len = 0.001 * config.xfade_len_ms
      end
    end
  },
  {
    name = "insert",
    description = "3-point editing behaviour",
    default = true,
    boolean = true,
    display_map = { [true] = "insert", [false] = "overrride" }
  },
  {
    name = "select_edit_in_dst",
    description = "Select edit on timeline in destination project (true/false)",
    default = true,
    boolean = true
  },
  {
    name = "dst_cur_to_edit_end",
    description = "Move cursor to end of edit in destination project (true/false)",
    default = true,
    boolean = true
  },
  {
    name = "copy_markers",
    description = "Copy markers",
    default = false,
    boolean = true
  }
}

local function error(msg)
  reaper.ShowConsoleMsg("Source-destination configuration: "..msg)
end

local function toboolean(s)
  if s == "true" then
    return true
  elseif s == "false" then
    return false
  elseif s == nil then
    return nil
  else
    return s or false
  end
end

local function objectize(param)
  -- make proper objects from `param` table (in place)

  param.str2value = function(self, str) -- convert string to parameter type, returns nil if fails
    if self.boolean then
      return toboolean(str)
    elseif self.number then
      return tonumber(str)
    else
      return str
    end
  end

  param._update = function(self)
    if self.value == nil then
      config[self.name] = self.default
    else
      if self.boolean then
        local boolval = toboolean(self.value)
        if boolval == nil then
          error("boolean `"..self.name.."` is either `true` or `false`")
          boolval = self.default
        end
        config[self.name] = boolval
      elseif self.number then
        config[self.name] = tonumber(self.value)
      else
        config[self.name] = self.value
      end
    end
    if self.on_change then param.on_change() end
  end

  param.save = function(self) -- save to REAPER settings (ExtState)
    if self.value == nil then
      reaper.DeleteExtState(config.SECTION, self.name, true)
    else
      reaper.SetExtState(config.SECTION, self.name, self.value, true)
    end
  end

  param.load = function(self) -- load from REAPER settings (ExtState)
    if reaper.HasExtState(config.SECTION, self.name) then
      self:set(reaper.GetExtState(config.SECTION, self.name), false)
    else
      self:reset(false)
    end
    self:_update()
  end

  param.reset = function(self, save) -- reset parameter and ExtState
    save = save == nil and true or save
    reaper.DeleteExtState(config.SECTION, self.name, true)
    self.value = nil
    config[self.name] = self.default
    self:_update()
    if save then self:save() end
  end

  param.set = function(self, value, save) -- set parameter and ExtState
    save = save == nil and true or save
    if value == nil then
      config.reset(self, save)
    else
      self.value = tostring(value)
      self:_update()
      if save then self:save() end
    end
  end

  param.display = function(self)
    local value = self.value ~= nil and self.value or self.default
    if self.display_map then
      return self.display_map[self:str2value(value)]
    else
      return tostring(value)
    end
  end

  if param.boolean == true then -- additionals for booleans
    param.toggle = function(self)
      if self.value == nil then
        self:set(self.default)
      else
        self:set(not toboolean(self.value))
      end
      self:_update()
    end
  end
end

for _, param in ipairs(config.params) do
  objectize(param)
end

function config.load()
  -- load configuration and fill missing values with defaults
  for _, param in ipairs(config.params) do
    param:load()
  end
end

function config.save()
  -- save all configuration (from config.params[].value)
  for _, param in ipairs(config.params) do
    param:save()
  end
end

--------------------------------------------------------------------------------

config.load()
return config