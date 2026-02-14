#!/usr/bin/env nu
let choice = echo "Shutdown\nReboot\nSleep\nHibernate\nLock"
| tofi --prompt-text "[power]"

match $choice {
   "Shutdown" => { systemctl poweroff }
   "Reboot" => { systemctl reboot }
   "Sleep" => { bash -c "hyprlock --quiet &"; systemctl suspend } # `job spawn` doesn't work for some reason.
   "Hibernate" => { bash -c "hyprlock --quiet &"; systemctl hibernate }
   "Lock" => { hyprlock --quiet }
   _ => { }
}
