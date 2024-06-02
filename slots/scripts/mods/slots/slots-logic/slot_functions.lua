-- slot_functions.lua

local mod = get_mod("slots")

local DebugDrawerRelease = require("scripts/mods/slots/debug-drawer/debug_drawer")
local debug_drawer = DebugDrawerRelease:new()

local AISlotUtils = require("scripts/entity_system/systems/ai/ai_slot_utils")
local AIPlayerSlotExtension = require("scripts/entity_system/systems/ai/ai_player_slot_extension")

local debuggers = mod:dofile("scripts/mods/slots/slots-logic/ai_slot_system")
local debug_draw_slots = debuggers.debug_draw_slots

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

    for _, target_unit in ipairs(self.target_units) do
        local target_unit_extension = self.unit_extension_data[target_unit]
        if target_unit_extension then
            custom_create_target_slots(target_unit_extension, target_unit, 1)
        end
    end
end

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

    for _, target_unit in ipairs(self.target_units) do
        local target_unit_extension = self.unit_extension_data[target_unit]
        if target_unit_extension then
            custom_create_target_slots(target_unit_extension, target_unit, 1)
        end
    end
end

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
