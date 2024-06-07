-- slot_debugger.lua

local mod = get_mod("slots")
local DebugDrawerRelease = require("scripts/mods/slots/debug-drawer/debug_drawer")

local debug_drawer = DebugDrawerRelease:new()

function debug_draw_slots(target_units, unit_extension_data, nav_world, t)
    -- Ensure the Debug world is valid
    if not Debug.world or type(Debug.world) ~= "userdata" then
        mod:echo("Invalid Debug world")
        return
    end

    -- Create line object
    local line_object = Debug.create_line_object("slots_debug_drawer")
    if not line_object or type(line_object) ~= "userdata" then
        mod:echo("Failed to create line object")
        return
    end
    mod:echo("Successfully created line object: " .. tostring(line_object))

    -- Create debug drawer
    local debug_drawer = DebugDrawerRelease:new(line_object, "immediate")

    -- Log target units
    mod:echo("Target Units contents:")
    for i, unit in ipairs(target_units) do
        mod:echo(string.format("%d: %s", i, tostring(unit)))
        local extension = unit_extension_data[unit]
        if extension then
            mod:echo("  valid_target: " .. tostring(extension.valid_target))
            mod:echo("  all_slots: " .. tostring(extension.all_slots))
            mod:echo("  was_on_ladder: " .. tostring(extension.was_on_ladder))
            mod:echo("  has_slots_attached: " .. tostring(extension.has_slots_attached))
            mod:echo("  _audio_parameter_id: " .. tostring(extension._audio_parameter_id))
            mod:echo("  _network_transmit: " .. tostring(extension._network_transmit))
            mod:echo("  delayed_num_occupied_slots: " .. tostring(extension.delayed_num_occupied_slots))
            mod:echo("  next_slot_status_update_at: " .. tostring(extension.next_slot_status_update_at))
            mod:echo("  _status_ext: " .. tostring(extension._status_ext))
            mod:echo("  belongs_to_player: " .. tostring(extension.belongs_to_player))
            mod:echo("  _is_local_player: " .. tostring(extension._is_local_player))
            mod:echo("  position: " .. tostring(extension.position))
            mod:echo("  _is_server_player: " .. tostring(extension._is_server_player))
            mod:echo("  _locomotion_ext: " .. tostring(extension._locomotion_ext))
            mod:echo("  num_occupied_slots: " .. tostring(extension.num_occupied_slots))
            mod:echo("  full_slots_at_t: " .. tostring(extension.full_slots_at_t))
            mod:echo("  _peer_id: " .. tostring(extension._peer_id))
            mod:echo("  unit: " .. tostring(extension.unit))
            mod:echo("  _audio_system: " .. tostring(extension._audio_system))
            mod:echo("  index: " .. tostring(extension.index))
            mod:echo("  delayed_slot_decay_t: " .. tostring(extension.delayed_slot_decay_t))
            mod:echo("  debug_color_name: " .. tostring(extension.debug_color_name))
            mod:echo("  _is_server: " .. tostring(extension._is_server))
            mod:echo("  dogpile: " .. tostring(extension.dogpile))
        end
    end

    -- Log the world object
    mod:echo("Managers.state.debug._world: " .. tostring(Managers.state.debug._world))

    for _, unit in ipairs(target_units) do
        local extension = unit_extension_data[unit]
        if extension and extension.slots then
            for _, slot in ipairs(extension.slots) do
                if slot.position then
                    debug_drawer:sphere(slot.position, 0.5, Color(255, 0, 0))
                end
            end
        end
    end

    -- Attempt to update the debug drawer
    debug_drawer:update(Managers.state.debug._world)
end


return {
    debug_draw_slots = function(target_units, unit_extension_data, nav_world, t)
        mod:debug_draw_slots(target_units, unit_extension_data, nav_world, t)
    end
}
