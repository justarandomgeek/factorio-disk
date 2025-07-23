local new_reader = require("reader")

script.on_init(function ()
  ---@class (exact) DiskStorage
  ---@field readers {[integer?]:DiskReader}  # integer? so unit_number works with it...
  storage = {
    readers = {},
  }
end)

script.on_event(defines.events.on_tick, function()
  for unit_number, reader in pairs(storage.readers) do
    if reader:valid() then
      reader:on_tick()
    else
      reader:destroy()
      storage.readers[unit_number] = nil
    end
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

script.on_event(defines.events.on_entity_settings_pasted, function (event)
  local destination = event.destination
  if destination.name == "diskreader" then
    storage.readers[destination.unit_number]:on_entity_settings_pasted(event.source)
  end
end)

do
  ---@param event EventData.CustomInputEvent
  local function on_fast_entity_transfer(event)
    local player = game.get_player(event.player_index)
    ---@cast player -?
    local selected = player.selected
    if (not selected) or selected.name~="diskreader" then return end
    local reader = storage.readers[selected.unit_number]
    if not reader then return end
    if player.is_cursor_empty() then
      reader:take_disk(player)
    else
      local cursor = player.cursor_stack
      if not cursor then return end
      if cursor.name == "disk" then
        reader:put_disk(cursor)
      end
    end
  end
  script.on_event(prototypes.custom_input["disk-fast-entity-transfer"], on_fast_entity_transfer)
  script.on_event(prototypes.custom_input["disk-fast-entity-split"], on_fast_entity_transfer)
end

remote.add_interface('disk',{

})
