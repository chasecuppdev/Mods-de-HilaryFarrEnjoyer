local mod = get_mod("slots")

mod:dofile("scripts/mods/slots/slots-logic/slot_helpers")
mod:dofile("scripts/mods/slots/slots-logic/slot_hooks")
mod:dofile("scripts/mods/slots/slots-logic/slot_functions")

local base_slot_settings = require("scripts/settings/slot_settings")
local base_slot_templates = require("scripts/settings/slot_templates")

local custom_slot_settings = require("scripts/mods/slots/custom-slot-settings/custom_slot_settings")
local custom_slot_templates = require("scripts/mods/slots/custom-slot-settings/custom_slot_templates")

assert(type(custom_slot_settings) == "table", "Expected custom_slot_settings to be a table")
assert(type(custom_slot_templates) == "table", "Expected custom_slot_templates to be a table")

SlotSettings = SlotSettings or {}
SlotTypeSettings = SlotTypeSettings or {}

table.merge_recursive(SlotSettings, custom_slot_settings)
table.merge_recursive(SlotTypeSettings, custom_slot_templates)

debug_print_table(SlotSettings, "SlotSettings after merge")
debug_print_table(SlotTypeSettings, "SlotTypeSettings after merge")

SlotSettings.slot_config = SlotSettings.slot_config or {
    num_normal_slots = 9,
    num_medium_slots = 8,
    num_large_slots = 4,
}

print("[slots] SlotSettings and SlotTemplates overridden successfully")

-- Enable debug visualizer
local enabled = false

mod:hook_safe(Boot, "game_update", function(_, real_world_dt)
    if enabled then
        local t = Managers.time:time("main")
        local ai_slot_system = Managers.state.entity:system("ai_slot_system")
        if not ai_slot_system then
            mod:echo("Error: AI Slot System not found")
            return
        end

        local target_units = ai_slot_system.target_units
        local unit_extension_data = ai_slot_system.unit_extension_data
        local nav_world = ai_slot_system.nav_world

        -- Example usage of debug_print_table
        debug_print_table(target_units, "Target Units")

        mod:debug_draw_slots(target_units, unit_extension_data, nav_world, t)
        
        if Managers.state.debug then
            for _, drawer in pairs(Managers.state.debug._drawers) do
                drawer:update(Managers.state.debug._world)
            end
        end
    end
end)

-- COMMANDS
mod:command("debug_slots", "Enable the Slot Debug UI", function()
    enabled = not enabled

    script_data.disable_debug_draw = not enabled
    Development._hardcoded_dev_params.disable_debug_draw = not enabled
end)
