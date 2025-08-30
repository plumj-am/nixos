let
	james = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA7WV4+7uhIWQVHEN/2K0jJPTaZ/HbG3W8OKSpzmPBI4";
	# users = [ james ];
in
{
  "hosts/plum/password.age".publicKeys = [ james ];
}
