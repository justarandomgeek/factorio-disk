local sigstr = script.active_mods["signalstrings"] and require("__signalstrings__/signalstrings.lua")

---@class (exact) DiskReader
---@field public entity LuaEntity
---@field private unit_number integer
---@field public control LuaDeciderCombinatorControlBehavior
---@field private chest? LuaEntity
---@field public stack? LuaItemStack
---@
---@field public write_signal? SignalID
---@field public read_signal? SignalID
---@field public flip_wires? boolean # true = data red/control green, false = data green/control red
---@
---@field public itemid_high_signal? SignalID
---@field public itemid_low_signal? SignalID
---@field public userid_signal? SignalID
---@field public pagecount_signal? SignalID
local reader={}

---@type metatable
local reader_meta = {
    __index = reader,
}

script.register_metatable("DiskReader", reader_meta)

---@param ent LuaEntity
---@return DiskReader
local function new(ent)
  local is_ghost = ent.type == "entity-ghost"
  local control = ent.get_or_create_control_behavior() --[[@as LuaDeciderCombinatorControlBehavior]]

  local chest, stack
  if not is_ghost then
    chest = ent.surface.create_entity{
      name = "diskreader-chest",
      position = ent.position,
      force = ent.force,
      direction = ent.direction,
    }
    ---@cast chest -?
    chest.destructible = false

    local inv = chest.get_inventory(defines.inventory.chest)
    ---@cast inv -?
    inv.set_bar(nil)
    inv.set_filter(1, "disk")
    stack = inv[1]
  end

  local self = setmetatable({
    entity = ent,
    unit_number = ent.unit_number,
    control = control,
    chest = chest,
    stack = stack,
  }, reader_meta)
  control.parameters = self:load_entity_settings()
  return self
end

local control_wire = {
  [true] = defines.wire_connector_id.combinator_input_green,
  [false] = defines.wire_connector_id.combinator_input_red,
}

---@type {[string]:SignalID}
local default_signal = {
  read = {
    type = "virtual",
    name = "signal-output",
    quality = "normal",
  },
  write = {
    type = "virtual",
    name = "signal-input",
    quality = "normal",
  },

  itemid_high = {
    type = "virtual",
    name = "signal-0",
    quality = "normal",
  },
  itemid_low = {
    type = "virtual",
    name = "signal-1",
    quality = "normal",
  },
  userid = {
    type = "virtual",
    name = "signal-info",
    quality = "normal",
  },
  pagecount = {
    type = "virtual",
    name = "signal-stack-size",
    quality = "normal",
  },
}

---@type {[SignalIDType]:LuaCustomTable<string>}
local typeinfos = {
  item = prototypes.item,
  fluid = prototypes.fluid,
  virtual = prototypes.virtual_signal,
  recipe = prototypes.recipe,
  entity = prototypes.entity,
  ["space-location"] = prototypes.space_location,
  quality = prototypes.quality,
  ["asteroid-chunk"] = prototypes.asteroid_chunk,
}

local no_wires = {red=false, green=false}

---@package
---@return DeciderCombinatorParameters
function reader:load_entity_settings()
  local param = self.control.parameters
  local conditions = param.conditions
  if #conditions == 4 then
    self.flip_wires = conditions[2].first_signal_networks.red
    self.read_signal = conditions[2].first_signal
    self.write_signal = conditions[2].second_signal
    self.itemid_high_signal = conditions[3].first_signal
    self.itemid_low_signal = conditions[3].second_signal
    self.userid_signal = conditions[4].first_signal
    self.pagecount_signal = conditions[4].second_signal
  elseif #conditions == 2 then -- old config
    self.flip_wires = conditions[2].first_signal_networks.red
    self.read_signal = conditions[2].first_signal
    self.write_signal = conditions[2].second_signal
    self.itemid_high_signal = default_signal.itemid_high
    self.itemid_low_signal = default_signal.itemid_low
    self.userid_signal = default_signal.userid
    self.pagecount_signal = default_signal.pagecount
  else -- no config
    self.flip_wires = nil
    self.read_signal = default_signal.read
    self.write_signal = default_signal.write
    self.itemid_high_signal = default_signal.itemid_high
    self.itemid_low_signal = default_signal.itemid_low
    self.userid_signal = default_signal.userid
    self.pagecount_signal = default_signal.pagecount
  end
  param.conditions = self:save_entity_settings()
  return param
