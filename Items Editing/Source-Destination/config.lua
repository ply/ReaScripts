--[[
@noindex
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

local config = {}
config.params = {}
config.SECTION = "ply_sd_edit"

-- enums
config.enums = {
  boolean = {
    -- special enum, as boolean values require additional handling
    -- when loading and saving the configuration
    no = false, -- stored as 0
    yes = true, -- stored as 1
  },
  behaviour = {
    override = 0,
    insert = 1,
  },
  item_selection = {
    new_items = 1,
    crossfade = 2,
  },
  move_cursor = {
    no = 0,
    start = 1,
    end_ = 2,
  }
}


-- parameters and defaults
config.params = {
  {
    name = "xfade_len_ms",
    description = "Cross-fade length in miliseconds. When negative uses media item defaults",
    default = -1,
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
    name = "behaviour",
    description = "3-point editing behaviour",
    enum = config.enums.behaviour,
    default = config.enums.behaviour.insert,
  },
  {
    name = "item_selection",
    description = "Item selection in destination project",
    enum = config.enums.item_selection,
    default = config.enums.item_selection.crossfade,
  },
  {
    name = "select_edit_in_dst",
    description = "Select edit on timeline in destination project",
    enum = config.enums.boolean,
    default = true,
  },
  {
    name = "move_cursor",
    description = "Move cursor to edit",
    enum = config.enums.move_cursor,
    default = config.enums.move_cursor.end_,
  },
  {
    name = "copy_markers",
    description = "Copy markers",
    enum = config.enums.boolean,
    default = false,
  }
}

-- helper functions
local function error(msg)
  reaper.ShowConsoleMsg("Source-destination configuration: "..msg.."\n")
end

-- populate helper tables
for name, enum in pairs(config.enums) do
  enum._nameof = {} -- reverse mappings for enums
  enum._values = {} -- enum values to iterate through when switching (ordered)
  enum._idxof = {}  -- reverse mapping for _values

  for k, v in pairs(enum) do
    if k:sub(1, 1) ~= "_" then -- ignore keys starting with "_"
      enum._nameof[v] = k
      table.insert(enum._values, v)
    end
  end
  if name ~= "boolean" then -- boolean values can't be compared
    table.sort(enum._values)
  end
  for i, v in ipairs(enum._values) do
    enum._idxof[v] = i
  end
end

-- make proper objects from `param` table (in place)
for _, param in ipairs(config.params) do
  param.str2value = function(self, str) -- convert string to parameter type, returns nil if fails
    if self.number then
      return tonumber(str)
    elseif self.enum then
      if self.enum == config.enums.boolean then
        local map = {
          ["0"] = false, ["1"] = true,
          ["false"] = false, ["true"] = true,  -- for backwards compatibility
        }
        local boolval = map[str]
        if boolval == nil then
          error("invalid value for "..self.name..": "..str)
        end
        return boolval
      else
        return tonumber(str)
      end
    else
      return str
    end
  end

  param.load = function(self) -- load from REAPER settings (ExtState)
    if reaper.HasExtState(config.SECTION, self.name) then
      self:set(self:str2value(reaper.GetExtState(config.SECTION, self.name)), false)
    else
      self:reset(false)
    end
  end

  param.save = function(self) -- save to REAPER settings (ExtState)
    if self.value == nil then
      reaper.DeleteExtState(config.SECTION, self.name, true)
    elseif self.enum == config.enums.boolean then
      reaper.SetExtState(config.SECTION, self.name, tostring(self.value and 1 or 0), true)
    else
      reaper.SetExtState(config.SECTION, self.name, tostring(self.value), true)
    end
  end

  param.set = function(self, value, save)
    self.value = value
    if value == nil then
      config[self.name] = self.default
    else
      config[self.name] = value
    end

    if self.enum then
      local name = self.enum._nameof[config[self.name]]
      if name == nil then
        self.value_str = tostring("<"..config[self.name]..">")
      else
        -- remove trailing underscores
        while #name > 0 and name:sub(#name) == "_" do
          name = name:sub(1, #name-1)
        end
        self.value_str = name:gsub("_", " ")
      end
    else
      self.value_str = tostring(config[self.name])
    end

    if save or save == nil then self:save() end
    if self.on_change then param.on_change() end
  end

  param.reset = function(self, save)
    self:set(nil, save)
  end

  if param.enum then
    param.switch = function(self)
      if self.value == nil then
        self:set(self.default)
      else
        local idx = self.enum._idxof[self.value]
        if idx == nil or idx == #self.enum._values then
          idx = 1
        else
          idx = idx + 1
        end
        self:set(self.enum._values[idx])
      end
    end
  end
end

--------------------------------------------------------------------------------

function config.load()
  -- load configuration and fill missing values with defaults
  for _, param in ipairs(config.params) do
    -- handle configuration stored in an old way for backward compatibility
    if param.name == "behaviour" and reaper.HasExtState(config.SECTION, "insert") then
      local value = reaper.GetExtState(config.SECTION, "insert")
      reaper.DeleteExtState(config.SECTION, "insert", true)
      if value == "true" then
        param:set(param.enum.insert)
      elseif value == "false" then
        param:set(param.enum.override)
      end
    elseif param.name == "move_cursor" and reaper.HasExtState(config.SECTION, "dst_cur_to_edit_end") then
      local value = reaper.GetExtState(config.SECTION, "dst_cur_to_edit_end")
      reaper.DeleteExtState(config.SECTION, "dst_cur_to_edit_end", true)
      if value == "false" then
        param:set(param.enum.no)
      elseif value == "true" then
        param:set(param.enum.end_)
      end
    else -- load current configuration
      param:load()
    end
  end
end

function config.save()
  -- save all configuration (from config.params[].value)
  for _, param in ipairs(config.params) do
    param:save()
  end
end

config.load()
return config
