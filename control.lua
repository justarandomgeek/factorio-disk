local signalblacklist = {["signal-diskreader-read"]=true, ["signal-diskreader-write"]=true, ["signal-diskreader-status"]=true}

local function onTickManager(manager)
  if manager.clearcc2 then
    manager.clearcc2 = nil
    manager.cc2.get_or_create_control_behavior().parameters=nil
  end

  local disk, hasDisk = manager.ent.get_inventory(defines.inventory.furnace_source)[1], false
  local ejectedDisk, hasEjectedDisk = manager.ent.get_inventory(defines.inventory.furnace_result)[1], false
  if disk and disk.valid_for_read and disk.name=="disk" then hasDisk = true end
  if ejectedDisk and ejectedDisk.valid_for_read and ejectedDisk.name=="disk" then hasEjectedDisk = true end


  local state = 0

  -- read cc1 signals. Only uses one wire, red if both connected.
  local signet1 = manager.cc1.get_circuit_network(defines.wire_type.red) or manager.cc1.get_circuit_network(defines.wire_type.green)
  if signet1 and signet1.signals and #signet1.signals > 0 then
    local readsig = signet1.get_signal({name="signal-diskreader-read",type="virtual"})
    if readsig ~= 0 then
      if readsig == -1 then
        -- eject disk
        if not hasDisk then
          state = -1  -- ERR_NO_DISK
        elseif hasEjectedDisk then
          state = -2  -- ERR_MACHINE_BLOCKED
        else
          manager.ent.get_inventory(defines.inventory.furnace_result)[1].set_stack(disk)
          disk.clear()
          state = 1  -- DISK_OP_OK
        end
      elseif readsig > 0 and readsig <= 512 then
        -- read a frame to cc2
        if not hasDisk then
          state = -1  -- ERR_NO_DISK
        else
          local diskdata = disk.get_tag("disk_"..readsig)
          if diskdata then
            -- bog up the output combinator port now, mark for clear
            diskdata[#diskdata+1] = {index=#diskdata+1, count=1, signal={name="signal-diskreader-status",type="virtual"}}
            manager.cc2.get_or_create_control_behavior().parameters={parameters = diskdata}
            manager.clearcc2 = true
            state = 0 -- state already reported with read data
          end
        end
      else
        state = -3  -- ERR_ILLEGAL_READ
      end
    else
      local writesig = signet1.get_signal({name="signal-diskreader-write",type="virtual"})
      if writesig > 0 and writesig <= 512 then
        -- write data from cc1 with read/write stripped
        if not hasDisk then
          state = -1  -- ERR_NO_DISK
        else
          local storeframe = {}
          for i,signal in pairs(signet1.signals) do
            if not signalblacklist[signal.signal.name] then
              storeframe[#storeframe+1] = {index=#storeframe+1, count=signal.count, signal=signal.signal}
            end
          end
          if #storeframe > 0 then
            disk.set_tag("disk_"..writesig, storeframe)
          else
            disk.set_tag("disk_"..writesig, nil)
          end
          state = 1  -- DISK_OP_OK
        end
      elseif writesig == -1 then
        -- erase disk (configurable, perhaps?)
        if not hasDisk then
          state = -1  -- ERR_NO_DISK
        else
          for i = 1, 512 do
            disk.set_tag("disk_"..i, nil)
          end
          state = 1 -- DISK_OP_OK
        end
      elseif writesig ~= 0 then
        state = -4  --- ERR_ILLEGAL_WRITE
      end
    end

    -- if nonblank resultstate, send state
    if state ~= 0 then
      manager.cc2.get_or_create_control_behavior().parameters={parameters = {{index=1, count=state, signal={name="signal-diskreader-status",type="virtual"}}}}
      manager.clearcc2 = true
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

local function onCursorStackChanged(event)
  local player = game.players[event.player_index]
  if player.cursor_stack.valid_for_read and player.cursor_stack.name == "disk" then
    local frame = player.gui.left.add{type="frame", name="diskgui"}
    local textbox = frame.add{type="textfield", name="disk-string-text"}
    if table_size(player.cursor_stack.tags) == 0 then
      textbox.text = "EMPTY DISK"
    else
      textbox.text = player.cursor_stack.export_stack()
    end
  else
    local frame = player.gui.left["diskgui"]
    if frame then
      frame.destroy()
    end
  end
end

script.on_event(defines.events.on_tick, onTick)
script.on_event(defines.events.on_built_entity, onBuilt)
script.on_event(defines.events.on_robot_built_entity, onBuilt)
script.on_event(defines.events.on_player_cursor_stack_changed, onCursorStackChanged)
--on_gui_checked_state_changed
--on_gui_click
--on_gui_elem_changed
--on_gui_selection_state_changed



remote.add_interface('disk',{

})
