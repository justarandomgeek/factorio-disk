local new_reader = require("reader")
local gui = require("gui")

script.on_init(function ()
  ---@class (exact) DiskStorage
  ---@field readers {[integer?]:DiskReader}  # integer? so unit_number works with it...
  ---@field ghost_readers {[integer?]:DiskReader}  # integer? so unit_number works with it...
  ---@field refs {[integer]:{[string]: LuaGuiElement}} # player_index, element ref name
  ---@field opened_readers {[integer?]:DiskReader} # player_index
  storage = {
    readers = {},
    ghost_readers = {},
    refs = {},
    opened_readers = {}
  }
end)

script.on_configuration_changed(function (change)
  storage = {
    readers = storage.readers or {},
    ghost_readers = storage.ghost_readers or {},
    refs = storage.refs or {},
    opened_readers = storage.opened_readers or {}
  }
end)

---@param collection {[integer?]:{ valid:(fun(self:self):boolean), (on_tick:fun(self:self)), (destroy:fun(self:self))  }}
local function tick_or_cleanup(collection)
  for unit_number, obj in pairs(collection) do
    if obj:valid() then
      obj:on_tick()
    else
      obj:destroy()
      collection[unit_number] = nil
    end
  end
end

script.on_event(defines.events.on_tick, function()
  tick_or_cleanup(storage.readers)
  tick_or_cleanup(storage.ghost_readers)
  gui.on_tick()
end)

---@param entity LuaEntity
---@return DiskReader
local function get_or_create_ghost_reader(entity)
  local ghost_reader = storage.ghost_readers[entity.unit_number]
  if not ghost_reader then
    ghost_reader = new_reader(entity)
    storage.ghost_readers[entity.unit_number] = ghost_reader
  end
  return ghost_reader
end

script.on_event(defines.events.on_gui_opened, function (event)
  local entity = event.entity
  if not entity then return end
  local reader 
  if entity.name == "diskreader" then
    reader = storage.readers[entity.unit_number]
  elseif entity.name == "entity-ghost" and entity.ghost_name == "diskreader" then
    reader = get_or_create_ghost_reader(entity)
  end
  if reader then
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    gui.open(reader, player)
  end
end)

script.on_event(defines.events.on_script_trigger_effect, function (event)
  if event.effect_id == "diskreader-created" then
    local ent = event.cause_entity
    if ent and ent.name == "diskreader" then
      storage.readers[ent.unit_number]=new_reader(ent)
    end
  end
end)

do
  ---@param event {entity:LuaEntity, buffer:LuaInventory}
  local function on_mined_entity(event)
    storage.readers[event.entity.unit_number]:take_disk(event.buffer)
  end
  local filters = {{filter="name", name="diskreader"}}
  script.on_event(defines.events.on_player_mined_entity, on_mined_entity, filters)
  script.on_event(defines.events.on_robot_mined_entity, on_mined_entity, filters)
  script.on_event(defines.events.on_space_platform_mined_entity, on_mined_entity, filters)
end

script.on_event(defines.events.on_pre_entity_settings_pasted, function (event)
  local destination = event.destination
  if destination.name == "entity-ghost" and destination.ghost_name == "diskreader" then
    -- prepare a ghost_reader with the old settings...
    get_or_create_ghost_reader(destination)
  end
end)

script.on_event(defines.events.on_entity_settings_pasted, function (event)
  local destination = event.destination
  if destination.name == "diskreader" then
    storage.readers[destination.unit_number]:on_entity_settings_pasted(event.source)
  elseif destination.name == "entity-ghost" and destination.ghost_name == "diskreader" then
    get_or_create_ghost_reader(destination):on_entity_settings_pasted(event.source)
  end
end)

do
  local allow_controller_types = {
    [defines.controllers.character] = true,
    [defines.controllers.editor] = true,
    [defines.controllers.god] = true,
  }

  ---@param event EventData.CustomInputEvent
  local function on_fast_entity_transfer(event)
    local player = game.get_player(event.player_index)
    ---@cast player -?
    if not allow_controller_types[player.controller_type] then return end
    local selected = player.selected
    if not (selected and selected.name=="diskreader" and player.can_reach_entity(selected)) then return end
    local reader = storage.readers[selected.unit_number]
    if not reader then return end
    if player.is_cursor_empty() then
      reader:take_disk(player)
      player.play_sound{
          path = "item-move/disk",
      }
    else
      local cursor = player.cursor_stack
      if not (cursor and cursor.valid_for_read) then return end
      if cursor.name == "disk" then
        reader:put_disk(cursor)
        player.play_sound{
            path = "item-move/disk",
        }
      end
    end
  end
  script.on_event(prototypes.custom_input["disk-fast-entity-transfer"], on_fast_entity_transfer)
  script.on_event(prototypes.custom_input["disk-fast-entity-split"], on_fast_entity_transfer)
end

remote.add_interface('disk',{

})
