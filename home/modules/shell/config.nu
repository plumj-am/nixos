# nixos handles PATH through configuration

$env.config.buffer_editor = "nvim"
$env.config.show_banner = false

$env.config.ls = {
    use_ls_colors: true
    clickable_links: true
}

$env.config.rm = {
    always_trash: false
}

$env.config.table = {
    mode: compact # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
    index_mode: always # "always" show indexes, "never" show indexes, "auto" = show indexes when a table has "index" column
    show_empty: true # show 'empty list' and 'empty record' placeholders for command output
    trim: {
		methodology: wrapping
		wrapping_try_keep_words: true
		truncating_suffix: "..."
    }
}

$env.config.explore = {
    help_banner: true
    exit_esc: true

    command_bar_text: '#C4C9C6'

    status_bar_background: {}

    highlight: {bg: 'yellow' fg: 'black' }

    status: {}

    try: {}

    table: {
		split_line: '#404040'

		cursor: true

		line_index: true
		line_shift: true
		line_head_top: true
		line_head_bottom: true

		show_head: true
		show_index: true
    }

    config: {
		cursor_color: {bg: 'yellow' fg: 'black'}
    }
}

$env.config.history = {
	max_size: 10000
    sync_on_enter: true
}

$env.config.filesize = {}

$env.config.cursor_shape = {
    emacs: block
    vi_insert: block
    vi_normal: block
}

$env.config.float_precision = 2
$env.config.use_ansi_coloring = true
$env.config.show_banner = false

# hooks
$env.config.hooks.display_output = {||
	if (term size).columns >= 100 { table -e } else { table }
}

$env.config.hooks.pre_prompt = [
	{ ||
	    if (which direnv | is-empty) {
		return
	    }
	    direnv export json | from json | default {} | load-env
	    $env.PATH = ($env.PATH | split row (char env_sep))
	}
]