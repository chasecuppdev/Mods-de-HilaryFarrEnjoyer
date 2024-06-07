local mod = get_mod("slots")

-- local function custom_create_target_slots(self, unit, num_slots, slot_type, color)
--     self.slots = self.slots or {}

--     local target_unit_str = tostring(unit)
--     local nav_world = self.nav_world

--     if not nav_world then
--         mod:echo("Error: nav_world is not initialized")
--         return
--     end

--     local above = SLOT_Z_MAX_UP or 1
--     local below = SLOT_Z_MAX_DOWN or 1

--     mod:echo(string.format("Creating target slots for unit: %s", target_unit_str))
--     mod:echo(string.format("Num slots: %d, Slot type: %s, Color: %s", num_slots, slot_type, color))

--     for i = 1, num_slots do
--         local slot_data = {
--             slot_type = slot_type,
--             color = color,
--             position = nil,
--             occupied = false,
--             debug_color_name = color,
--             attached_to_unit = nil,
--             last_occupied_time = 0,
--             full_slots_at_t = {},
--             delayed_slot_decay_t = 0,
--             has_slots_attached = true,
--             delayed_num_occupied_slots = 0,
--             moved_at = 0,
--             next_slot_status_update_at = 0,
--             dogpile = 0,
--         }

--         table.insert(self.slots, slot_data)

--         local slot_direction = Vector3(1, 0, 0)  -- Replace with appropriate initial direction
--         local distance = SlotTypeSettings[slot_type].distance
--         local target_position = POSITION_LOOKUP[unit]

--         -- Call the function from the included file
--         local position, _ = AIPlayerSlotExtension.get_slot_position_on_navmesh_from_outside_target(
--             target_position, slot_direction, nil, distance, nav_world, above, below
--         )

--         if position then
--             slot_data.position = position
--             mod:echo(string.format("Slot %d for %s created with position (%f, %f, %f)", i, target_unit_str, position.x, position.y, position.z))
--         else
--             mod:echo(string.format("Failed to create slot %d for %s", i, target_unit_str))
--         end
--     end
-- end

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


--[[ mod:hook(AIPlayerSlotExtension, "_create_target_slots", function(func, self, ...)
    log_argument_types_and_values(self, ...)
    return custom_create_target_slots(self, ...)
end) ]]

--[[ mod:hook(AISlotSystem, "on_add_extension", function(func, self, ...)
    log_argument_types_and_values(self, ...)
    return custom_on_add_extension(self, ...)
end) ]]
