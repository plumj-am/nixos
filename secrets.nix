let
	inherit (import ./keys.nix) james plum pear kiwi all admins;
in
{
	"hosts/plum/id.age".publicKeys                    = [ plum ] ++ admins;
	"hosts/plum/password.age".publicKeys              = [ plum ] ++ admins;
	"hosts/plum/forgejo-password.age".publicKeys      = [ plum ] ++ admins;
	"hosts/plum/matrix-signing-key.age".publicKeys    = [ plum ] ++ admins;
	"hosts/plum/matrix-registration-secret.age".publicKeys = [ plum ] ++ admins;

	"hosts/kiwi/id.age".publicKeys               = [ kiwi ] ++ admins;
  "hosts/kiwi/password.age".publicKeys         = [ kiwi ] ++ admins;

  "hosts/pear/id.age".publicKeys               = [ pear ] ++ admins;

	"modules/acme/environment.age".publicKeys = all;

  "hosts/kiwi/github2forgejo/environment.age".publicKeys = [ kiwi ] ++ admins;

  "hosts/kiwi/dr-radka-environment.age".publicKeys = [ kiwi ] ++ admins;
}
