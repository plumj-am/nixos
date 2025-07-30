return {
	cmd = { "bacon-ls" },
	filetypes = { "rust" },
	root_markers = { "Cargo.toml", "Cargo.lock", ".bacon-locations" },
	settings = {
		init_options = {
			locationsFile = ".bacon-locations",
			updateOnSave = true,
			updateOnSaveWaitMillis = 100,
			runBaconInBackground = true,
			synchronizeAllOpenFilesWaitMillis = 1000,
		},
	},
}
