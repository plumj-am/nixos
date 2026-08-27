{ self, ... }:
{
  flake.modules.common.default = self.modules.common.entities;
  flake.modules.common.entities =
    { lib, ... }:
    let
      inherit (lib.attrsets)
        attrValues
        filterAttrs
        mapAttrs
        genAttrs
        ;
      inherit (lib.lists) elem concatMap unique;
      inherit (lib.types) attrsOf anything;
      inherit (lib.options) mkOption;
      inherit (lib.trivial) const;
      inherit (lib.fixedPoints) fix;

      everyone = removeAttrs entities.people [ "self" ];

      entities = fix (entities: {
        people = {
          self = entities.people.plumjam;

          plumjam = fix (plumjam: {
            userName = "jam";
            fullName = "PlumJam";
            domain = "plumj.am";
            email = "me@${plumjam.domain}";
            admin = true;
            extraGroups = [
              "grove-systems"
            ];
            git = {
              username = plumjam.fullName;
              email = "git@${plumjam.domain}";
            };
            sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA7WV4+7uhIWQVHEN/2K0jJPTaZ/HbG3W8OKSpzmPBI4 jam";
            radicleKey = "";
          });

          anamana = {
            userName = "anamana";
            fullName = "Anamana";
            admin = false;
            extraGroups = [
              "grove-systems"
            ];
            sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOnZeNqPD+w84UmI4EvQNcvmriL7bg0cf4qU86GzH62k anamana";
            radicleKey = "";
          };
        };

        machines = {
          blackwell = {
            sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGSi4SKhqze7ZzhJFcUF9KW/4nXX1MfvZjUqrYWNDi9c root@blackwell";
            radicleKey = "";
          };
          plum = {
            sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBH1S3dhOYCCltqrseHc3YZFHc9XU90PsvDo7frzUGrr root@plum";
            radicleKey = "";
          };
          pear = {
            sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL2/Pg/5ohT3Dacnzjw9pvkeoQ1hEFwG5l1vRkr3v2sQ root@pear";
            radicleKey = "";
          };
          kiwi = {
            sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElcSHxI64xqUUKEY83tKyzEH+fYT5JCWn3qCqtw16af root@kiwi";
            radicleKey = "";
          };
          lime = {
            sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeG5tRLj+z0LlAhH60rQuvRarHWuYE+fYMEgPvGbMrW jam@lime";
            radicleKey = "";
          };
          date = {
            sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEzfoVKZDyiyyMiX1JRFaaTELspG25MlLNq0kI2AANTa root@date";
            radicleKey = "";
          };
          yuzu = {
            sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDLlddona4PlORWd+QpR/7F5H46/Dic9vV23/YSrZl0 root@yuzu";
            radicleKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICvRi9abIjDLDqiwxnsWahI7mY+vwTrg2C8UW8c30q0X";
          };
          sloe = {
            sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK42xzC/vWHZC9SiU/8IBBd2pn7mggBYFQ8themKAic/ root@sloe";
            radicleKey = "";
          };
        };

        sshKeys =
          (everyone |> mapAttrs (_: { sshKey, ... }: sshKey))
          // (entities.machines |> mapAttrs (_: { sshKey, ... }: sshKey));

        sshKeysAdmins =
          everyone
          |> filterAttrs (
            _:
            {
              admin ? false,
              ...
            }:
            admin
          )
          |> attrValues
          |> map ({ sshKey, ... }: sshKey);

        radicleKeys =
          (everyone |> mapAttrs (_: { radicleKey, ... }: radicleKey))
          // (entities.machines |> mapAttrs (_: { radicleKey, ... }: radicleKey));

        groveSystemsMembers =
          everyone
          |> filterAttrs (
            _:
            {
              extraGroups ? [ ],
              ...
            }:
            elem "grove-systems" extraGroups
          );

        groveSystemsUsernames =
          everyone
          |> filterAttrs (
            _:
            {
              extraGroups ? [ ],
              ...
            }:
            elem "grove-systems" extraGroups
          )
          |> attrValues
          |> map ({ userName, ... }: userName);

        allExtraGroups =
          everyone
          |> attrValues
          |> concatMap (
            {
              extraGroups ? [ ],
              ...
            }:
            extraGroups
          )
          |> unique;
      });
    in
    {
      options.flake.entities = mkOption {
        type = attrsOf anything;
        default = { };
        description = ''
          All persistent entities associated with this configuration collection.
        '';
      };

      config.flake.entities = entities;

      config.users.groups = genAttrs entities.allExtraGroups (const { });
    };
}
