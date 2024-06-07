local mod = get_mod("slots")

return {
	normal = {
		count = mod:get("normal_slots_count"),
		debug_color = "lime",
		dialogue_surrounded_count = 8,
		distance = 1.85,
		priority = 2,
		queue_distance = 3,
		radius = 0.5,
		use_wait_slots = true,
	},
	medium = {
		count = mod:get("medium_slots_count"),
		debug_color = "yellow",
		dialogue_surrounded_count = 6,
		distance = 2.2,
		priority = 1.5,
		queue_distance = 3.5,
		radius = 1,
		use_wait_slots = true,
	},
	large = {
		count = mod:get("large_slots_count"),
		debug_color = "red",
		dialogue_surrounded_count = 4,
		distance = 2.25,
		priority = 1,
		queue_distance = 3.5,
		radius = 1.5,
		use_wait_slots = false,
	},
}
