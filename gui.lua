local glib = require("__glib__.glib")

local gui = {}

---@type table<defines.entity_status, LocalisedString>
local status_names = {}
for k, v in pairs(defines.entity_status) do
    name = string.gsub(k, "_", "-")
    name = {"entity-status."..name}
    status_names[v] = name
end

local handlers = {}

---@param player LuaPlayer
local function update_gui(player)
    local reader = storage.opened_readers[player.index]
    if not reader then return end
    local refs = storage.refs[player.index]
    local control = reader.control

    local chest_stack = reader.stack
    if chest_stack and chest_stack.valid_for_read then
        refs.slot.sprite = "item."..chest_stack.name
    else
        refs.slot.sprite = nil
    end

    -- fields in reader are already fresh because they ticked first before the gui update
    refs.read_signal.elem_value = reader.read_signal
    refs.write_signal.elem_value = reader.write_signal
    refs.itemid_high_signal.elem_value = reader.itemid_high_signal
    refs.itemid_low_signal.elem_value = reader.itemid_low_signal
    refs.userid_signal.elem_value = reader.userid_signal
    refs.pagecount_signal.elem_value = reader.pagecount_signal

    refs.flip_wires_switch.switch_state = reader.flip_wires and "right" or "left"

    do
        local cf = refs.connections_frame
        cf.clear()
        cf.add{type = "label", style = "subheader_caption_label", caption = {"", {"gui-arithmetic.input"}, ":"}}
        local input_connector_red = control.get_circuit_network(defines.wire_connector_id.combinator_input_red)
        local input_connector_green = control.get_circuit_network(defines.wire_connector_id.combinator_input_green)
        if not input_connector_red and not input_connector_green then
            cf.add{type = "label", style = "label", caption = {"gui-control-behavior.not-connected"}}
        else
            cf.add{type = "label", style = "label", caption = {"gui-control-behavior.connected-to-network"}}
            if input_connector_red then
                cf.add{type = "label", style = "label", caption = {"gui-control-behavior.red-network-id", input_connector_red.network_id}}
            end
            if input_connector_green then
                cf.add{type = "label", style = "label", caption = {"gui-control-behavior.green-network-id", input_connector_green.network_id}}
            end
        end

        local e = cf.add{type = "empty-widget"}
        e.style.horizontally_stretchable = true

        cf.add{type = "label", style = "subheader_caption_label", caption = {"", {"gui-arithmetic.input"}, ":"}}
        local output_connector_red = control.get_circuit_network(defines.wire_connector_id.combinator_output_red)
        local output_connector_green = control.get_circuit_network(defines.wire_connector_id.combinator_output_green)
        if not output_connector_red and not output_connector_green then
            cf.add{type = "label", style = "label", caption = {"gui-control-behavior.not-connected"}}
        else
            cf.add{type = "label", style = "label", caption = {"gui-control-behavior.connected-to-network"}}
            if output_connector_red then
                cf.add{type = "label", style = "label", caption = {"gui-control-behavior.red-network-id", output_connector_red.network_id}}
            end
            if output_connector_green then
                cf.add{type = "label", style = "label", caption = {"gui-control-behavior.green-network-id", output_connector_green.network_id}}
            end
        end
    end

    refs.status_label.caption = status_names[reader.entity.status]
end

local function signal_flow(name)
    return {
        args = {type = "flow", direction = "horizontal"},
        style_mods = {vertical_align = "center"},
        {
            args = {type = "choose-elem-button", name = name, style = "slot_button_in_shallow_frame", elem_type = "signal"},
            _elem_changed = handlers[name.."_changed"]
        },
        {
            args = {type = "flow"},
            {
                args = {type = "label", style = "subheader_semibold_label", caption = {"diskreader-gui."..name}},
            },
        },
    }
end

