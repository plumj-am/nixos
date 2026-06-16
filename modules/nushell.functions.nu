def zellij-update-tabname []: nothing -> nothing {
   if "ZELLIJ" in $env {
      let tab_name = if (pwd) == $env.HOME {
         "~"
      } else {
         (pwd | path parse | get stem)
      }

      zellij action rename-tab $tab_name
   }
}

def "cargo search" [query: string, --limit: int = 10]: nothing -> table {
   cargo search $query --limit $limit
   | lines
   | each {|line|
      if ($line =~ "#") {
         $line | parse --regex '(?P<name>.+) = "(?P<version>.+)" +# (?P<description>.+)'
      } else {
         $line | parse --regex '(?P<name>.+) = "(?P<version>.+)"'
      }
   }
   | flatten
}

def "cargo update-all" [--force]: nothing -> nothing {

   # nu-lint-ignore: non_final_failure_check
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

def pwd []: any -> string {
   $env.PWD | str replace $nu.home-dir '~'
}

# nu-lint-ignore: print_and_return_data
def "git summary" [--count(-n): int = 10]: nothing -> nothing {
   try {
      git log $"--pretty=%h»¦«%aN»¦«%s»¦«%aD" $"-($count)"
      | lines
      | split column »¦« sha1 committer desc merged_at
      | histogram committer merger
      | sort-by merger
      | reverse
      | table --index 1 # start index from 1
   } catch { print "Error: Make sure you're in a git repository" }
}

def tmux-ide [session: string = "main"] {
   if (tmux has-session -t $session | complete | get exit_code) == 0 {
      tmux kill-session -t $session
   }

   tmux new-session -d -s $session

   # Vertical split
   tmux split-window -v -p 28 -t $"($session).0"

   # Horizontal split top
   tmux split-window -h -p 18 -t $"($session).0"

   # Horizontal split bottom
   tmux split-window -h -p 50 -t $"($session).2"

   tmux select-pane -t $"($session).0"

   tmux attach -t $session
}
