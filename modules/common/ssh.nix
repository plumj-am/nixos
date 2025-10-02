{ lib, config, ... }:
let
	inherit (lib) enabled;
in
{
	environment.shellAliases.mosh = "mosh --no-init";

	programs.mosh = enabled {
		openFirewall = true;
	};

	home-manager.sharedModules = [
		(homeArgs: let
			identityPath = if config.isLinux then
				"${homeArgs.config.home.homeDirectory}/.ssh/id"
			else
				"${config.users.users.${config.system.primaryUser}.home}/.ssh/id";
		in {
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

					identityFile = identityPath;
				};
			};
		})
	];
}
