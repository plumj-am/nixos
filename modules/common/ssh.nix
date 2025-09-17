{ lib, ... }:
let
	inherit (lib) enabled;
in
{
	environment.shellAliases.mosh = "mosh --no-init";

	programs.mosh = enabled {
		openFirewall = true;
	};

	home-manager.sharedModules = [{
	  programs.ssh = enabled {
			enableDefaultConfig = false;
			extraConfig = ''
				strictHostKeyChecking accept-new
				identitiesOnly yes
			'';
	    matchBlocks."*" = {
				setEnv.COLORTERM = "truecolor";
				setEnv.TERM      = "xterm-256color";

				controlMaster       = "auto";
				controlPersist      = "60m";
				serverAliveCountMax = 2;
				serverAliveInterval = 60;

				identityFile = "~/.ssh/id";
	    };
	  };
  }];
}
