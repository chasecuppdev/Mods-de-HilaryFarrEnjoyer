local mod = get_mod("slots")

-- HELPER FUNCTIONS
-- Define echo_table if it's not already defined
if not mod.echo_table then
    function mod:echo_table(tbl)
        for k, v in pairs(tbl) do
            self:echo(string.format("%s: %s", tostring(k), tostring(v)))
        end
    end
end

-- Define `unit_alive` function
local function unit_alive(unit)
    return ALIVE[unit]
end

-- Function to log argument types and values
local function log_argument_types_and_values(...)
    local args = {...}
    for i, arg in ipairs(args) do
        mod:echo(string.format("Argument %d: %s (type: %s)", i, tostring(arg), type(arg)))
    end
end

-- Debug function to print table contents
local function debug_print_table(tbl, name)
    if tbl then
        mod:echo(name .. " contents:")
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                mod:echo(tostring(k) .. ": table: " .. tostring(v))
                for sub_k, sub_v in pairs(v) do
                    mod:echo("  " .. tostring(sub_k) .. ": " .. tostring(sub_v))
                end
            else
                mod:echo(tostring(k) .. ": " .. tostring(v))
            end
        end
    else
        mod:echo(name .. " is nil")
    end
end

-- Debugging function to print table contents
local function debug_print_table_contents(tbl, tbl_name)
    if not tbl then
        mod:echo(string.format("%s is nil", tbl_name))
        return
    end

    for key, value in pairs(tbl) do
        mod:echo(string.format("%s[%s] = %s", tbl_name, tostring(key), tostring(value)))
    end
end

local DebugDrawerRelease = require("scripts/mods/slots/game-code/debug-drawer")
local debug_drawer = DebugDrawerRelease:new()

local AISlotUtils = require("scripts/entity_system/systems/ai/ai_slot_utils")
local AIPlayerSlotExtension = require("scripts/entity_system/systems/ai/ai_player_slot_extension")

local base_slot_settings = require("scripts/settings/slot_settings")
local base_slot_templates = require("scripts/settings/slot_templates")

local custom_slot_settings = require("scripts/mods/slots/custom_slot_settings")
local custom_slot_templates = require("scripts/mods/slots/custom_slot_templates")

-- Include debug visualizer files
local debuggers = mod:dofile("scripts/mods/slots/game-code/ai_slot_system")
local debug_draw_slots = debuggers.debug_draw_slots

assert(type(custom_slot_settings) == "table", "Expected custom_slot_settings to be a table")
assert(type(custom_slot_templates) == "table", "Expected custom_slot_templates to be a table")

-- Initialize SlotSettings and SlotTypeSettings if they are not defined
SlotSettings = SlotSettings or {}
SlotTypeSettings = SlotTypeSettings or {}

-- Merge custom settings with base settings
table.merge_recursive(SlotSettings, custom_slot_settings)
table.merge_recursive(SlotTypeSettings, custom_slot_templates)

-- Debug output after merging
debug_print_table(SlotSettings, "SlotSettings after merge")
debug_print_table(SlotTypeSettings, "SlotTypeSettings after merge")

-- Ensure slot_config is initialized
SlotSettings.slot_config = SlotSettings.slot_config or {
    num_normal_slots = 9,
    num_medium_slots = 8,
    num_large_slots = 4,
}

print("[slots] SlotSettings and SlotTemplates overridden successfully")

-- Ensure extensions table is defined
AISlotSystem.extensions = {
    "AIEnemySlotExtension",
    "AIPlayerSlotExtension",
    "AIAggroableSlotExtension"
}

AISlotSystem2.extensions = {
    "AIEnemySlotExtension",
    "AIPlayerSlotExtension",
    "AIAggroableSlotExtension"
}

