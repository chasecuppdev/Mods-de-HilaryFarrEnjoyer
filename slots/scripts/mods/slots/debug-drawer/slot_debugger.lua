-- slot_debugger.lua

local mod = get_mod("slots")
local DebugDrawerRelease = require("scripts/mods/slots/debug-drawer/debug_drawer")
local debug_drawer = DebugDrawerRelease:new()

function mod:debug_draw_slots(target_units, unit_extension_data, nav_world, t)
    local line_object = Debug.create_line_object("slots_debug_drawer")
    local debug_drawer = DebugDrawerRelease:new(line_object, "immediate")

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

    if type(Managers.state.debug._world) ~= "userdata" then
        mod:echo("Error: Managers.state.debug._world is not userdata")
        return
    end

    if not rawget(_G, "World") or not World.is_world then
        mod:echo("Error: World.is_world is not available")
        return
    end

    if not World.is_world(Managers.state.debug._world) then
        mod:echo("Error: Managers.state.debug._world is not of type World")
        return
    end

    debug_drawer:update(Managers.state.debug._world)
end

return {
    debug_draw_slots = function(target_units, unit_extension_data, nav_world, t)
        mod:debug_draw_slots(target_units, unit_extension_data, nav_world, t)
    end
}