end

---@private
---@return DeciderCombinatorCondition[]
function reader:save_entity_settings()
  local has_disk = self.stack and self.stack.valid_for_read
  ---@type DeciderCombinatorCondition[]
  return {
    -- always on condition to skip processing the rest...
    {
      first_signal_networks=no_wires,
      comparator=has_disk and "=" or "≠",
      constant=0,
      second_signal_networks=no_wires,
      -- first compare_type does nothing...
    },
    -- and the rest hold config data...
    {
      comparator="=",
      first_signal = self.read_signal,
      first_signal_networks={
        red=not not self.flip_wires,
        green = false},
      second_signal = self.write_signal,
      second_signal_networks=no_wires,
      compare_type = has_disk and "or" or "and", -- how the config group combines with the first condition
    },
    {
      comparator="=",
      first_signal = self.itemid_high_signal,
      first_signal_networks=no_wires,
      second_signal = self.itemid_low_signal,
      second_signal_networks=no_wires,
      compare_type = "and" -- any future config rows should be plain ands to make one big config group...
    },
    {
      comparator="=",
      first_signal = self.userid_signal,
      first_signal_networks=no_wires,
      second_signal = self.pagecount_signal,
      second_signal_networks=no_wires,
      compare_type = "and"
    },
  }
end

---@public
function reader:on_gui_changed_settings()
  self.control.parameters = {
    conditions = self:save_entity_settings(),
    outputs = {},
  }
end

---@public
---@param from LuaEntity
function reader:on_entity_settings_pasted(from)
  if from.name ~= "diskreader" then
    self.control.parameters = {
      conditions = self:save_entity_settings(),
      outputs = {},
    }
  end
end

local info_page_ls = { "diskreader-gui.status-info-page" }
local disk_label_ls = { "diskreader-gui.status-disk-label" }
local disk_clear_ls = { "diskreader-gui.status-clear" }
local satus_idle_ls = { "diskreader-gui.status-idle" }
local no_disk_status = {
  diode = defines.entity_status_diode.yellow,
  label = { "diskreader-gui.status-no-disk" },
}

