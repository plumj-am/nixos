{
  perSystem =
    { lib, pkgs, ... }:
    let
      inherit (lib.meta) getExe;
    in
    {
      packages.helpers =
        pkgs.writers.writeNuBin "helpers" # nu
          ''
            def main [--help (-h)] {
              if $help { help main; exit 0 }
            }

            def "main nixos-anywhere" [
              --host: string   # host to build
              --remote: string # remote to copy to
            ]: nothing -> string {
              print $"running nixos-anywhere for remote ($remote)..."
              (${getExe pkgs.nixos-anywhere}
                --generate-hardware-config nixos-facter $"./hosts/facter/($host).json"
                --flake $".#($host)"
                --target-host root@($remote)
                --option builders ""
                --phases kexec,disko,install # Skip reboot to verify setup for sops.
                --build-on local)
            }

            def "main generate-facter-config" []: nothing -> string {
              print "running nixos-facter..."
              try {
                (sudo ${getExe pkgs.nixos-facter}
                --output $"./(sys host | get hostname).json")
              } catch {|e|
                error make $"failed to generate nixos-facter config: ($e)"
              }
            }

            def "main copy-user-ssh" [
              --host: string   # host to build
            ]: nothing -> string {
              print $"copying jam ssh keys to ($host)..."

              (${getExe pkgs.rsync}
                --acls
                --verbose
                /home/jam/.ssh/
                jam@($host):/home/jam/.ssh/)
            }

            def "main copy-root-ssh" [
              --host: string   # host to build
              --remote: string # remote to copy to
            ] {
              print "decrypting the host private key..."
              (${getExe pkgs.sops}
                --decrypt
                $"./secrets/($host)/id.yaml")
                | from yaml
                | get id out> tmp-id-($host).txt

              print "evaluating the hostPubkey..."

              (${getExe pkgs.nix}
                eval
                $".#nixosConfigurations.($host).config.flake.keys.($host)")
                | str trim --char '"' out> tmp-id-pub-($host).txt

              print "creating the necessary files..."

              try {
                ssh root@($remote) "cd /root && mkdir --parents .ssh && cd .ssh && touch id id.pub"
              } catch {|e|
                error make $"failed to touch the necessary files: ($e)"
              }

              print "copying root ssh public key..."

              (${getExe pkgs.rsync}
                --verbose
                /home/jam/nixos/tmp-id-pub-($host).txt
                root@($remote):/root/.ssh/id.pub)

              print "copying root ssh private key..."

              (${getExe pkgs.rsync}
                --verbose
                /home/jam/nixos/tmp-id-($host).txt
                root@($remote):/root/.ssh/id
              )

              print "updating ownership root ssh keys..."

              try {
                ssh root@($remote) "cd .ssh && chmod 0600 id*"
              } catch {|e|
                error make $"failed to chmod the root ssh keys: ($e)"
              }

              print "removing local temporary files..."

              try {
                rm ./tmp-id-($host).txt
                rm ./tmp-id-pub-($host).txt
              } catch {|e|
                error make $"failed to remove local tmp-id-* files; remove them manually: ($e)"
              }
            }

            def "main full-nixos-anywhere-setup" [
              --host: string   # host to build
              --remote: string # remote to copy to
            ]: nothing -> nothing {
              print $"starting the full deployment process for ($host)..."

              print $"generating the necessary local keys with ssh-keygen..."

              try {
                ssh-keygen -R ($remote)
              } catch {|e|
                error make $"ssh-keygen failed: ($e)"
              }

              input $"Make sure you have:
              - run 'sudo passwd' on the new host \(($host) | ($remote)\)
              - enabled openssh service with `services.openssh.settings.PermitRootLogin = "yes";`
              - allowed port 22 (TCP)
              - disabled automatic sleep
            before continuing, if necessary.
            Press any button to continue."

              main copy-root-ssh --host $host --remote $remote
              main nixos-anywhere --host $host --remote $remote
              main copy-user-ssh --host $host

              print "full-nixos-anywhere-setup'ing complete!"
              print "rebuild will not take place automatically, SSH to the machine to verify secrets etc."
            }

            # let reboot into installer again
            # find drives and mnt to /mnt and /mnt/boot
            # nixos-enter
            # add root ssh keys
            # exit
            # nixos-enter (should show decryption successful)
          '';
    };
}
