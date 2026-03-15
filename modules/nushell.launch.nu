#!/usr/bin/env nu
let apps = [
   {name: steam, app: steam}
   {name: "dev.zed.Zed", app: zeditor}
   {name: radicle-desktop, app: radicle-desktop}
   {name: thunderbird, app: thunderbird}
   {name: OpenCode, app: OpenCode}
   {name: vesktop, app: vesktop}
   {name: brave, app: brave}
]

for a in $apps {
   if (^niri msg windows | find $a.name | is-empty) {
      print $"($a.name) is not running. Launching now."
      bash -c $"($a.app) &" # `job spawn` doesn't work here.
   } else {
      print $"($a.name) is already running"
   }
}
