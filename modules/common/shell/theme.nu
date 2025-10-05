# TODO: Make 100 progress show full bar but prevent sticky notification.
def print-notify [message: string, progress: int = -1] {
    print $"(ansi purple)[Theme Switcher] ($message)"
    if (which notify-send | is-not-empty) {
        let base_args = ["--replace-id=1002" "--print-id"]

        # Don't add progress hint for completion (progress=100) so it times out.
        let args = if $progress >= 0 and $progress < 100 {
            $base_args | append ["--hint" $"int:value:($progress)"]
        } else {
            $base_args
        }

        let timeout = if ($message | str downcase | str contains "error") { 30000 } else { 15000 }
        let urgency = if ($message | str downcase | str contains "error") { "critical" } else { "normal" }

        ^notify-send ...$args --urgency=($urgency) --expire-time=($timeout) "Theme Switcher" $"($message)"
    }
}

def toggle-theme [theme?: string] {
    let dark_mode_file = $"($env.HOME)/.config/dark-mode"

    # Determine current theme from nix theme file.
    let theme_file = $"($env.HOME)/nixos/modules/common/theme.nix"
    let current_theme = try {
        let content = open $theme_file
        if ($content | str contains "is_dark = true;") {
            "dark"
        } else {
            "light"
        }
    } catch {
        "light"
    }

    # Check if using pywal scheme.
    let using_pywal = try {
        let content = open $theme_file
        $content | str contains 'color_scheme = "pywal";'
    } catch {
        false
    }

    # Use provided theme or toggle current.
    let new_theme = if $theme != null {
        if $theme in ["light", "dark"] {
            $theme
        } else {
            print $"Invalid theme: ($theme). Use 'light' or 'dark'"
            return
        }
    } else {
        print-notify $"Invalid theme: '($theme)'. Use 'light' or 'dark'."
        return
    }

    print-notify $"Switching to ($new_theme) theme."

    # If using pywal, regenerate colors from current wallpaper.
    if $using_pywal {
        print-notify "Regenerating pywal colors..." 20

        # Get current wallpaper from swww.
        let wallpaper = try {
            ^swww query | lines | first | parse "{monitor}: image: {path}" | get path.0
        } catch {
            null
        }

        if $wallpaper != null and ($wallpaper | path exists) {
            try {
                # Clear pywal cache to force regeneration from current wallpaper.
                ^rm -rf ~/.cache/wal

                let wal_args = if $new_theme == "dark" {
                    ["-n" "--saturate" "0.7" "-i" $wallpaper]
                } else {
                    ["-n" "--saturate" "0.6" "-l" "-i" $wallpaper]
                }
                ^wal --backend wal ...$wal_args err> /dev/null
                ^cp ~/.cache/wal/colors.json $"($env.HOME)/nixos/pywal-colors.json"
                print-notify $"Regenerated ($new_theme) mode pywal colors." 30
            } catch { |e|
                print-notify $"Warning: Failed to regenerate pywal colors: ($e.msg)" 30
            }
        } else {
            print-notify "Warning: Could not detect current wallpaper" 30
        }
    }

    # Update centralized theme file.
    try {
        let content = open $theme_file

        let updated = if $new_theme == "dark" {
            $content | str replace "is_dark = false;" "is_dark = true;"
        } else {
            $content | str replace "is_dark = true;" "is_dark = false;"
        }

        $updated | save $theme_file --force
        print $"updated theme to ($new_theme)"
    } catch { |e|
        print-notify $"Failed to switch theme: ($e.msg)"
        return
    }

    # Update system dark mode marker and environment variable.
    print-notify "Updating environment..." 40
    if $new_theme == "dark" {
        touch $dark_mode_file
        $env.THEME_MODE = "dark"
        print-notify "Dark mode activated." 50
    } else {
        if ($dark_mode_file | path exists) {
            rm $dark_mode_file
        }
        $env.THEME_MODE = "light"
        print-notify "Light mode activated." 50
    }

    # Rebuild configuration to apply themes.
    print-notify $"Rebuilding configuration to apply ($new_theme) theme." 75

    try {
        nu $"($env.HOME)/rebuild.nu" --quiet
    } catch { |e|
        print-notify "Error: Rebuild failed, run manually in a terminal." 100
        exit 1
    }

    print-notify $"Switch to the ($new_theme) theme completed!" 100
}

def switch-scheme [scheme: string] {
    let theme_file = $"($env.HOME)/nixos/modules/common/theme.nix"

    # Validate scheme.
    if $scheme not-in ["pywal", "gruvbox"] {
        print-notify $"Invalid scheme: '($scheme)'. Use 'pywal' or 'gruvbox'."
        return
    }

    print-notify $"Switching to ($scheme) color scheme."

    # If switching to pywal, generate colors from current wallpaper.
    if $scheme == "pywal" {
        print-notify "Generating pywal colors from current wallpaper..." 25

        # Determine current theme mode.
        let is_dark = try {
            let content = open $theme_file
            $content | str contains "is_dark = true;"
        } catch {
            false
        }

        # Get current wallpaper from swww.
        let wallpaper = try {
            ^swww query | lines | first | parse "{monitor}: image: {path}" | get path.0
        } catch {
            null
        }

        if $wallpaper != null and ($wallpaper | path exists) {
            try {
                # Clear pywal cache to force regeneration from current wallpaper.
                ^rm -rf ~/.cache/wal

                let wal_args = if $is_dark {
                    ["-n" "--saturate" "0.7" "-i" $wallpaper]
                } else {
                    ["-n" "--saturate" "0.6" "-l" "-i" $wallpaper]
                }
                ^wal --backend wal ...$wal_args err> /dev/null
                ^cp ~/.cache/wal/colors.json $"($env.HOME)/nixos/pywal-colors.json"
                print-notify "Generated pywal colors." 50
            } catch { |e|
                print-notify $"Warning: Failed to generate colors: ($e.msg)" 50
            }
        } else {
            print-notify "Warning: Could not detect current wallpaper" 50
        }
    }

    # Update color_scheme in theme.nix.
    try {
        let content = open $theme_file

        let updated = if $scheme == "pywal" {
            $content | str replace 'color_scheme = "gruvbox";' 'color_scheme = "pywal";'
        } else {
            $content | str replace 'color_scheme = "pywal";' 'color_scheme = "gruvbox";'
        }

        $updated | save $theme_file --force
        print $"Updated color_scheme to ($scheme)"
    } catch { |e|
        print-notify $"Failed to switch scheme: ($e.msg)"
        return
    }

    # Rebuild configuration to apply new scheme.
    print-notify $"Rebuilding configuration to apply ($scheme) scheme..." 75

    try {
        nu $"($env.HOME)/rebuild.nu" --quiet
    } catch { |e|
        print-notify "Error: Rebuild failed, run manually in a terminal."
        exit 1
    }

    print-notify $"Switch to ($scheme) scheme completed!" 100
}

# Main tt command - handles both light/dark and scheme switching.
export def tt [arg?: string] {
    if $arg == null {
        print "Usage: tt <dark|light|pywal|gruvbox>"
        return
    }

    match $arg {
        "dark" | "light" => { toggle-theme $arg }
        "pywal" | "gruvbox" => { switch-scheme $arg }
        _ => { print $"Invalid option: '($arg)'. Use: dark, light, pywal, or gruvbox." }
    }
}
