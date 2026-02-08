#!/usr/bin/env nu
let choice = echo "Shutdown\nReboot\nSleep\nHibernate\nLock"
| tofi --prompt-text "[power]"

match $choice {
   "Shutdown" => { systemctl poweroff }
   "Reboot" => { systemctl reboot }
   "Sleep" => { hyprlock --quiet & systemctl suspend }
   "Hibernate" => { hyprlock --quiet & systemctl hibernate }
   "Lock" => { hyprlock --quiet --grace 5 }
   _ => { }
}