-- FUNCTIONS
local function custom_create_target_slots(self, unit, num_slots, slot_type, color)
    -- Ensure self.slots is initialized
    self.slots = self.slots or {}

    local target_unit_str = tostring(unit)
    local nav_world = self.nav_world  -- Assuming nav_world is accessible from self
    local above = SLOT_Z_MAX_UP or 1  -- Replace with appropriate value
    local below = SLOT_Z_MAX_DOWN or 1  -- Replace with appropriate value

    -- Debugging statements
    mod:echo(string.format("Creating target slots for unit: %s", target_unit_str))
    mod:echo(string.format("Num slots: %d, Slot type: %s, Color: %s", num_slots, slot_type, color))

    for i = 1, num_slots do
        local slot_data = {
            slot_type = slot_type,
            color = color,
            position = nil,
            occupied = false,
            debug_color_name = color,
            attached_to_unit = nil,
            last_occupied_time = 0,
            full_slots_at_t = {},
            delayed_slot_decay_t = 0,
            has_slots_attached = true,
            delayed_num_occupied_slots = 0,
            moved_at = 0,
            next_slot_status_update_at = 0,
            dogpile = 0,
        }

        table.insert(self.slots, slot_data)

        -- Use get_slot_position_on_navmesh_from_outside_target to get the slot position
        local slot_direction = Vector3(1, 0, 0)  -- Replace with appropriate initial direction
        local distance = SlotTypeSettings[slot_type].distance
        local target_position = POSITION_LOOKUP[unit]

        local position, _ = get_slot_position_on_navmesh_from_outside_target(
            target_position, slot_direction, nil, distance, nav_world, above, below
        )

        if position then
            slot_data.position = position
            mod:echo(string.format("Slot %d for %s created with position (%f, %f, %f)", i, target_unit_str, position.x, position.y, position.z))
        else
            mod:echo(string.format("Failed to create slot %d for %s", i, target_unit_str))
        end
    end
end

