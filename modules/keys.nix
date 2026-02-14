let
  commonModule =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) attrsOf anything;
      inherit (lib.attrsets) attrValues;

      keys = {
        jam = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA7WV4+7uhIWQVHEN/2K0jJPTaZ/HbG3W8OKSpzmPBI4 jam";
        plum = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBH1S3dhOYCCltqrseHc3YZFHc9XU90PsvDo7frzUGrr root@plum";
        pear = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL2/Pg/5ohT3Dacnzjw9pvkeoQ1hEFwG5l1vRkr3v2sQ root@pear";
        kiwi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElcSHxI64xqUUKEY83tKyzEH+fYT5JCWn3qCqtw16af root@kiwi";
        date = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEzfoVKZDyiyyMiX1JRFaaTELspG25MlLNq0kI2AANTa root@date";
        yuzu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDLlddona4PlORWd+QpR/7F5H46/Dic9vV23/YSrZl0 root@yuzu";
        sloe = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK42xzC/vWHZC9SiU/8IBBd2pn7mggBYFQ8themKAic/ root@sloe";
        anamana = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOnZeNqPD+w84UmI4EvQNcvmriL7bg0cf4qU86GzH62k anamana";
      };
    in
    {
      options.flake.keys = mkOption {
        type = attrsOf anything;
        default = { };
        description = "SSH public keys";
      };

      config.flake.keys = keys // {
        admins = [ keys.jam ];
        all = attrValues keys;
      };
    };
in
{
  flake.modules.nixos.keys = commonModule;
  flake.modules.darwin.keys = commonModule;
}
