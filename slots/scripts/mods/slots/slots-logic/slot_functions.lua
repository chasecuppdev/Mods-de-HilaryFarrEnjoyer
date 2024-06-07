-- slot_functions.lua

local mod = get_mod("slots")

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

print("[slots] SlotSettings and SlotTemplates overridden successfully")

local debug_drawer = DebugDrawerRelease:new()
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

local SLOT_COLORS = {
	{
		"aqua_marine",
		"cadet_blue",
		"corn_flower_blue",
		"dodger_blue",
		"sky_blue",
		"midnight_blue",
		"medium_purple",
		"blue_violet",
		"dark_slate_blue",
	},
	{
		"dark_green",
		"green",
		"lime",
		"light_green",
		"dark_sea_green",
		"spring_green",
		"sea_green",
		"medium_aqua_marine",
		"light_sea_green",
	},
	{
		"maroon",
		"dark_red",
		"brown",
		"firebrick",
		"crimson",
		"red",
		"tomato",
		"coral",
		"indian_red",
		"light_coral",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
	{
		"orange",
		"gold",
		"dark_golden_rod",
		"golden_rod",
		"pale_golden_rod",
		"dark_khaki",
		"khaki",
		"olive",
		"yellow",
	},
}

AIPlayerSlotExtension.init = function (self, extension_init_context, unit, extension_init_data)
    -- Basic initialization
    self.unit = unit
    self.all_slots = {}

    -- Log the start of the initialization
    mod:echo("Initializing AIPlayerSlotExtension for unit: " .. tostring(unit))
    mod:echo("Profile index: " .. tostring(extension_init_data.profile_index))
    mod:echo("SlotTypeSettings:")
    debug_print_table(SlotTypeSettings, "SlotTypeSettings")

    -- Loop through slot types and initialize slots
    for slot_type, setting in pairs(SlotTypeSettings) do
--[[         mod:echo("Initializing slots for slot type: " .. slot_type)
        mod:echo("Settings: " .. tostring(setting)) ]]

        local unit_data_var_name = slot_type == "normal" and "ai_slots_count" or "ai_slots_count_" .. slot_type
        local total_slots_count = setting.count
        local slot_data = {}

        slot_data.total_slots_count = total_slots_count
        slot_data.slot_radians = math.degrees_to_radians(360 / total_slots_count)
        slot_data.slots_count = 0
        slot_data.use_wait_slots = setting.use_wait_slots
        slot_data.priority = setting.priority
        slot_data.disabled_slots_count = 0
        slot_data.slots = {}

        self.all_slots[slot_type] = slot_data

--[[         -- Log the slot data
        mod:echo(string.format("Slot data for %s: total_slots_count = %d, slot_radians = %.2f, use_wait_slots = %s, priority = %d", 
            slot_type, total_slots_count, slot_data.slot_radians, tostring(slot_data.use_wait_slots), slot_data.priority)) ]]
    end

    -- Log after all slots have been initialized
    mod:echo("All slots have been initialized.")
    mod:echo("All slot data:")
    debug_print_table(self.all_slots, "all_slots")

    -- Additional initialization
    local debug_color_index = extension_init_data.profile_index or AGGROABLE_SLOT_COLOR_INDEX

    self.dogpile = 0
    self.position = Vector3Box(POSITION_LOOKUP[unit])
    self.moved_at = 0
    self.next_slot_status_update_at = 0
    self.valid_target = true
    self.debug_color_name = SLOT_COLORS[debug_color_index][1]
    self.num_occupied_slots = 0
    self.has_slots_attached = true
    self.delayed_num_occupied_slots = 0
    self.delayed_slot_decay_t = 0
    self.full_slots_at_t = {}

    self:_create_target_slots(unit, debug_color_index)

    self._is_server = extension_init_context.is_server
    self._network_transmit = extension_init_context.network_transmit
    self._audio_system = Managers.state.entity:system("audio_system")
    self._audio_parameter_id = NetworkLookup.global_parameter_names.occupied_slots_percentage

    local player = Managers.player:unit_owner(unit)

    self:_update_assigned_player(player, unit)

    self.belongs_to_player = true

    -- Final log for initialization completion
    mod:echo("AIPlayerSlotExtension initialization complete for unit: " .. tostring(unit))
end


--[[ AISlotSystem.init = function (self, context, system_name)
	local entity_manager = context.entity_manager

	entity_manager:register_system(self, system_name, AISlotSystem.extensions)

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
end ]]

--[[ AISlotSystem2.init = function (self, context, system_name)
    debug_print_table(SlotSettings, "SlotSettings at AISlotSystem.init")
    debug_print_table(SlotTypeSettings, "SlotTypeSettings at AISlotSystem.init")
	AISlotSystem2.super.init(self, context, system_name, AISlotSystem2.extensions)

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
end ]]
