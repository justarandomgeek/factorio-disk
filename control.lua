local new_reader = require("reader")

script.on_init(function ()
  ---@class (exact) DiskStorage
  ---@field readers {[integer]:DiskReader}
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
  
end)

remote.add_interface('disk',{

})
