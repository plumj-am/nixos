return {
	capabilities = capabilities,
	cmd = { "gopls" },
	root_markers = { "go.mod", "go.sum" },
	filetypes = { "go" },
	-- init_options = {
	-- 	usePlaceholders = true,
	-- },
	settings = {
		experimentalPostfixCompletions = true,
		gofumpt = true,
		staticcheck = true,
		completeUnimported = true,
		usePlaceholders = true,
		semanticTokens = true,
				-- stylua: ignore start
				analyses = { -- all good analyses are enabled
					shadow = true, QF1005 = true, QF1006 = true, QF1007 = true, QF1011 = true, S1002 = true, S1005 = true, S1006 = true, S1008 = true, S1009 = true, S1011 = true, S1016 = true, S1021 = true, S1029 = true, SA1000 = true, SA1002 = true, SA1003 = true, SA1007 = true, SA1010 = true, SA1011 = true, SA1014 = true, SA1015 = true, SA1017 = true, SA1018 = true, SA1020 = true, SA1021 = true, SA1023 = true, SA1024 = true, SA1025 = true, SA1026 = true, SA1027 = true, SA1028 = true, SA1030 = true, SA1031 = true, SA1032 = true, SA2002 = true, SA2003 = true, SA4005 = true, SA4006 = true, SA4008 = true, SA4009 = true, SA4010 = true, SA4012 = true, SA4015 = true, SA4017 = true, SA4018 = true, SA4023 = true, SA4031 = true, SA5000 = true, SA5002 = true, SA5005 = true, SA5007 = true, SA5010 = true, SA5011 = true, SA5012 = true, SA6000 = true, SA6001 = true, SA6002 = true, SA6003 = true, SA9001 = true, SA9003 = true, SA9005 = true, SA9007 = true, SA9008 = true,
				},
		-- stylua: ignore end
		codelenses = {
			run_govulncheck = true,
		},
		vulncheck = "Imports",
	},
}
