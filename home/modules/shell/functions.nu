def zellij-update-tabname [] {
    if ("ZELLIJ" in $env) {
        let tab_name = if ((pwd) == $env.HOME) {
            "~"
        } else {
            (pwd | path parse | get stem)
        };
        
        zellij action rename-tab $tab_name;
    }
}

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

    let results = try {
        print "Starting cargo updates..."
        if $force {
            do -i { cargo update-all --force }
        } else {
            do -i { cargo update-all }
        }
        print "cargo completed"
        [{ manager: "cargo", status: "success" }]
    } catch { |e|
        print $"cargo failed: ($e.msg)"
        [{ manager: "cargo", status: "failed", error: $e.msg }]
    }

    print "
All updates finished"

    $results
}
