let
	inherit (import ./keys.nix) james plum pear kiwi all admins;
in
{
  "hosts/plum/password.age".publicKeys         = [ plum ] ++ admins;
  "hosts/kiwi/password.age".publicKeys         = [ kiwi ] ++ admins;
  "hosts/plum/id.age".publicKeys               = [ plum ] ++ admins;
  "hosts/pear/id.age".publicKeys               = [ pear ] ++ admins;
	"hosts/kiwi/id.age".publicKeys               = [ kiwi ] ++ admins;
	"hosts/plum/forgejo-password.age".publicKeys = [ plum ] ++ admins;
	"modules/acme/environment.age".publicKeys    = all;
}
