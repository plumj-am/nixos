{
  nix.settings.netrc-file = "/etc/.netrc";

  age.secrets.netrc = {
    rekeyFile = ./netrc.age;
    path      = "/etc/.netrc";
    owner     = "root";
    group     = "root";
    mode      = "0400";
  };
}