-- Custom on_add_extension function
local function custom_on_add_extension(self, world, unit, extension_name, extension_init_data)
    local extension = {}

    ScriptUnit.set_extension(unit, "ai_slot_system", extension, dummy_input)

    self.unit_extension_data[unit] = extension

    if extension_name == "AIPlayerSlotExtension" or extension_name == "AIAggroableSlotExtension" then
        local debug_color_index

        if extension_name == "AIPlayerSlotExtension" then
            debug_color_index = extension_init_data.profile_index
        elseif extension_name == "AIAggroableSlotExtension" then
            debug_color_index = AGGROABLE_SLOT_COLOR_INDEX

            local _, is_level_unit = Managers.state.network:game_object_or_level_id(unit)

            if is_level_unit then
                POSITION_LOOKUP[unit] = Unit.world_position(unit, 0)
            end
        end

        extension.all_slots = {}

        for slot_type, setting in pairs(SlotTypeSettings) do
            local unit_data_var_name = slot_type == "normal" and "ai_slots_count" or "ai_slots_count_" .. slot_type
            local total_slots_count = Unit.get_data(unit, unit_data_var_name) or setting.count
            local slot_data = {}

            slot_data.total_slots_count = total_slots_count
            slot_data.slot_radians = math.degrees_to_radians(360 / total_slots_count)
            slot_data.slots_count = 0
            slot_data.use_wait_slots = setting.use_wait_slots
            slot_data.priority = setting.priority
            slot_data.disabled_slots_count = 0
            slot_data.slots = {}
            extension.all_slots[slot_type] = slot_data
        end

        local target_index = #self.target_units + 1

        extension.dogpile = 0
        extension.position = Vector3Box(POSITION_LOOKUP[unit])
        extension.moved_at = 0
        extension.next_slot_status_update_at = 0
        extension.valid_target = true
        extension.index = target_index
        extension.debug_color_name = SLOT_COLORS[debug_color_index][1]
        extension.num_occupied_slots = 0
        extension.has_slots_attached = true
        extension.delayed_num_occupied_slots = 0
        extension.delayed_slot_decay_t = 0
        extension.full_slots_at_t = {}

        custom_create_target_slots(extension, unit, debug_color_index)

        self.target_units[target_index] = unit

        local target_units = self.target_units
        local nav_world = self.nav_world
        local traverse_logic = self._traverse_logic
        local unit_extension_data = self.unit_extension_data

        self:update_target_slots(0, unit, target_units, unit_extension_data, extension, nav_world, traverse_logic)
    end

    if extension_name == "AIEnemySlotExtension" then
        extension.target = nil
        extension.target_position = Vector3Box()
        extension.improve_wait_slot_position_t = 0
        self.update_slots_ai_units[#self.update_slots_ai_units + 1] = unit
    end

    return extension
end

-- Override AISlotSystem init function
AISlotSystem.init = function(self, context, system_name)
    debug_print_table(SlotSettings, "SlotSettings at AISlotSystem.init")
    debug_print_table(SlotTypeSettings, "SlotTypeSettings at AISlotSystem.init")

    AISlotSystem.super.init(self, context, system_name, AISlotSystem.extensions)

    local entity_manager = context.entity_manager
    entity_manager:register_system(self, system_name, AISlotSystem.extensions)

    self.num_normal_slots = SlotSettings.slot_config.num_normal_slots
    self.num_medium_slots = SlotSettings.slot_config.num_medium_slots
    self.num_large_slots = SlotSettings.slot_config.num_large_slots

    mod:echo(string.format("Initialized with %d normal slots, %d medium slots, %d large slots", self.num_normal_slots, self.num_medium_slots, self.num_large_slots))

    self.entity_manager = entity_manager
    self.is_server = context.is_server
    self.world = context.world
    self.unit_storage = context.unit_storage
    self.nav_world = Managers.state.entity:system("ai_system"):nav_world()
    self.unit_extension_data = {}
    self.frozen_unit_extension_data = {}
    self.update_slots_ai_units = {}
    self.update_slots_ai_units_prioritized = {}
    self.target_units = {}
    self.current_ai_index = 1
    self.next_total_slot_count_update = 0
    self.next_disabled_slot_count_update = 0
    self.next_slot_sound_update = 0
    self.network_transmit = context.network_transmit
    self.num_total_enemies = 0
    self.num_occupied_slots = 0

    local nav_tag_layer_costs = {
        bot_poison_wind = 1,
        bot_ratling_gun_fire = 1,
        fire_grenade = 1,
    }

    table.merge(nav_tag_layer_costs, NAV_TAG_VOLUME_LAYER_COST_AI)

    local navtag_layer_cost_table = GwNavTagLayerCostTable.create()

    self._navtag_layer_cost_table = navtag_layer_cost_table

    AiUtils.initialize_cost_table(navtag_layer_cost_table, nav_tag_layer_costs)

    local nav_cost_map_cost_table = GwNavCostMap.create_tag_cost_table()

    self._nav_cost_map_cost_table = nav_cost_map_cost_table

    AiUtils.initialize_nav_cost_map_cost_table(nav_cost_map_cost_table, nil, 1)

    self._traverse_logic = GwNavTraverseLogic.create(self.nav_world, nav_cost_map_cost_table)

    GwNavTraverseLogic.set_navtag_layer_cost_table(self._traverse_logic, navtag_layer_cost_table)

    -- Call modified slot creation
    for _, target_unit in ipairs(self.target_units) do
        local target_unit_extension = self.unit_extension_data[target_unit]
        if target_unit_extension then
            custom_create_target_slots(target_unit_extension, target_unit, 1)
        end
    end
end

-- Override AISlotSystem2 init function
AISlotSystem2.init = function(self, context, system_name)
    debug_print_table(SlotSettings, "SlotSettings at AISlotSystem2.init")
    debug_print_table(SlotTypeSettings, "SlotTypeSettings at AISlotSystem2.init")

    AISlotSystem2.super.init(self, context, system_name, AISlotSystem2.extensions)

    self.num_normal_slots = SlotSettings.slot_config.num_normal_slots
    self.num_medium_slots = SlotSettings.slot_config.num_medium_slots
    self.num_large_slots = SlotSettings.slot_config.num_large_slots

    mod:echo(string.format("Initialized with %d normal slots, %d medium slots, %d large slots", self.num_normal_slots, self.num_medium_slots, self.num_large_slots))

    self.nav_world = Managers.state.entity:system("ai_system"):nav_world()
    self.unit_extension_data = {}
    self.frozen_unit_extension_data = {}
    self.update_slots_ai_units = {}
    self.update_slots_ai_units_prioritized = {}
    self.target_units = {}
    self.current_ai_index = 1
    self.next_total_slot_count_update = 0
    self.next_disabled_slot_count_update = 0
    self.next_slot_sound_update = 0
    self.network_transmit = context.network_transmit
    self.num_total_enemies = 0
    self.num_occupied_slots = 0

    local nav_tag_layer_costs = {
        bot_poison_wind = 1,
        bot_ratling_gun_fire = 1,
        fire_grenade = 1,
    }

    table.merge(nav_tag_layer_costs, NAV_TAG_VOLUME_LAYER_COST_AI)

    local navtag_layer_cost_table = GwNavTagLayerCostTable.create()

    self._navtag_layer_cost_table = navtag_layer_cost_table

    AiUtils.initialize_cost_table(navtag_layer_cost_table, nav_tag_layer_costs)

    local nav_cost_map_cost_table = GwNavCostMap.create_tag_cost_table()

    self._nav_cost_map_cost_table = nav_cost_map_cost_table

    AiUtils.initialize_nav_cost_map_cost_table(nav_cost_map_cost_table, nil, 1)

    self._traverse_logic = GwNavTraverseLogic.create(self.nav_world, nav_cost_map_cost_table)

    GwNavTraverseLogic.set_navtag_layer_cost_table(self._traverse_logic, navtag_layer_cost_table)

    -- Call modified slot creation
    for _, target_unit in ipairs(self.target_units) do
        local target_unit_extension = self.unit_extension_data[target_unit]
        if target_unit_extension then
            custom_create_target_slots(target_unit_extension, target_unit, 1)
        end
    end
end

-- Function to draw debug visuals for the AI slot system
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

     -- Ensure that Managers.state.debug._world is of the correct type
    if type(Managers.state.debug._world) ~= "userdata" then
        mod:echo("Error: Managers.state.debug._world is not userdata")
        return
    end

    -- Debugging: Check if Managers.state.debug._world is of type World
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

-- HOOKS
-- Hook the original create_target_slots function in AIPlayerSlotExtension
mod:hook(AIPlayerSlotExtension, "_create_target_slots", function(func, self, ...)
    log_argument_types_and_values(self, ...)
    return custom_create_target_slots(self, ...)
end)

-- Hook into get_slot_position_on_navmesh_from_outside_target
mod:hook(AIPlayerSlotExtension, "get_slot_position_on_navmesh_from_outside_target", function (func, target_position, slot_direction, _, distance, nav_world, above, below)
    log_argument_types_and_values(target_position, slot_direction, _, distance, nav_world, above, below)
    mod:echo(string.format("Calling get_slot_position_on_navmesh_from_outside_target with target_position: %s, slot_direction: %s, distance: %s, nav_world: %s, above: %s, below: %s",
        tostring(target_position), tostring(slot_direction), tostring(distance), tostring(nav_world), tostring(above), tostring(below)))
    
    local position, original_position = func(target_position, slot_direction, _, distance, nav_world, above, below)
    
    mod:echo(string.format("Resulting position: %s", tostring(position)))
    
    return position, original_position
end)

-- Hook the original on_add_extension function
mod:hook(AISlotSystem, "on_add_extension", function(func, self, ...)
    log_argument_types_and_values(self, ...)
    return custom_on_add_extension(self, ...)
end)

mod:hook_safe(AISlotSystem2, "init", function (self, context, system_name)
    mod:echo("SlotSettings at AISlotSystem2.init contents:")
    mod:echo_table(SlotSettings)
    mod:echo("SlotTypeSettings at AISlotSystem2.init contents:")
    mod:echo_table(SlotTypeSettings)
    mod:echo(string.format("Initialized with %d normal slots, %d medium slots, %d large slots",
        SlotSettings.normal.count, SlotSettings.medium.count, SlotSettings.large.count))
end)

-- Hook the original on_add_extension function
mod:hook(AISlotSystem, "on_add_extension", function(func, self, ...)
    return custom_on_add_extension(self, ...)
end)

-- Enable debug visualizer
local enabled = false

mod:hook_safe(Boot, "game_update", function(_, real_world_dt)
    if enabled then
        local t = Managers.time:time("main")
        local ai_slot_system = Managers.state.entity:system("ai_slot_system")
        local target_units = ai_slot_system.target_units
        local unit_extension_data = ai_slot_system.unit_extension_data
        local nav_world = ai_slot_system.nav_world

        -- Make unit_alive function available within debug_draw_slots
        local function unit_alive(unit)
            return ALIVE[unit]
        end

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

--COMMANDS
mod:command("debug_slots", "Enable the Slot Debug UI", function()
    enabled = not enabled

    script_data.disable_debug_draw = not enabled
    Development._hardcoded_dev_params.disable_debug_draw = not enabled
end)