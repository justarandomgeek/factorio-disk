local json = require('dkjson')
--TODO: create in-game editor interface and import/export strings for tapes

local signalblacklist = {["signal-diskreader-read"]=true, ["signal-diskreader-write"]=true}

local function onTickManager(manager)
  if manager.clearcc2 then
    manager.clearcc2 = nil
    manager.cc2.get_or_create_control_behavior().parameters=nil
  end

  local tape = manager.ent.get_inventory(defines.inventory.furnace_source)[1]
  if tape and tape.valid_for_read and tape.name=="disk" then

    -- read cc1 signals. Only uses one wire, red if both connected.
    local signet1 = manager.cc1.get_circuit_network(defines.wire_type.red) or manager.cc1.get_circuit_network(defines.wire_type.green)
    if signet1 and signet1.signals and #signet1.signals > 0 then
      local readsig = signet1.get_signal({name="signal-diskreader-read",type="virtual"})
      if readsig ~= 0 then
        if readsig == -1 then
          -- eject tape
          manager.ent.get_inventory(defines.inventory.furnace_result)[1].set_stack(tape)
          tape.clear()

        elseif readsig > 0 and readsig <= 512 then
          -- read a frame to cc2
          local tapedata = tape.get_tag("disk_"..readsig)
          manager.cc2.get_or_create_control_behavior().parameters={parameters = tapedata}
          manager.clearcc2 = true

        end
      else
        local writesig = signet1.get_signal({name="signal-diskreader-write",type="virtual"})
        if writesig > 0 and writesig <= 512 then
          -- write data from cc1 with read/write stripped
          local storeframe = {}
          for i,signal in pairs(signet1.signals) do
            if not signalblacklist[signal.signal.name] then
              storeframe[#storeframe+1] = {index=#storeframe+1, count=signal.count, signal=signal.signal}
            end
          end
          if #storeframe > 0 then
            tape.set_tag("disk_"..writesig, storeframe)
          else
            tape.set_tag("disk_"..writesig, nil)
          end

        end
      end
    end
  end
end

local function onTick()
  if global.managers then
    for _,manager in pairs(global.managers) do
      if not (manager.ent.valid and manager.cc1.valid and manager.cc2.valid) then
        -- if anything is invalid, tear it all down
        if manager.ent.valid then manager.ent.destroy() end
        if manager.cc1.valid then manager.cc1.destroy() end
        if manager.cc2.valid then manager.cc2.destroy() end
        global.managers[_] = nil
      else
        onTickManager(manager)
      end
    end
  end
end

local function CreateControl(manager,position)
  local ghost = manager.surface.find_entity('entity-ghost', position)
  if ghost then
    -- if there's a ghost here, just claim it!
    _,ghost = ghost.revive()
  end

  local ent = ghost or manager.surface.create_entity{
      name='diskreader-control',
      position = position,
      force = manager.force
    }

  ent.operable=false
  ent.minable=false
  ent.destructible=false

  return ent
end

local function onBuilt(event)
  local ent = event.created_entity
  if ent.name == "diskreader" then

    ent.active = false
    --ent.operable = false

    local cc1 = CreateControl(ent, {x=ent.position.x-1,y=ent.position.y+1.5})
    local cc2 = CreateControl(ent, {x=ent.position.x+1,y=ent.position.y+1.5})

    if not global.managers then global.managers = {} end
    global.managers[ent.unit_number]={ent=ent, cc1 = cc1, cc2 = cc2}

  end
end

local function ExportTape(tape)
  local data = {}
  for i = 1,512 do
    data[tostring(i)] = tape.get_tag("disk_"..i)
  end
  return json.encode{label=tape.label, data=data}
end

local function ImportTape(tape,data)
  local decode = json.decode(data)
  tape.label = decode.label
  tape.set_tag("disk",decode.data)
end

script.on_event(defines.events.on_tick, onTick)
script.on_event(defines.events.on_built_entity, onBuilt)
script.on_event(defines.events.on_robot_built_entity, onBuilt)

remote.add_interface('disk',{
  export = ExportTape,
  import = ImportTape,
})
