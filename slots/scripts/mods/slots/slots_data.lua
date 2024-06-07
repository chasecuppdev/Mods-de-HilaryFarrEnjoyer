local mod = get_mod("slots")

local menu = {
    name = "slots",
    description = mod:localize("mod_description"),
    is_togglable = true,
    tooltip = "requires_restart",
    options = {
        widgets = {
            {
                setting_id = "normal_slots_count",
                type = "numeric",
                default_value = 9,
                range = {1, 100},
            },
            {
                setting_id = "medium_slots_count",
                type = "numeric",
                default_value = 8,
                range = {1, 100},
            },
            {
                setting_id = "large_slots_count",
                type = "numeric",
                default_value = 4,
                range = {1, 100},
            }
        }
    }
}

return menu