---@param event EventData.on_gui_opened
function gui.on_gui_opened(event)
    local entity = event.entity
    if not entity or not entity.valid or entity.name ~= "diskreader" then return end
    local reader = storage.readers[entity.unit_number]
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    local refs = storage.refs[event.player_index]
    if not refs then
        storage.refs[event.player_index] = {}
        refs = storage.refs[event.player_index]
    end
    glib.add(player.gui.screen, {
        args = {type = "frame", name = "diskreader_window", direction = "vertical"},
        style_mods = {width = 448, maximal_height = 867},
        elem_mods = {auto_center = true},
        _closed = handlers.close_window,
        children = {
            {
                args = {type = "flow"},
                style_mods = {horizontal_spacing = 8},
                drag_target = "diskreader_window",
                {
                    args = {type = "label", caption = entity.localised_name, style = "frame_title", ignored_by_interaction = true},
                    style_mods = {top_margin = -3, bottom_margin = 3},
                },
                {
                    args = {type = "empty-widget", style = "draggable_space_header", ignored_by_interaction = true},
                    style_mods = {height = 24, right_margin = 4, horizontally_stretchable = true},
                },
                {
                    args = {type = "sprite-button", style = "close_button", sprite = "utility/close"},
                    _click = handlers.close_window,
                }
            },
            {
                args = {type = "frame", style = "entity_frame", direction = "vertical"},
                {
                    args = {type = "frame", name = "connections_frame", style = "subheader_frame_with_text_on_the_right"},
                    style_mods = {top_margin = -8, left_margin = -12, right_margin = -12, horizontally_stretchable = true, vertically_stretchable = true},
                    {
                        args = {type = "label", style = "subheader_caption_label", caption = {"", {"gui-arithmetic.input"}, ":"}},
                    },
                    {
                        args = {type = "empty-widget"},
                        style_mods = {horizontally_stretchable = true},
                    },
                    {
                        args = {type = "label", style = "caption_label", caption = {"", {"gui-arithmetic.output"}, ":"}},
                    },
                },
                {
                    args = {type = "flow"},
                    style_mods = {vertical_align = "center"},
                    {
                        args = {type = "sprite", name = "status_sprite", sprite = "utility.status_working"},
                    },
                    {
                        args = {type = "label", name = "status_label", caption = {"entity-status.working"}}
                    }
                },
                {
                    args = {type = "frame", style = "deep_frame_in_shallow_frame"},
                    {
                        args = {type = "entity-preview", style = "wide_entity_button"},
                        elem_mods = {entity = entity},
                    },
                },
                {
                    args = {type = "flow", direction = "horizontal"},
                    style_mods = {vertical_align = "center"},
                    {
                        args = {type = "sprite-button", name = "slot", style = "inventory_slot"},
                        _click = handlers.slot_clicked,
                    },
                    {
                        args = {type = "flow"},
                        {
                            args = {type = "label", style = "subheader_semibold_label", caption = "Disk name"},
                        },
                        {
                            args = {type = "sprite-button", style = "mini_button_aligned_to_text_vertically", sprite = "utility.rename_icon"},
                        },
                    },
                },
                {
                    args = {type = "line"},
                    style_mods = {horizontally_stretchable = true},
                },
                signal_flow("read_signal"),
                signal_flow("write_signal"),
                {
                    args = {type = "line"},
                    style_mods = {horizontally_stretchable = true},
                },
                signal_flow("itemid_high_signal"),
                signal_flow("itemid_low_signal"),
                signal_flow("userid_signal"),
                signal_flow("pagecount_signal"),
                {
                    args = {type = "flow", direction = "horizontal"},
                    style_mods = {vertical_align = "center"},
                    {
                        args = {type = "flow", direction = "vertical"},
                        {
                            args = {type = "flow", direction = "horizontal"},
                            style_mods = {vertical_align = "center"},
                            {
                                args = {type = "label", caption = {"gui-network-selector.red-label"}},
                            },
                            {
                                args = {type = "label", style = "semibold_label", caption = {"diskreader-gui.command"}},
                            },
                        },
                        {
                            args = {type = "flow", direction = "horizontal"},
                            style_mods = {vertical_align = "center"},
                            {
                                args = {type = "label", caption = {"gui-network-selector.green-label"}},
                            },
                            {
                                args = {type = "label", style = "semibold_label", caption = {"diskreader-gui.data"}},
                            },
                        }
                    },
                    {
                        args = {type = "switch", name = "flip_wires_switch"},
                        _switch_state_changed = handlers.flip_wires_switched,
                    },
                    {
                        args = {type = "flow", direction = "vertical"},
                        {
                            args = {type = "flow", direction = "horizontal"},
                            style_mods = {vertical_align = "center"},
                            {
                                args = {type = "label", caption = {"gui-network-selector.red-label"}},
                            },
                            {
                                args = {type = "label", style = "semibold_label", caption = {"diskreader-gui.data"}},
                            },
                        },
                        {
                            args = {type = "flow", direction = "horizontal"},
                            style_mods = {vertical_align = "center"},
                            {
                                args = {type = "label", caption = {"gui-network-selector.green-label"}},
                            },
                            {
                                args = {type = "label", style = "semibold_label", caption = {"diskreader-gui.command"}},
                            },
                        }
                    },
                },
                {
                    args = {type = "line"},
                    style_mods = {horizontally_stretchable = true},
                },
                {
                    args = {type = "button", name = "description_button", caption = {"gui-edit-label.add-description"}},
                    _click = handlers.edit_description,
                },
            }
        }
    }, refs)
    storage.opened_readers[event.player_index] = reader
    player.opened = refs.diskreader_window
    update_gui(player)
