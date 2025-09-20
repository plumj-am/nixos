let
	inherit (import ./keys.nix) jam plum pear kiwi yuzu date all admins;
in
{
	"hosts/plum/id.age".publicKeys               = [ plum ] ++ admins;
	"hosts/plum/password.age".publicKeys         = [ plum ] ++ admins;
	"hosts/plum/forgejo-password.age".publicKeys = [ plum ] ++ admins;

	"hosts/plum/matrix-signing-key.age".publicKeys         = [ plum ] ++ admins;
	"hosts/plum/matrix-registration-secret.age".publicKeys = [ plum ] ++ admins;

  "hosts/plum/cache/key.age".publicKeys = [ plum ] ++ admins;

  "hosts/plum/grafana/password.age".publicKeys = [ plum ] ++ admins;

	"hosts/kiwi/id.age".publicKeys       = [ kiwi ] ++ admins;
  "hosts/kiwi/password.age".publicKeys = [ kiwi ] ++ admins;

  "hosts/pear/id.age".publicKeys       = [ pear ] ++ admins;
	"hosts/pear/password.age".publicKeys = [ pear ] ++ admins;

	"hosts/date/id.age".publicKeys       = [ date ] ++ admins;
	"hosts/date/password.age".publicKeys = [ date ] ++ admins;

	"hosts/yuzu/id.age".publicKeys       = [ yuzu ] ++ admins;
	"hosts/yuzu/password.age".publicKeys = [ yuzu ] ++ admins;

	"modules/acme/environment.age".publicKeys = all;

  "hosts/kiwi/github2forgejo/environment.age".publicKeys = [ kiwi ] ++ admins;

  "hosts/kiwi/dr-radka-environment.age".publicKeys = [ kiwi ] ++ admins;

}
