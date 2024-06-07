local mod = get_mod("slots")

mod:dofile("scripts/mods/slots/slots-logic/slot_helpers")
mod:dofile("scripts/mods/slots/debug-drawer/debug_drawer")
mod:dofile("scripts/mods/slots/slots-logic/slot_functions")
local debuggers = mod:dofile("scripts/mods/slots/slots-logic/ai_slot_system")
local debug_draw_slots = debuggers.debug_draw_slots

-- Disable debug mode by default
local enabled = false

-- Gotta restart the game to apply. Haven't figured out how to reinitialize the ai systems in game yet.
local function apply_slot_settings()
    -- Reload custom slot settings
    package.loaded["scripts/mods/slots/custom-slot-settings/custom_slot_settings"] = nil
    local custom_slot_settings = require("scripts/mods/slots/custom-slot-settings/custom_slot_settings")
    local custom_slot_templates = require("scripts/mods/slots/custom-slot-settings/custom_slot_templates")

    -- Update the settings
    SlotSettings = SlotSettings or {}
    SlotTypeSettings = SlotTypeSettings or {}

    table.merge_recursive(SlotSettings, custom_slot_settings)
    table.merge_recursive(SlotTypeSettings, custom_slot_templates)

    mod:echo("Applied slot settings:")
end

local function reinitialize_slot_systems()
    local entity_system = Managers.state.entity
    if entity_system then
        local ai_slot_system_2 = entity_system:system("ai_slot_system_2")
        if ai_slot_system_2 and ai_slot_system_2.init then
            ai_slot_system_2:init()  -- Initialize the AI Slot System 2
        end
    else
        mod:echo("Warning: Managers.state.entity is not available.")
    end
end

local function draw_slots()
    local entity_system = Managers.state.entity
    if enabled and entity_system then
        local ai_slot_system = entity_system:system("ai_slot_system")
        if ai_slot_system then
            local t = Managers.time:time("main")
            local target_units = ai_slot_system.target_units
            local unit_extension_data = ai_slot_system.unit_extension_data
            local nav_world = ai_slot_system.nav_world

            debug_draw_slots(target_units, unit_extension_data, nav_world, t)
        end
    end
end

mod:hook_safe(Boot, "game_update", function(_, real_world_dt)
    if enabled then
        draw_slots()
    end
end)

mod.on_setting_changed = function(setting_name)
    apply_slot_settings()
    --reinitialize_slot_systems()
end

-- COMMANDS
mod:command("debug_slots", "Enable the Slot Debug UI", function()
    enabled = not enabled

    script_data.disable_debug_draw = not enabled
    Development._hardcoded_dev_params.disable_debug_draw = not enabled
end)
