{ self, ... }:
{
  nix.settings.netrc-file = "/etc/.netrc";

  age.secrets.netrc = {
    rekeyFile = self + /secrets/netrc.age;
    path      = "/etc/.netrc";
    owner     = "root";
    group     = "root";
    mode      = "0400";
  };
}
