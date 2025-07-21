
---@class (exact) DiskReader
---@field private entity LuaEntity
---@field private unit_number integer
---@field private control LuaDeciderCombinatorControlBehavior
---@field private chest LuaEntity
---@field private stack LuaItemStack
---@field private write_signal SignalID
---@field private read_signal SignalID
---@field private flip_wires? boolean # true = data red/control green, false = data green/control red
local reader={}

---@type metatable
local reader_meta = {
    __index = reader,
}

script.register_metatable("DiskReader", reader_meta)

---@param ent LuaEntity
---@return DiskReader
local function new(ent)
  local control = ent.get_or_create_control_behavior() --[[@as LuaDeciderCombinatorControlBehavior]]

  local chest = ent.surface.create_entity{
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

  local self = setmetatable({
    entity = ent,
    unit_number = ent.unit_number,
    control = control,
    chest = chest,
    stack = inv[1],
  }, reader_meta)
  control.parameters = self:load_entity_settings()
  return self
end

local control_wire = {
  [true] = defines.wire_connector_id.combinator_input_green,
  [false] = defines.wire_connector_id.combinator_input_red,
}

---@type SignalID
local default_read_signal = {
  type = "virtual",
  name = "signal-output",
  quality = "normal",
}

local default_write_signal = {
  type = "virtual",
  name = "signal-input",
  quality = "normal",
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
  if #conditions == 2 then
    self.flip_wires = conditions[2].first_signal_networks.red
    self.read_signal = conditions[2].first_signal or default_read_signal
    self.write_signal = conditions[2].second_signal or default_write_signal
  end
  param.conditions = self:save_entity_settings()
  return param
end

---@private
---@return DeciderCombinatorCondition[]
function reader:save_entity_settings()
  return {
    -- always on condition to skip processing the rest...
    {
      first_signal_networks=no_wires,
      comparator="=",
      constant=0,
      second_signal_networks=no_wires,
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
    }
  }
end

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
  if stack.valid_for_read then
    local flip = not not self.flip_wires
    local wire = control_wire[flip]
    local readcmd = entity.get_signal(self.read_signal, wire)
    if readcmd ~= 0 then
      if readcmd >= 1 and readcmd <= 512 then
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
        end
      elseif readcmd == -1 then
        -- read disk info
        -- stack.item_number on [0]high [1]low
        outputs[#outputs+1] = {
          signal = {
            type = "virtual",
            name = "signal-0",
          },
          copy_count_from_input = false,
          constant = math.floor(stack.item_number/0x100000000),
        }
        outputs[#outputs+1] = {
          signal = {
            type = "virtual",
            name = "signal-1",
          },
          copy_count_from_input = false,
          constant = math.fmod(stack.item_number, 0x100000000),
        }
        -- stack.get_tag("disk_id") on [info]
      end
    end

    local writecmd = entity.get_signal(self.write_signal, wire)
    if writecmd ~= 0 then
      if writecmd >= 1 and writecmd <= 512 then
        local data = entity.get_signals(control_wire[not flip])
        if data then
          -- write a data frame
          stack.set_tag("disk_data_"..writecmd, data)
        else
          stack.remove_tag("disk_data_"..writecmd)
        end
      elseif writecmd == -1 then
        -- write disk info
        -- disk_id on [info]
      elseif writecmd == -512 then
        -- clear disk
        local tags = {
          disk_id = stack.get_tag("disk_id"),
        }
        stack.tags = tags
      end
    end
  end
  control.parameters = param
end

---@public
---@param inv LuaInventory
function reader:take_disk(inv)
  if inv.insert(self.stack) == 1 then
    self.stack.clear() -- delete it if it got taken
  end
end

---@public
function reader:valid()
  if not self.entity.valid then return false end
  if not self.control.valid then return false end
  if not self.chest.valid then return false end
  if not self.stack.valid then return false end
  return true
end

---@public
function reader:destroy()
  self.entity.destroy()
  self.chest.destroy()
end

return new