end

function handlers.close_window(event)
    if storage.do_not_close_gui then return end
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    player.gui.screen.diskreader_window.destroy()
    storage.opened_readers[event.player_index] = nil
end

for _, name in pairs({"read_signal", "write_signal", "itemid_high_signal", "itemid_low_signal", "userid_signal", "pagecount_signal"}) do
    ---@param event EventData.on_gui_elem_changed
    handlers[name.."_changed"] = function(event)
        local reader = storage.opened_readers[event.player_index]
        if not reader then return end
        local refs = storage.refs[event.player_index]
        reader[name] = event.element.elem_value --[[@as SignalID]]
        reader:on_gui_changed_settings()
    end
end

---@param event EventData.on_gui_click
function handlers.slot_clicked(event)
    local player = game.get_player(event.player_index)
    ---@cast player -?
    local reader = storage.opened_readers[event.player_index]
    local cursor_stack = player.cursor_stack
    if not cursor_stack then return end
    if cursor_stack.valid_for_read and cursor_stack.name ~= "disk" then
        player.create_local_flying_text{
            text = {"diskreader-gui.cant-be-used-as-data-storage", player.cursor_stack.prototype.localised_name},
            create_at_cursor = true,
        }
    else
        local chest_stack = reader.stack
        cursor_stack.swap_stack(chest_stack)
    end
end

---@param event EventData.on_gui_switch_state_changed
function handlers.flip_wires_switched(event)
    local reader = storage.opened_readers[event.player_index]
    if not reader then return end
    reader.flip_wires = not reader.flip_wires
    reader:on_gui_changed_settings()
end

---@param event EventData.on_gui_click
function handlers.edit_description(event)
    local player = game.get_player(event.player_index)
    ---@cast player -?
    local refs = storage.refs[event.player_index]
    glib.add(player.gui.screen, {
        args = {type = "frame", name = "description_window", style = "inset_frame_container_frame", direction = "vertical"},
        style_mods = {width = 400, maximal_height = 867},
        elem_mods = {auto_center = true},
        _closed = handlers.close_description_window,
        {
            args = {type = "flow"},
            style_mods = {horizontal_spacing = 8},
            drag_target = "description_window",
            {
                args = {type = "label", caption = {"gui-edit-label.edit-description"}, style = "frame_title", ignored_by_interaction = true},
                style_mods = {top_margin = -3, bottom_margin = 3},
            },
            {
                args = {type = "empty-widget", style = "draggable_space_header", ignored_by_interaction = true},
                style_mods = {height = 24, right_margin = 4, horizontally_stretchable = true},
            },
            {
                args = {type = "sprite-button", style = "cancel_close_button", sprite = "utility/close"},
                _click = handlers.close_description_window,
            }
        },
    }, refs)
    storage.do_not_close_gui = true
    player.opened = refs.description_window
    storage.do_not_close_gui = nil
end

function handlers.close_description_window(event)
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    player.gui.screen.description_window.destroy()
    player.opened = player.gui.screen.diskreader_window
end

function gui.on_tick()
    for _, player in pairs(game.connected_players) do
        update_gui(player)
    end
end

glib.register_handlers(handlers)

return gui