---@public
function reader:on_tick()
  local entity = self.entity
  local control = self.control

  -- clear the outputs, and make sure the config is fresh in conditions
  local param = self:load_entity_settings()
  ---@type DeciderCombinatorOutput[]
  local outputs = {}
  param.outputs = outputs

  local stack = self.stack
  if stack then -- nil for ghosts
    if not stack.valid_for_read then
      entity.custom_status = no_disk_status
    else
      local did_read, did_write
      local flip = not not self.flip_wires
      local wire = control_wire[flip]
      if self.read_signal then
        local readcmd = entity.get_signal(self.read_signal, wire)
        if readcmd ~= 0 then
          if readcmd >= 1 and readcmd <= 512 then
            did_read = { "diskreader-gui.status-read", readcmd }
            -- read a data frame
            local diskdata = stack.get_tag("disk_data_"..readcmd)
            if type(diskdata) == "table" then
              ---@cast diskdata Signal[]
              -- validate disk data is all valid
              local i = 1
              for _,data in pairs(diskdata) do
                local signal = data.signal
                local stype = signal.type or "item"
                local info = typeinfos[stype]
                local sname = signal.name
                local sig_valid = info and info[sname]
                local qname = signal.quality or "normal"
                local qual_valid = typeinfos.quality[qname]
                if sig_valid and qual_valid then
                  outputs[i] = {
                    signal = {
                      type = stype,
                      name = sname,
                      quality = qname,
                    },
                    copy_count_from_input = false,
                    constant = data.count,
                  }
                  i = i+1
                end
              end
            else
              stack.remove_tag("disk_data_"..readcmd)
            end
          elseif readcmd == -1 then
            did_read = { "diskreader-gui.status-read", info_page_ls }
            -- read disk info
            -- stack.item_number on [0]high [1]low
            if self.itemid_high_signal then
              outputs[#outputs+1] = {
                signal = self.itemid_high_signal,
                copy_count_from_input = false,
                constant = math.floor(stack.item_number/0x100000000),
              }
            end
            if self.itemid_low_signal then
              outputs[#outputs+1] = {
                signal = self.itemid_low_signal,
                copy_count_from_input = false,
                constant = math.fmod(stack.item_number, 0x100000000),
              }
            end
            -- stack.get_tag("disk_id") on [info]
            if self.userid_signal then
              local info = stack.get_tag("disk_id")
              if type(info) == "number" then
                outputs[#outputs+1] = {
                  signal = self.userid_signal,
                  copy_count_from_input = false,
                  constant = info,
                }
              else
                stack.remove_tag("disk_id")
              end
            end

            if self.pagecount_signal then
              local count = 0
              --for _, tag in pairs(stack.get_tag_names()) do
              for tag in pairs(stack.tags) do
                if string.match(tag, "^disk_data_%d+$") then
                  count = count + 1
                end
              end
              outputs[#outputs+1] = {
                signal = self.pagecount_signal,
                copy_count_from_input = false,
                constant = count,
              }
            end
          elseif readcmd == -2 then
            -- read label
            if sigstr then
              did_read = { "diskreader-gui.status-read", disk_label_ls }
              if stack.label then
                local sigs = sigstr.string_to_decider_outputs(stack.label)
                local base = #outputs
                for i, sig in pairs(sigs) do
                  outputs[base+i] = sig
                end
              end
            end
          end
        end
      end

      if self.write_signal then
        local writecmd = entity.get_signal(self.write_signal, wire)
        if writecmd ~= 0 then
          local data_wire = control_wire[not flip]
          if writecmd >= 1 and writecmd <= 512 then
            did_write = { "diskreader-gui.status-write", writecmd }
            local data = entity.get_signals(data_wire)
            if data then
              -- write a data frame
              stack.set_tag("disk_data_"..writecmd, data)
            else
              stack.remove_tag("disk_data_"..writecmd)
            end
          elseif writecmd == -1 then
            did_write = { "diskreader-gui.status-write", info_page_ls }
            -- write disk info
            -- disk_id on [info]
            local id = 0
            if self.userid_signal then
              id = entity.get_signal(self.userid_signal, data_wire)
            end
            if id ~= 0 then
              stack.set_tag("disk_id", id)
            else
              stack.remove_tag("disk_id")
            end
          elseif writecmd == -2 then
            -- write label
            if sigstr then
              did_write = { "diskreader-gui.status-write", disk_label_ls }
              local sigs = entity.get_signals(data_wire)
              if sigs then
                stack.label = sigstr.signals_to_string(sigs)
              else
                stack.label = ""
              end
            end
          elseif writecmd == -512 then
            did_write = disk_clear_ls
            -- clear disk
            local tags = {
              disk_id = stack.get_tag("disk_id"),
            }
            stack.tags = tags
          end
        end
      end

      local status_label
      if did_read and did_write then
        status_label = { "", did_read, " - ", did_write }
      elseif did_read or did_write then
        status_label = did_read or did_write
      else
        status_label = satus_idle_ls
      end
      entity.custom_status = {
        diode = defines.entity_status_diode.green,
        label = status_label,
      }
    end
  end
  control.parameters = param
end

---@public
---@param target LuaInventory|LuaPlayer
function reader:take_disk(target)
  if target.insert(self.stack) == 1 then
    self.stack.clear() -- delete it if it got taken
  end
end

---@public
---@param stack LuaItemStack
---@return boolean `true` if the disk was transferred
function reader:put_disk(stack)
  return self.stack.transfer_stack(stack)
end

---@public
function reader:valid()
  if not self.entity.valid then return false end
  if not self.control.valid then return false end
  if self.chest and not self.chest.valid then return false end
  if self.stack and not self.stack.valid then return false end
  return true
end

---@public
function reader:destroy()
  self.entity.destroy()
  if self.chest then self.chest.destroy() end
end

---@public
---@return LocalisedString
function reader:localised_name()
  if self.chest then
    return  self.entity.localised_name
  end
  return self.entity.ghost_localised_name
end

return new