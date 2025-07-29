# path configuration handled by nixos

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
    mode: compact
    index_mode: always
    show_empty: true
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

# menus
$env.config.menus = [
{
	name: completion_menu
	only_buffer_difference: false
	marker: "| "
	type: {
		layout: columnar
		columns: 4
		col_width: 20
		col_padding: 2
	}
	style: {
		text: green
		selected_text: green_reverse
		description_text: yellow
	}
}
{
	name: history_menu
	only_buffer_difference: true
	marker: "? "
	type: {
		layout: list
		page_size: 10
	}
	style: {
		text: green
		selected_text: green_reverse
		description_text: yellow
	}
}
{
	name: help_menu
	only_buffer_difference: true
	marker: "? "
	type: {
		layout: description
		columns: 4
		col_width: 20
		col_padding: 2
		selection_rows: 4
		description_rows: 10
	}
	style: {
		text: green
		selected_text: green_reverse
		description_text: yellow
	}
}
{
	name: commands_menu
	only_buffer_difference: false
	marker: "# "
	type: {
		layout: columnar
		columns: 4
		col_width: 20
		col_padding: 2
	}
	style: {
		text: green
		selected_text: green_reverse
		description_text: yellow
	}
	source: { |buffer, position|
		$nu.scope.commands
		| where name =~ $buffer
		| each { |it| {value: $it.name description: $it.usage} }
	}
}
{
	name: vars_menu
	only_buffer_difference: true
	marker: "# "
	type: {
		layout: list
		page_size: 10
	}
	style: {
		text: green
		selected_text: green_reverse
		description_text: yellow
	}
	source: { |buffer, position|
		$nu.scope.vars
		| where name =~ $buffer
		| sort-by name
		| each { |it| {value: $it.name description: $it.type} }
	}
}
{
	name: commands_with_description
	only_buffer_difference: true
	marker: "# "
	type: {
		layout: description
		columns: 4
		col_width: 20
		col_padding: 2
		selection_rows: 4
		description_rows: 10
	}
	style: {
		text: green
		selected_text: green_reverse
		description_text: yellow
	}
	source: { |buffer, position|
		$nu.scope.commands
		| where name =~ $buffer
		| each { |it| {value: $it.name description: $it.usage} }
	}
}]

# utils
def "cargo search" [query: string, --limit=10] {
    ^cargo search $query --limit $limit
    | lines
    | each {
        |line| if ($line | str contains "#") {
            $line | parse --regex '(?P<name>.+) = "(?P<version>.+)" +# (?P<description>.+)'
        } else {
            $line | parse --regex '(?P<name>.+) = "(?P<version>.+)"'
        }
    }
    | flatten
}

def "cargo update-all" [--force] {
    cargo install --list
        | parse "{package} v{version}:"
        | get package
        | each {|p|
            if $force {
                cargo install --locked --force $p
            } else {
                cargo install --locked $p
            }
        }
}

def pwd [] {
  $env.PWD | str replace $nu.home-path '~'
}

def gitsummary [
    --count (-n): int = 999999
] {
    try {
        git log $"--pretty=%h»¦«%aN»¦«%s»¦«%aD" $"-($count)"
        | lines
        | split column "»¦«" sha1 committer desc merged_at
        | histogram committer merger
        | sort-by merger
        | reverse
    } catch {
        print "Error: Make sure you're in a git repository"
    }
}

def mega-update [--force (-f), --yes (-y)] {
    # confirmation check
    if $force and not $yes and not (input "Force update all packages? (y/n): " | str starts-with "y") {
        return
    }

    let par_results = ["cargo", "scoop"] | par-each { |manager|
        try {
            print $"Starting ($manager)..."
            if $manager == "cargo" {
                if $force {
                    do -i { cargo update-all --force }
                } else {
                    do -i { cargo update-all }
                }
            } else if $manager == "scoop" {
                if $force {
                    do -i { scoop update --all --force }
                } else {
                    do -i { scoop update --all }
                }
            }
            print $"✓ ($manager) completed"
            { manager: $manager, status: "success" }
        } catch { |e|
            print $"✗ ($manager) failed: ($e.msg)"
            { manager: $manager, status: "failed", error: $e.msg }
        }
    }

    # winget alone for input
    let winget_result = try {
        print "Starting winget..."
        if $force {
            do -i { winget upgrade --all --interactive --force }
        } else {
            do -i { winget upgrade --all --interactive }
        }
        print "✓ winget completed"
        { manager: "winget", status: "success" }
    } catch { |e|
        print $"✗ winget failed: ($e.msg)"
        { manager: "winget", status: "failed", error: $e.msg }
    }

    let all_results = $par_results | append $winget_result

    print "
All updates finished"

    $all_results
}
