let
	james = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA7WV4+7uhIWQVHEN/2K0jJPTaZ/HbG3W8OKSpzmPBI4";
	plum  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBH1S3dhOYCCltqrseHc3YZFHc9XU90PsvDo7frzUGrr root@plum";
	pear  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL2/Pg/5ohT3Dacnzjw9pvkeoQ1hEFwG5l1vRkr3v2sQ root@pear";
	kiwi  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ1AbTRPJiOAPE0u1HHqoMBeXhlenugGvIndnJVLETld root@kiwi";
	# users = [ james ];
in
{
  "hosts/plum/password.age".publicKeys = [ james plum ];
  "hosts/kiwi/password.age".publicKeys = [ james kiwi ];
  "hosts/plum/id.age".publicKeys       = [ james plum ];
  "hosts/pear/id.age".publicKeys       = [ james pear ];
	"hosts/kiwi/id.age".publicKeys       = [ james kiwi ];
}
