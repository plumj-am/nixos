return {
	cmd = { "rust-analyzer" },
	filetypes = { "rust" },
	root_markers = { "Cargo.toml", "Cargo.lock" },
	settings = {
		["rust-analyzer"] = {
			assist = {
				preferSelf = true,
			},
			lens = {
				references = {
					adt = {
						enable = true,
					},
					enumVariant = {
						enable = true,
					},
					method = {
						enable = true,
					},
					trait = {
						enable = true,
						all = true,
					},
				},
			},
			semanticHighlighting = {
				operator = {
					specialization = {
						enable = true,
					},
				},
				punctuation = {
					enable = true,
					separate = {
						macro = {
							enable = true,
						},
					},
					specialization = {
						enable = true,
					},
				},
			},
			inlayHints = {
				bindingModeHints = {
					enable = true,
				},
				closureCaptureHints = {
					enable = true,
				},
				closureReturnTypeHints = {
					enable = true,
				},
				discriminantHints = {
					enable = true,
				},
				expressionAdjustmentHints = {
					enable = true,
				},
				genericParameterHints = {
					lifetime = {
						enable = true,
					},
					type = {
						enable = true,
					},
				},
				implicitDrops = {
					enable = true,
				},
				implicitSizedBoundHints = {
					enable = true,
				},
				lifetimeElisionHints = {
					useParameterNames = true,
					enable = true,
				},
				rangeExclusiveHints = {
					enable = true,
				},
			},
			-- checkOnSave and diagnostics must be disabled for bacon-ls
			checkOnSave = {
				command = "clippy",
				enable = true,
			},
			diagnostics = {
				enable = true,
				experimental = {
					enable = true,
				},
				styleLints = {
					enable = true,
				},
			},
			hover = {
				actions = {
					references = {
						enable = true,
					},
				},
				show = {
					enumVariants = 10,
					fields = 10,
					traitAssocItems = 10,
				},
			},
			interpret = {
				tests = true,
			},
			cargo = {
				features = "all",
			},
			completion = {
				hideDeprecated = true,
				fullFunctionSignatures = {
					enable = true,
				},
			},
		},
	},
}
