#!/usr/bin/env nu
def main [] {}

def "main nixos-anywhere" [--host: string --remote: string] {
   print "nix run'ning nixos-anywhere"
   (nix run github:nix-community/nixos-anywhere --
      --generate-hardware-config nixos-facter $"./hosts/facter/($host).json"
      --flake $".#($host)"
      --target-host root@($remote)
      --option builders ""
      --phases kexec,disko,install # Skip reboot to verify setup for Agenix.
      --build-on local)
}

def "main generate-facter-config" [] {
   print "nix run'ning nixos-facter"
   (sudo nix run
      --option experimental-features "nix-command flakes"
      --option extra-substituters https://numtide.cachix.org
      --option extra-trusted-public-keys numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=
      github:nix-community/nixos-facter
      --
      --output $"./(hostname).json")
}

def "main copy-user-ssh" [--host: string --remote: string] {
   print "cp'ing jam ssh keys"
   (rsync
      --acls
      --verbose
      /home/jam/.ssh/
      jam@($host):/home/jam/.ssh/
   )
}

def "main copy-root-ssh" [--host: string --remote: string] {
   print "decrypting the host private key"
   (nix run
      nixpkgs#age
      --
      --decrypt
      --identity ./yubikey.pub
      $"./secrets/($host)-id.age"
   ) out> tmp-id-($host).txt

   print "nix eval'ing the hostPubkey"
   (nix eval
      $".#nixosConfigurations.($host).config.age.rekey.hostPubkey"
   ) | str trim --char '"' out> tmp-id-pub-($host).txt

   print "touch'ing the necessary files"
   (ssh root@($remote) "cd /root && mkdir --parents .ssh && cd .ssh && touch id id.pub")

   print "cp'ing root ssh public key"
   (rsync
      --verbose
      /home/jam/nixos/tmp-id-pub-($host).txt
      root@($remote):/root/.ssh/id.pub
   )

   print "cp'ing root ssh private key"
   (rsync
      --verbose
      /home/jam/nixos/tmp-id-($host).txt
      root@($remote):/root/.ssh/id
   )

   print "chmod'ing root ssh keys"
   (ssh root@($remote) "cd .ssh && chmod 0600 id*")

   print "rm'ing local temporary files"
   rm ./tmp-id-($host).txt
   rm ./tmp-id-pub-($host).txt
}

def "main full-nixos-anywhere-setup" [--host: string --remote: string] {
   print $"Starting the full deployment process for ($host)"

   print $"ssh-keygen -R'ing the necessary local keys"

   (ssh-keygen -R ($remote))

   input $"Make sure you have run 'sudo passwd' on the new host \(($host) | ($remote)\) before continuing. Press any button to continue."

   main copy-root-ssh --host $host --remote $remote

   main nixos-anywhere --host $host --remote $remote

   main copy-user-ssh --host $host --remote $remote

   print "full-nixos-anywhere-setup'ing complete!"
   print "rebuild will not take place automatically, SSH to the machine to verify secrets etc."
}

def "main reset-circus-db" [] {
   ssh root@plum "
      sudo -u postgres dropdb circus
      sudo -u postgres createdb -O circus circus
      sudo -u circus circus-migrate up postgresql:///circus?host=/run/postgresql

      systemctl restart circus-server.service
      systemctl restart circus-queue-runner.service
      systemctl restart circus-evaluator.service
   "
}

def "main fill-caches-remote" [] {
   let hosts = [date plum sloe]
   let builds = [date kiwi plum sloe yuzu]

   $hosts | par-each {|host|
   jj file list
   | (rsync
      --archive
      --compress
      --delete --recursive --force
      --delete-excluded
      --delete-missing-args
      --human-readable
      --delay-updates
      --rsh "ssh -o RemoteCommand=none"
      --files-from - ./ $"jam@($host):nixos")

      for b in $builds {
         ssh jam@($host) $"cd ~/nixos ; nix build .#nixosConfigurations.($b).config.system.build.toplevel --builders \"\" --repair --fallback"
      }
   }
}

def "main fill-caches-local" [] {
   let hosts = [date kiwi plum sloe yuzu]
   let copyable = $hosts | where {|h| $h != (hostname)}

   for h in $hosts {
      let target =  $".#nixosConfigurations.($h).config.system.build.toplevel"
      rom build ($target) -- --builders "" --repair --fallback

      for hh in $hosts {
         if $hh in $copyable {
            nix copy --to ssh://root@($h) $target
         }
      }
   }

}

# let reboot into installer again
# find drives and mnt to /mnt and /mnt/boot
# nixos-enter
# add root ssh keys
# exit
# nixos-enter (should show decryption successful)
