return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`slots` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("slots", {
			mod_script       = "scripts/mods/slots/slots",
			mod_data         = "scripts/mods/slots/slots_data",
			mod_localization = "scripts/mods/slots/slots_localization",
		})
	end,
	packages = {
		"resource_packages/slots/slots",
	},
}
