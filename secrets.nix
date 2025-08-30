let
	james = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA7WV4+7uhIWQVHEN/2K0jJPTaZ/HbG3W8OKSpzmPBI4";
	plum = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7VV+Jow/4g+m8CY1JRsuAngSrazPzmzchbnpTyEHA8 root@plum";
	# users = [ james ];
in
{
  "hosts/plum/password.age".publicKeys = [ james plum ];
  "hosts/plum/id.age".publicKeys = [ james plum ];
}
