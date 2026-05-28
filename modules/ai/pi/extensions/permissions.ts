import { matchesGlob, relative, resolve } from "node:path"
import { homedir } from "node:os"
import { appendFileSync, mkdirSync } from "node:fs"
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@mariozechner/pi-coding-agent"
import {
	Editor,
	type EditorTheme,
	Key,
	matchesKey,
	truncateToWidth,
} from "@mariozechner/pi-tui"

let autoDenyTimeoutEnabled = true
let autoDenyTimeoutMs = 30000
let yoloMode = false

// Read-only allowlist patterns (strict mode)
export const allowedPatterns: string[] = [
	"ag*",
	"awk*",
	"bat*",
	"cat*",
	"command*",
	"echo*",
	"false",
	"fd*",
	"find*",
	"fzf*",
	"grep*",
	"head*",
	"hyperfine*",
	"less*",
	"ls*",
	"rg*",
	"sg*",
	"sort*",
	"tail*",
	"tree*",
	"true",
	"uniq*",
	"wait*",
	"wc*",
	"which*",
	"xargs*",

	"jj bookmark list*",
	"jj commit -m*",
	"jj commit --message*",
	"jj desc -m*",
	"jj desc --message*",
	"jj describe -m*",
	"jj describe --message*",
	"jj diff*",
	"jj evolog*",
	"jj file list*",
	"jj file search*",
	"jj file show*",
	"jj git colocation status*",
	"jj git remote list*",
	"jj git root*",
	"jj help*",
	"jj interdiff*",
	"jj log*",
	"jj new -m*",
	"jj new --message*",
	"jj op diff*",
	"jj op log*",
	"jj op show*",
	"jj operation diff*",
	"jj operation log*",
	"jj operation show*",
	"jj resolve --list*",
	"jj root*",
	"jj show*",
	"jj sparse list*",
	"jj st*",
	"jj status*",
	"jj tag list*",
	"jj util config-schema*",
	"jj version*",
	"jj workspace list*",
	"jj workspace root*",

	"git branch --list*",
	"git branch --show-current*",
	"git diff*",
	"git log*",
	"git show*",
	"git status*",

	"cargo build*",
	"cargo check*",
	"cargo clippy*",
	"cargo fmt*",
	"cargo nextest*",
	"cargo test*",
	"cargo tree*",

	"curl http://localhost*",
	"curl -s http://localhost*",
	"curl -X GET http://localhost*",
	"curl -s -X GET http://localhost*",
	"curl -X POST http://localhost*",
	"curl -s -X POST http://localhost*",
	"curl -X PUT http://localhost*",
	"curl -s -X PUT http://localhost*",
	"curl -X DELETE http://localhost*",
	"curl -s -X DELETE http://localhost*",

	"nix*build*",
	"nix*eval*",
	"nix*flake check*",
	"nix*flake metadata*",
	"nix*log*",
	"nix search*",

	"fj --help*",
	"fj*--help*",
	"fj actions tasks*",
	"fj -H https://git.plumj.am actions tasks*",
	"fj issue search*",
	"fj -H https://git.plumj.am issue search*",
	"fj issue view*",
	"fj -H https://git.plumj.am issue view*",
	"fj pr list*",
	"fj -H https://git.plumj.am pr list*",
	"fj repo view*",
	"fj -H https://git.plumj.am repo view*",
	"fj wiki contents*",
	"fj -H https://git.plumj.am wiki contents*",
	"fj wiki view*",
	"fj -H https://git.plumj.am wiki view*",

	"fasm*",
	"go build*",
	"go fmt*",
	"go test*",
	"node --check*",
	"npx tsc*",
	"zig build*",
]

// Commands that are forbidden and show a replacement instruction instead
export const forbiddenCommandsWithAlternatives: Array<{
	command: string
	reason: string
}> = [
	{
		command: "sed*",
		reason:
			"Use `read` with `offset` parameter instead of sed to read specific lines. Use the edit tool for edits.",
	},
]

// Forbidden path patterns (strict mode)
export const forbiddenPathPatterns: string[] = [
	"**/run/agenix",
	"**/.env",
	"**/.env.*",
	"**/.envrc",
	"**/.envrc.*",
	"**/.ssh/**",
	"**/.gnupg/**",
	"**/.aws/**",
	"**/.netrc",
	"**/.npmrc",
	"**/.pypirc",
	"**/.cargo/credentials",
	"**/.config/gcloud",
	"**/.config/azure",
	"**/.config/aws",
	"**/.kube/**",
	"**/.terraform.d",
	"**/.terragrunt-cache",
	"/etc/shadow",
	"/etc/sudoers",
	"/etc/passwd",
	"/etc/group",
	"/root/.ssh/**",
	"/root/.gnupg/**",
	"/home/*/.ssh/**",
	"/home/*/.gnupg/**",
	"**/kubeconfig",
	"**/vaulttoken",
	"**/vaultsecret",
	"**/GITHUB_TOKEN",
	"**/AWS_ACCESS_KEY",
	"**/AWS_SECRET_KEY",
	"*EDITOR*vim*.swp",
]

// Commands that are always blocked regardless of yolo mode
// This is a comprehensive blocklist. Err on the side of caution.
export const veryDangerousCommands: string[] = [
	// ====== Filesystem destruction ======
	"rm -rf /",
	"rm -rf /*",
	"rm -rf --no-preserve-root*",
	"rm -rf /boot*",
	"rm -rf /bin*",
	"rm -rf /sbin*",
	"rm -rf /lib*",
	"rm -rf /etc*",
	"rm -rf /usr*",
	"rm -rf /var*",
	"rm -rf /opt*",
	"rm -rf /nix*",
	"rm -rf /System*",
	"rm -rf /nix/store/*",
	"rm -rf /nix/var/*",
	"rm -rf /dev/*",
	"rm -rf /proc/*",
	"rm -rf /sys/*",
	"rm -rf /run/*",

	// ====== Block device destruction ======
	"dd if=*of=/dev/sd*",
	"dd if=*of=/dev/nvme*",
	"dd if=*of=/dev/vd*",
	"dd if=*of=/dev/mmc*",
	"dd if=*of=/dev/loop*",
	"dd if=*of=/dev/mapper/*",
	"dd if=*of=/dev/md*",
	"dd if=*of=/dev/zram*",
	"dd if=*of=/dev/disk/*",
	"wipefs -a*",
	"wipefs -fa*",
	"blkdiscard /dev/*",
	"hdparm --wipe*",
	"sgdisk --zap-all*",
	"sgdisk -o*",

	// ====== Partitioning / formatting ======
	"mkfs*",
	"mkfs.ext*",
	"mkfs.btrfs*",
	"mkfs.xfs*",
	"mkfs.fat*",
	"mkfs.vfat*",
	"mkfs.ntfs*",
	"mkfs.reiserfs*",
	"mkfs.zfs*",
	"mkfs.f2fs*",
	"mke2fs*",
	"mkswap /dev/*",
	"fdisk /dev/sd*",
	"fdisk /dev/nvme*",
	"fdisk /dev/vd*",
	"fdisk /dev/mmc*",
	"fdisk /dev/loop*",
	"fdisk /dev/mapper/*",
	"fdisk /dev/md*",
	"cfdisk /dev/*",
	"sfdisk /dev/*",
	"parted /dev/*",
	"parted -s /dev/*",
	"partprobe /dev/*",
	"gdisk /dev/sd*",
	"gdisk /dev/nvme*",

	// ====== LVM destruction ======
	"pvcreate /dev/*",
	"vgcreate *",
	"lvcreate *",
	"pvremove /dev/*",
	"pvremove --force*",
	"vgremove *",
	"vgremove --force*",
	"lvremove *",
	"lvremove --force*",
	"lvchange -an*",
	"vgchange -an*",
	"pvchange -x n*",
	"lvresize * /dev/*",
	"pvmove *",

	// ====== RAID ======
	"mdadm --create*",
	"mdadm --stop*",
	"mdadm --zero-superblock*",
	"mdadm --fail*",
	"mdadm --remove*",
	"mdadm --manage --stop*",

	// ====== ZFS ======
	"zpool destroy*",
	"zfs destroy -r*",
	"zpool create*",
	"zpool remove*",
	"zpool offline /dev/*",
	"zpool labelclear*",
	"zpool split*",

	// ====== Btrfs ======
	"btrfs device remove*",
	"btrfs device delete*",
	"btrfs balance start -dusage=0*",
	"btrfs balance start --full-balances*",
	"btrfs subvolume delete /",
	"btrfs subvolume delete /*",

	// ====== Encryption ======
	"cryptsetup luksFormat /dev/*",
	"cryptsetup luksRemoveKey /dev/*",
	"cryptsetup luksErase /dev/*",
	"cryptsetup erase /dev/*",
	"cryptsetup reencrypt /dev/*",
	"cryptsetup convert*",

	// ====== System permissions destruction ======
	"chmod -R 0 /",
	"chmod -R 0 /*",
	"chmod -R 000 /",
	"chmod -R 000 /*",
	"chmod 0 /*",
	"chmod 0 /",
	"chmod 000 /*",
	"chmod 000 /",
	"chmod -R 777 /",
	"chmod -R a+rwx /*",
	"chown -R 0:0 /",
	"chown -R 0:0 /*",
	"chown -R root:root /*",
	"chown -R nobody:nogroup /*",
	"chmod 0 /etc*",
	"chmod -R 0 /nix*",

	// ====== Remount / unmount ======
	"mount -o remount,ro /",
	"mount -o remount,ro /*",
	"mount -t tmpfs tmpfs /",
	"mount -t tmpfs tmpfs /*",
	"mount --bind /dev/null /etc*",
	"umount /",
	"umount /*",
	"umount -a",
	"umount -f /",
	"umount -l /",
	"umount -R /",
	"swapoff -a",
	"swapoff /dev/*",

	// ====== Kernel manipulation ======
	"sysctl -w kernel*",
	"sysctl -w vm*",
	"sysctl -w net.ipv*",
	"echo c > /proc/sysrq-trigger",
	"echo b > /proc/sysrq-trigger",
	"echo o > /proc/sysrq-trigger",
	"echo i > /proc/sysrq-trigger",
	"echo s > /proc/sysrq-trigger",
	"echo u > /proc/sysrq-trigger",
	"echo 1 > /proc/sys/kernel/sysrq",
	"echo 0 > /proc/sys/kernel/sysrq",
	"modprobe -r*",
	"rmmod *",
	"insmod *",
	"kexec*",

	// ====== Boot / power management ======
	"shutdown*",
	"poweroff*",
	"reboot*",
	"halt*",
	"init 0",
	"init 6",
	"init 1",
	"telinit 0",
	"telinit 6",
	"telinit 1",
	"systemctl poweroff",
	"systemctl reboot",
	"systemctl halt",
	"systemctl kexec",
	"systemctl emergency",
	"systemctl rescue",
	"systemctl soft-reboot",
	"systemctl exit",
	"systemctl switch-root*",

	// ====== Network destruction ======
	"iptables -F",
	"iptables -F*",
	"iptables -X",
	"iptables -P INPUT DROP",
	"iptables -P INPUT ACCEPT",
	"iptables -P FORWARD DROP",
	"iptables -P OUTPUT DROP",
	"iptables -t nat -F",
	"iptables -t mangle -F",
	"ip6tables -F",
	"ip6tables -X",
	"ip6tables -P*DROP",
	"iptables-save",
	"iptables-restore*",
	"nft flush ruleset",
	"nft delete table*",
	"ip link set * down",
	"ip link set lo down",
	"ip link delete *",
	"ip addr flush *",
	"ip route del default*",
	"ip route flush *",
	"route del default*",
	"route add default*",
	"ifconfig * down",
	"ifconfig * 0.0.0.0",
	"ifdown *",
	"iw dev * disconnect",
	"iw dev * del",
	"rfkill block all",
	"rfkill unblock all",
	"systemctl stop NetworkManager",
	"systemctl disable NetworkManager",
	"systemctl stop systemd-networkd",
	"systemctl disable systemd-networkd",
	"systemctl stop networking",
	"systemctl disable networking",
	"systemctl stop nscd",
	"systemctl stop resolved",
	"systemctl disable resolved",
	"resolvectl dns *",
	"resolvectl domain *",
	"ufw disable",
	"ufw reset",
	"ufw --force reset",
	"systemctl stop ufw",
	"systemctl disable ufw",
	"systemctl stop firewalld",
	"systemctl disable firewalld",
	"firewall-cmd --complete-reload",

	// ====== Security subsystem ======
	"setenforce 0",
	"setenforce Permissive",
	"setenforce permissive",
	"echo 0 > /selinux/enforce",
	"systemctl stop selinux*",
	"systemctl disable selinux*",
	"aa-disable *",
	"aa-complain *",
	"apparmor_parser -R*",
	"systemctl stop apparmor*",
	"systemctl disable apparmor*",
	"pam-auth-update --remove*",
	"semanage permissive*",

	// ====== User / auth destruction ======
	"passwd -d*",
	"passwd -l*",
	"passwd -u*",
	"passwd root*",
	"passwd * NOPASSWD*",
	"usermod -L*",
	"usermod -p ''*",
	"usermod -s /bin/false*",
	"usermod -G ''*",
	"userdel -r*",
	"userdel -f*",
	"groupdel*",
	"chage -E 0*",
	"chage -E -1*",
	"chpasswd*",
	"newusers*",

	// ====== SSH / remote access ======
	"rm -rf /etc/ssh*",
	"rm -rf ~/.ssh*",
	"chmod 0 /etc/ssh*",
	"chmod 0 ~/.ssh*",
	"echo PermitRootLogin*",
	"echo PasswordAuthentication*",
	"sed -i *PermitRootLogin*",
	"sed -i *PasswordAuthentication*",
	"sed -i *PubkeyAuthentication*",
	"systemctl stop sshd",
	"systemctl disable sshd",
	"systemctl stop ssh",
	"systemctl disable ssh",
	"systemctl stop dropbear",
	"systemctl disable dropbear",

	// ====== Service destruction ======
	"systemctl disable dbus*",
	"systemctl stop dbus*",
	"systemctl disable systemd-journald*",
	"systemctl stop systemd-journald*",
	"systemctl disable systemd-logind*",
	"systemctl stop systemd-logind*",
	"systemctl disable systemd-udevd*",
	"systemctl stop systemd-udevd*",
	"systemctl disable polkit*",
	"systemctl stop polkit*",
	"systemctl disable accounts-daemon*",
	"systemctl stop accounts-daemon*",
	"systemctl mask *",

	// ====== Process destruction ======
	"kill -9 -1",
	"kill -9 1",
	"killall -9*",
	"killall -r*",
	"kill -9 $(pidof *)",
	"kill -9 $(pgrep *)",
	"pkill -9*",
	"pkill -f *",
	"kill -STOP *",
	"kill -TERM 1",

	// ====== Package manager destruction ======
	"nix-env -e *",
	"nix-env --uninstall *",
	"nix-env -e system*",
	"nix-collect-garbage -d",
	"nix-store --delete *",
	"nix-store --gc *",
	"nix-store --repair *",
	"nix build --no-link --print-out-paths * | xargs rm -rf*",
	"nix profile remove *",
	"nix profile wipe-history*",
	"dpkg --purge *",
	"dpkg --remove *",
	"dpkg -P *",
	"apt-get remove *",
	"apt-get purge *",
	"apt-get autoremove*",
	"apt-get --purge remove*",
	"apt remove *",
	"apt purge *",
	"apt autoremove*",
	"rpm -e *",
	"rpm --erase *",
	"pacman -Rdd *",
	"pacman -Rsc *",
	"pacman -Rns *",
	"pacman -Scc",
	"pacman -S --force*",
	"pacstrap*",

	// ====== Container destruction ======
	"docker rm -f $(docker ps -aq)",
	"docker rm -f $(docker container ls -q)",
	"docker system prune -a*",
	"docker system prune --volumes*",
	"docker container prune -f*",
	"docker image prune -a*",
	"docker volume prune -a*",
	"docker network prune*",
	"docker compose down -v*",
	"docker kill $(docker ps -q)",
	"docker stop $(docker ps -q)",
	"podman rm -fa*",
	"podman system prune -af*",
	"podman system reset*",
	"podman pod rm -fa*",
	"podman volume prune -af*",
	"podman compose down -v*",
	"podman kill -a*",
	"runc delete*",
	"containerd*",
	"nerdctl system prune*",
	"nerdctl volume prune*",

	// ====== DB ======
	"pg_drop*",
	"dropdb*",
	"dropuser*",
	"psql -c *DROP DATABASE*",
	"psql -c *DROP TABLE*",
	"psql -c *TRUNCATE*",
	"psql -c *DELETE FROM*users*",
	"mysql -e *DROP DATABASE*",
	"mysql -e *DROP TABLE*",
	"mysqladmin drop*",
	"mongosh --eval *db.dropDatabase*",
	"mongosh --eval *db.drop*",
	"redis-cli FLUSHALL",
	"redis-cli FLUSHDB",
	"redis-cli CONFIG SET *",
	"redis-cli DEBUG SEGFAULT",
	"redis-cli SHUTDOWN*",
	"sqlite3 */var/lib/* .dump",
	"sqlite3 */var/lib/* .drop*",

	// ====== Firmware / hardware ======
	"flashrom -w*",
	"flashrom --write*",
	"flashrom -E*",
	"flashrom --erase*",
	"fwupdmgr update*",
	"fwupdmgr install*",
	"fwupdmgr switch-branch*",
	"fwupdmgr activate*",
	"efibootmgr -B*",
	"efibootmgr -b * -B",
	"efibootmgr --delete-bootnum*",
	"efibootmgr --create-only*",

	// ====== Config overwrite ======
	"*>/etc/fstab*",
	"*>/etc/passwd*",
	"*>/etc/shadow*",
	"*>/etc/sudoers*",
	"*>/etc/hosts*",
	"*>/etc/hostname*",
	"*>/etc/resolv.conf*",
	"*>/etc/ssh/sshd_config*",
	"*>/etc/nixos/*",
	"*>/etc/systemd/*",
	"*>/etc/default/*",
	"*>/etc/modprobe.d/*",
	"*>/etc/udev/rules.d/*",
	"*>/etc/polkit-1/*",
	"*>/etc/pam.d/*",
	"*>/etc/selinux/*",
	"*>/etc/nginx/*",
	"*>/etc/NetworkManager/*",
	"*>/etc/X11/*",
	"*>/etc/environment*",
	"*>/etc/profile*",
	"*>/etc/locale.conf*",
	"*>/etc/localtime*",

	// ====== Critical symlink manipulation ======
	"ln -sf /dev/null /etc*",
	"ln -sf /dev/null ~/.ssh*",
	"ln -sf /dev/zero /dev/sda",
	"ln -sf /dev/null /var/log*",
	"ln -sf /dev/null /var/lib*",
	"mv /etc/*",
	"mv /usr/*",
	"mv /bin/*",
	"mv /var/*",
	"mv /lib/*",
	"mv /opt/*",
	"mv /boot/*",

	// ====== Fork bomb / DoS ======
	":(){ :|:& };:",
	":() { : | : & };:",
	"while true; do mkdir*; done",
	":(){ :& };:",
	"yes > /dev/null &",
	"cat /dev/random > /dev/null &",

	// ====== User communication / annoyance (security risk) ======
	"write *",
	"wall *",
	"shutdown -k*", // fake shutdown

	// ====== Log / journal destruction ======
	"journalctl --rotate --vacuum-time=1s",
	"journalctl --rotate --vacuum-size=1",
	"journalctl --flush --rotate --vacuum*",
	"rm -rf /var/log*",
	"rm -rf /var/log/journal*",
	"rm -rf /run/log*",
	"rm -rf /var/crash*",
	"rm -rf /var/spool*",
	"rm -rf /var/mail*",
	"rm -rf /var/backups*",

	// ====== NixOS specific ======
	"nixos-rebuild switch --rollback",
	"nixos-rebuild boot --rollback",
	"cp -r /etc/nixos",
	"cp -r /etc/nixos/*",
	"mv /etc/nixos*",
	"rm -rf /etc/nixos*",
	"nixos-enter*",
	"nixos-install*",
	"nixos-generate-config --force*",
]

export const allowedExtraCwds: string[] = ["/tmp"]

const forbiddenPathPatternsLower: string[] = forbiddenPathPatterns.map((p) =>
	p.toLowerCase()
)

const PATH_EXTRACTOR = /['"]?([^\s'"&|;]+)['"]?/g

const BLOCKED_LOG_DIR = resolve(homedir(), ".local", "share", "pi")
const BLOCKED_LOG_PATH = resolve(BLOCKED_LOG_DIR, "blocked-commands.log")

function logBlockedCommand(
	command: string,
	cwd: string,
	reason: string,
): void {
	try {
		mkdirSync(BLOCKED_LOG_DIR, { recursive: true })
		const timestamp = new Date().toISOString()
		const entry =
			`[${timestamp}] BLOCKED\n  command: ${command}\n  cwd: ${cwd}\n  reason: ${reason}\n\n`
		appendFileSync(BLOCKED_LOG_PATH, entry)
	} catch {
		// silently ignore logging failures
	}
}

function updateTimeoutStatus(ctx: ExtensionContext): void {
	if (autoDenyTimeoutEnabled) {
		const sec = Math.round(autoDenyTimeoutMs / 1000)
		ctx.ui.setStatus(
			"perm-timeout",
			ctx.ui.theme.fg("warning", `⏱ ${sec}s`),
		)
	} else {
		ctx.ui.setStatus("perm-timeout", undefined)
	}
}

function updateYoloStatus(ctx: ExtensionContext): void {
	ctx.ui.setStatus(
		"yolo-mode",
		yoloMode ? ctx.ui.theme.fg("error", "YOLO") : undefined,
	)
}

export default function (pi: ExtensionAPI) {
	function isSafeCwdPrefix(command: string, cwd: string): string | null {
		const match = command.match(
			/^cd\s+['"]?([^'"]+)['"]?\s*&&\s*(.+)/,
		)
		if (!match) return null

		const cdPath = match[1].trim()
		const rest = match[2]

		const targetPath = cdPath.startsWith("~")
			? resolve(homedir(), cdPath.slice(cdPath.startsWith("~/") ? 2 : 1))
			: resolve(cwd, cdPath)

		const normCwd = resolve(cwd)
		const rel = relative(normCwd, targetPath)
		const isWithinCwd = rel === "" || !rel.startsWith("..")

		if (!isWithinCwd) {
			const isExtraAllowed = allowedExtraCwds.some((allowed) => {
				const normAllowed = resolve(allowed)
				const relExtra = relative(normAllowed, targetPath)
				return relExtra === "" || !relExtra.startsWith("..")
			})
			if (!isExtraAllowed) return null
		}

		return rest
	}

	function isForbiddenPath(command: string): string | null {
		PATH_EXTRACTOR.lastIndex = 0
		let pathMatch
		while ((pathMatch = PATH_EXTRACTOR.exec(command)) !== null) {
			const path = pathMatch[1]
			if (
				path.startsWith("http://") ||
				path.startsWith("https://") ||
				path.startsWith("--") ||
				path.startsWith("-")
			) {
				continue
			}
			const lowerPath = path.toLowerCase()
			for (let i = 0; i < forbiddenPathPatternsLower.length; i++) {
				if (matchesGlob(lowerPath, forbiddenPathPatternsLower[i])) {
					return path
				}
			}
		}
		return null
	}

	function splitRespectingQuotes(
		command: string,
		delimiter: string,
	): string[] {
		const parts: string[] = []
		let current = ""
		let inSingleQuote = false
		let inDoubleQuote = false

		for (let i = 0; i < command.length; i++) {
			const char = command[i]

			if (char === "\\") {
				current += char + (command[i + 1] ?? "")
				i++
				continue
			}

			if (char === "'" && !inDoubleQuote) {
				inSingleQuote = !inSingleQuote
			} else if (char === '"' && !inSingleQuote) {
				inDoubleQuote = !inDoubleQuote
			}

			if (
				!inSingleQuote &&
				!inDoubleQuote &&
				command.startsWith(delimiter, i)
			) {
				parts.push(current.trim())
				current = ""
				i += delimiter.length - 1
				continue
			}

			current += char
		}

		parts.push(current.trim())
		return parts.filter(Boolean)
	}

	function splitChain(command: string): string[] {
		return splitRespectingQuotes(command, "&&")
	}

	function splitOr(command: string): string[] {
		return splitRespectingQuotes(command, "||")
	}

	function splitSemicolons(command: string): string[] {
		return splitRespectingQuotes(command, ";")
	}

	function splitPipes(command: string): string[] {
		const parts: string[] = []
		let current = ""
		let inSingleQuote = false
		let inDoubleQuote = false

		for (let i = 0; i < command.length; i++) {
			const char = command[i]

			if (char === "\\") {
				current += char + (command[i + 1] ?? "")
				i++
				continue
			}

			if (char === "'" && !inDoubleQuote) {
				inSingleQuote = !inSingleQuote
			} else if (char === '"' && !inSingleQuote) {
				inDoubleQuote = !inDoubleQuote
			}

			if (!inSingleQuote && !inDoubleQuote && char === "|") {
				if (command[i + 1] === "|") {
					current += "||"
					i++
				} else {
					parts.push(current.trim())
					current = ""
				}
				continue
			}

			current += char
		}

		parts.push(current.trim())
		return parts.filter(Boolean)
	}

	function stripAssignments(command: string): string {
		let str = command.trim()
		while (true) {
			const m = str.match(
				/^([A-Za-z_][A-Za-z0-9_]*)=(?:\$\([^)]*\)|`[^`]*`|'[^']*'|"[^"]*"|[^\s'"`])+\s*/,
			)
			if (!m) break
			str = str.slice(m[0].length)
		}
		return str.trim()
	}

	function splitLines(command: string): string[] {
		const parts: string[] = []
		let current = ""
		let inSingleQuote = false
		let inDoubleQuote = false
		let parenDepth = 0

		for (let i = 0; i < command.length; i++) {
			const char = command[i]

			if (char === "\\") {
				current += char + (command[i + 1] ?? "")
				i++
				continue
			}

			if (char === "'" && !inDoubleQuote) {
				inSingleQuote = !inSingleQuote
			} else if (char === '"' && !inSingleQuote) {
				inDoubleQuote = !inDoubleQuote
			} else if (!inSingleQuote && !inDoubleQuote) {
				if (char === "$" && command[i + 1] === "(") {
					parenDepth++
				} else if (char === ")" && parenDepth > 0) {
					parenDepth--
				}
			}

			if (
				!inSingleQuote &&
				!inDoubleQuote &&
				parenDepth === 0 &&
				char === "\n"
			) {
				parts.push(current.trim())
				current = ""
				continue
			}

			current += char
		}

		parts.push(current.trim())
		return parts.filter(Boolean)
	}

	function extractLoopBody(command: string): string | null {
		const trimmed = command.trim()
		if (!trimmed.startsWith("for ") && !trimmed.startsWith("while ")) {
			return null
		}
		const doMatch = trimmed.match(/;\s*do\s/)
		if (!doMatch) return null
		const doneMatch = trimmed.match(/;\s*done\s*$/)
		if (!doneMatch) return null
		const bodyStart = doMatch.index! + doMatch[0].length
		const bodyEnd = trimmed.length - doneMatch[0].length
		return trimmed.slice(bodyStart, bodyEnd).trim()
	}

	function checkCommand(
		command: string,
		cwd: string,
		singleCheck: (cmd: string) => boolean,
		mode: "every" | "some",
	): boolean {
		const safeRest = isSafeCwdPrefix(command, cwd)
		const checkCmd = safeRest !== null ? safeRest : command

		const loopBody = extractLoopBody(checkCmd)
		if (loopBody !== null) {
			return checkCommand(loopBody, cwd, singleCheck, mode)
		}

		const lineParts = splitLines(checkCmd)
		if (lineParts.length > 1) {
			return lineParts[mode]((part) =>
				checkCommand(part, cwd, singleCheck, mode)
			)
		}

		const semiParts = splitSemicolons(checkCmd)
		if (semiParts.length > 1) {
			return semiParts[mode]((part) =>
				checkCommand(part, cwd, singleCheck, mode)
			)
		}

		const chainParts = splitChain(checkCmd)
		if (chainParts.length > 1) {
			return chainParts[mode]((part) =>
				checkCommand(part, cwd, singleCheck, mode)
			)
		}

		const orParts = splitOr(checkCmd)
		if (orParts.length > 1) {
			return orParts[mode]((part) =>
				checkCommand(part, cwd, singleCheck, mode)
			)
		}

		const pipeParts = splitPipes(checkCmd)
		if (pipeParts.length > 1) {
			return pipeParts[mode]((part) =>
				checkCommand(part, cwd, singleCheck, mode)
			)
		}

		return singleCheck(checkCmd)
	}

	// Lightweight glob matcher for command strings (not file paths).
	// Unlike path.matchesGlob, * here matches anything including / and spaces.
	function matchGlob(str: string, pattern: string): boolean {
		const re = pattern
			.replace(/[.+^${}()|[\]\\]/g, "\\$&")
			.replace(/\*\*/g, "{{GLOBSTAR}}")
			.replace(/\*/g, ".*")
			.replace(/\?/g, ".")
			.replace(/{{GLOBSTAR}}/g, ".*")
		return new RegExp(`^${re}$`, "s").test(str)
	}

	// Normalize a single command for robust pattern matching:
	//   - collapse runs of whitespace to single space
	//   - strip leading path from command name (/bin/rm → rm)
	//   - strip leading "command ", "sudo ", "doas "
	//   - strip leading env var assignments (VAR=val cmd → cmd)
	//   - remove backslash escaping (\x → x for any non-newline char)
	function normalizeCommand(cmd: string): string {
		// Remove backslash escaping before non-newline chars (bash: \x → x)
		let s = cmd.replace(/\\(?!\n)/g, "")

		// Collapse whitespace
		s = s.trim().replace(/\s+/g, " ")

		// Strip leading env var assignments
		s = s.replace(
			/^([A-Za-z_][A-Za-z0-9_]*=(?:\$\([^)]*\)|`[^`]*`|'[^']*'|"[^"]*"|[^\s"'`])+\s+)+/,
			"",
		)

		// Strip leading "command "
		s = s.replace(/^command\s+/, "")

		// Strip leading privilege elevators
		s = s.replace(/^sudo\s+(--\S+\s+)*/, "")
		s = s.replace(/^doas\s+/, "")
		s = s.replace(/^pkexec\s+/, "")
		s = s.replace(/^run0\s+/, "")

		// Strip leading "time ", "nohup ", "nice ", "stdbuf ", "ionice "
		s = s.replace(/^(time|nohup|nice|stdbuf|ionice|chrt|taskset)\s+/, "")

		// Strip leading path from first word (command name)
		// e.g. /bin/rm → rm, /nix/store/xxx/bin/nix → nix
		const parts = s.split(/(\s+)/)
		if (parts.length > 0) {
			const first = parts[0]
			const slashIdx = first.lastIndexOf("/")
			if (slashIdx >= 0) {
				parts[0] = first.slice(slashIdx + 1)
				s = parts.join("")
			}
		}

		return s.trim()
	}

	// Extract inner command from shell -c / nix --command / eval wrappers.
	// Returns an array of candidate commands to check.
	function extractWrappedCommands(cmd: string): string[] {
		const candidates: string[] = [cmd]

		// sh -c "dangerous" (also bash, zsh, dash, ksh)
		let m = cmd.match(
			/^(sh|bash|zsh|dash|ksh)\s+-c\s+('([^']*)'|"((?:[^"\\]|\\.)*)"|(\S+))/,
		)
		if (m) {
			const inner = m[3] ?? m[4] ?? m[5]
			if (inner) candidates.push(inner)
		}

		// eval "dangerous"
		m = cmd.match(/^eval\s+('([^']*)'|"((?:[^"\\]|\\.)*)"|(\S+))/)
		if (m) {
			const inner = m[2] ?? m[3] ?? m[4]
			if (inner) candidates.push(inner)
		}

		// nix shell ... --command <dangerous> / nix develop ... -c <dangerous>
		m = cmd.match(
			/nix\s+(?:shell|develop|run|build|exec|profile)\s+.*?\s+(?:--command|-c)\s+(.+)/,
		)
		if (m) candidates.push(m[1])

		// nix-shell (legacy) --command <dangerous> / --run <dangerous>
		m = cmd.match(/nix-shell\s+.*?\s+(?:--command|--run)\s+(.+)/)
		if (m) candidates.push(m[1])

		// ssh user@host "dangerous" — extract the remote command
		m = cmd.match(/ssh\s+\S+@\S+\s+('([^']*)'|"((?:[^"\\]|\\.)*)"|(\S.+))/)
		if (m) {
			const inner = m[2] ?? m[3] ?? m[4]
			if (inner) candidates.push(inner)
		}

		// xargs ... <dangerous>
		m = cmd.match(/xargs\s+(-I\S+\s+)?(.+)/)
		if (m) candidates.push(m[2])

		return candidates
	}

	// Create a relaxed version of a command by replacing $() and `` substitutions
	// with dangerous-looking path tokens so patterns like "rm -rf /*" catch
	// bypasses like `rm -rf "$(echo /)"` or `rm -rf $(echo /)/etc`.
	// Also strips quotes wrapping substitutions so the path token connects cleanly.
	function relaxSubstitutions(cmd: string): string {
		let s = cmd
			// Strip quotes wrapping substitutions: "$(x)" → $(x)
			.replace(/"(\$\([^)]*\))"/g, "$1")
			.replace(/"(`[^`]*`)"/g, "$1")
		// Replace $(...) and `...` with /*/x which patterns with /* can match
		s = s
			.replace(/\$\([^)]*\)/g, "/*/x")
			.replace(/`[^`]*`/g, "/*/x")
		return s
	}

	// Check if ANY subcommand in a compound command matches a dangerous pattern.
	// Splits on pipes, chains, semicolons, and newlines, normalizes each part,
	// and unwraps shell -c / nix --command wrappers.
	function matchesAnyDangerous(cmd: string): string | null {
		// Split into individual subcommands using same logic as checkCommand
		const subcommands = [
			// First try the whole thing
			cmd,
			// Split on newlines
			...splitLines(cmd),
			// Split on semicolons
			...splitSemicolons(cmd),
			// Split on && chains
			...splitChain(cmd),
			// Split on || ors
			...splitOr(cmd),
		]

		// Collect unique parts (split pipes within each part too)
		const parts = new Set<string>()
		for (const sub of subcommands) {
			const piped = splitPipes(sub)
			for (const p of piped) {
				if (p.trim()) parts.add(p.trim())
			}
		}

		// Check each sub-part AND any wrapped/embedded commands extracted from it
		for (const part of parts) {
			for (const candidate of extractWrappedCommands(part)) {
				const norm = normalizeCommand(candidate)
				if (!norm) continue
				for (const pattern of veryDangerousCommands) {
					if (matchGlob(norm, pattern)) {
						return pattern
					}
				}
			}

			// Catch command substitution bypasses: rm -rf "$(echo /)"
			// by relaxing substitutions to * and re-checking the full command
			const relaxed = relaxSubstitutions(part)
			if (relaxed !== part) {
				const normRelaxed = normalizeCommand(relaxed)
				if (normRelaxed) {
					for (const pattern of veryDangerousCommands) {
						if (matchGlob(normRelaxed, pattern)) {
							return pattern
						}
					}
				}
			}
		}

		return null
	}
	function isAllowedSingle(command: string): boolean {
		if (allowedPatterns.some((p) => matchGlob(command, p))) return true
		const stripped = stripAssignments(command)
		if (
			stripped &&
			stripped !== command &&
			allowedPatterns.some((p) => matchGlob(stripped, p))
		) {
			return true
		}
		const subMatch = command.match(/\$\(([\s\S]*?)\)/) ||
			command.match(/`([\s\S]*?)`/)
		if (subMatch) return isAllowedSingle(subMatch[1])
		return false
	}

	function isAllowed(command: string, cwd: string): boolean {
		return checkCommand(command, cwd, isAllowedSingle, "every")
	}

	pi.registerCommand("perm-timeout", {
		description:
			"Toggle or set permission timeout auto-deny (e.g. /perm-timeout 10)",
		handler: async (args, ctx) => {
			const trimmed = args?.trim() ?? ""
			if (!trimmed) {
				// Toggle with current/default timeout
				autoDenyTimeoutEnabled = !autoDenyTimeoutEnabled
			} else if (trimmed === "off" || trimmed === "0") {
				autoDenyTimeoutEnabled = false
			} else {
				const sec = Number.parseInt(trimmed, 10)
				if (Number.isNaN(sec) || sec <= 0) {
					ctx.ui.notify(
						`Invalid timeout: "${trimmed}". Use seconds (e.g. 10) or "off"`,
						"error",
					)
					return
				}
				autoDenyTimeoutMs = sec * 1000
				autoDenyTimeoutEnabled = true
			}
			updateTimeoutStatus(ctx)
			const sec = Math.round(autoDenyTimeoutMs / 1000)
			ctx.ui.notify(
				autoDenyTimeoutEnabled
					? `Permission timeout enabled (${sec}s auto-deny)`
					: "Permission timeout disabled (wait forever)",
				"info",
			)
		},
	})

	pi.registerCommand("yolo", {
		description:
			"Toggle yolo mode — auto-approve commands not in allowlist (still blocks paths and very dangerous commands)",
		handler: async (_args, ctx) => {
			yoloMode = !yoloMode
			updateYoloStatus(ctx)
			ctx.ui.notify(
				yoloMode
					? "YOLO mode enabled — auto-approving non-allowlisted commands"
					: "YOLO mode disabled",
				yoloMode ? "warning" : "info",
			)
		},
	})

	pi.registerShortcut(Key.ctrlAlt("t"), {
		description: "Toggle permission timeout auto-deny",
		handler: async (ctx) => {
			autoDenyTimeoutEnabled = !autoDenyTimeoutEnabled
			updateTimeoutStatus(ctx)
			const sec = Math.round(autoDenyTimeoutMs / 1000)
			ctx.ui.notify(
				autoDenyTimeoutEnabled
					? `Permission timeout enabled (${sec}s auto-deny)`
					: "Permission timeout disabled (wait forever)",
				"info",
			)
		},
	})

	pi.registerShortcut(Key.ctrlAlt("y"), {
		description: "Toggle yolo mode",
		handler: async (ctx) => {
			yoloMode = !yoloMode
			updateYoloStatus(ctx)
			ctx.ui.notify(
				yoloMode
					? "YOLO mode enabled — auto-approving non-allowlisted commands"
					: "YOLO mode disabled",
				yoloMode ? "warning" : "info",
			)
		},
	})

	pi.on("session_start", async (_event, ctx) => {
		autoDenyTimeoutEnabled = true
		autoDenyTimeoutMs = 30000
		yoloMode = false
		updateTimeoutStatus(ctx)
		updateYoloStatus(ctx)
	})

	function isPathForbidden(path: string): boolean {
		const lowerPath = path.toLowerCase()
		for (const pattern of forbiddenPathPatternsLower) {
			if (matchesGlob(lowerPath, pattern)) return true
		}
		return false
	}

	pi.on("tool_call", async (event, ctx) => {
		// Block read/edit/write tools on forbidden paths (always enforced)
		if (
			event.toolName === "read" || event.toolName === "edit" ||
			event.toolName === "write"
		) {
			const path = event.input.path as string
			if (path && isPathForbidden(path)) {
				const reason = `Forbidden path: ${path}`
				logBlockedCommand(`${event.toolName} ${path}`, ctx.cwd, reason)
				return { block: true, reason }
			}
			// Path OK, allow (no further checks needed for these tools)
			return undefined
		}

		if (event.toolName !== "bash") return undefined

		const command = event.input.command as string

		// Check forbidden paths first (always enforced)
		const forbiddenPath = isForbiddenPath(command)
		if (forbiddenPath) {
			const reason = `Forbidden path: ${forbiddenPath}`
			logBlockedCommand(command, ctx.cwd, reason)
			return {
				block: true,
				reason,
			}
		}

		// Check forbidden commands with alternatives — block and tell agent what to do instead
		for (const entry of forbiddenCommandsWithAlternatives) {
			if (matchGlob(command, entry.command)) {
				const reason = `Don't use this command. ${entry.reason}`
				logBlockedCommand(command, ctx.cwd, reason)
				return { block: true, reason }
			}
		}

		// Check very dangerous commands (always enforced, even in yolo mode)
		// Uses robust splitting + normalization to catch obfuscated variants.
		const dangerousHit = matchesAnyDangerous(command)
		if (dangerousHit) {
			const reason =
				`Very dangerous command blocked: ${dangerousHit}. This is never allowed.`
			logBlockedCommand(command, ctx.cwd, reason)
			return { block: true, reason }
		}

		if (isAllowed(command, ctx.cwd)) return undefined

		// YOLO mode: auto-approve anything that passes path and command checks
		if (yoloMode) {
			ctx.ui.notify(
				`YOLO-approved: ${command.slice(0, 80)}${
					command.length > 80 ? "…" : ""
				}`,
				"warning",
			)
			return undefined
		}

		if (!ctx.hasUI) {
			const reason = "Command not in allowlist (no UI)"
			logBlockedCommand(command, ctx.cwd, reason)
			return { block: true, reason }
		}

		interface PermissionResult {
			choice: "Yes" | "No"
			message?: string
		}

		const result = await ctx.ui.custom<PermissionResult | null | "timeout">(
			(tui, theme, _kb, done) => {
				let optionIndex = 0
				let editMode = false
				let cachedLines: string[] | undefined
				const options = ["Yes", "No"]

				const editorTheme: EditorTheme = {
					borderColor: (s) => theme.fg("accent", s),
					selectList: {
						selectedPrefix: (t) => theme.fg("accent", t),
						selectedText: (t) => theme.fg("accent", t),
						description: (t) => theme.fg("muted", t),
						scrollInfo: (t) => theme.fg("dim", t),
						noMatch: (t) => theme.fg("warning", t),
					},
				}
				const editor = new Editor(tui, editorTheme)

				editor.onSubmit = () => {
					const msg = editor.getText().trim()
					done({
						choice: options[optionIndex] as "Yes" | "No",
						message: msg || undefined,
					})
				}

				function refresh() {
					cachedLines = undefined
					tui.requestRender()
				}

				function handleInput(data: string) {
					// Clear timeout while user types - restart on exit edit
					function clearTypingTimeout() {
						if (timeoutId) {
							clearTimeout(timeoutId)
							timeoutId = undefined
						}
					}
					function restartTypingTimeout() {
						if (autoDenyTimeoutEnabled && !timeoutId) {
							timeoutId = setTimeout(() => {
								done("timeout")
							}, autoDenyTimeoutMs)
						}
					}

					if (editMode) {
						clearTypingTimeout()
						if (matchesKey(data, Key.escape)) {
							editMode = false
							editor.setText("")
							refresh()
							restartTypingTimeout()
							return
						}
						editor.handleInput(data)
						refresh()
						return
					}

					if (matchesKey(data, Key.up)) {
						optionIndex = Math.max(0, optionIndex - 1)
						refresh()
						return
					}
					if (matchesKey(data, Key.down)) {
						optionIndex = Math.min(
							options.length - 1,
							optionIndex + 1,
						)
						refresh()
						return
					}
					if (matchesKey(data, Key.tab)) {
						editMode = true
						clearTypingTimeout()
						refresh()
						return
					}
					if (matchesKey(data, Key.enter)) {
						done({ choice: options[optionIndex] as "Yes" | "No" })
						return
					}
					if (matchesKey(data, Key.escape)) {
						done(null)
						return
					}
				}

				function render(width: number): string[] {
					if (cachedLines) return cachedLines

					const lines: string[] = []
					const add = (s: string) =>
						lines.push(truncateToWidth(s, width))

					add(theme.fg("accent", "─".repeat(width)))
					add(theme.fg("warning", " ⚠️  Command not in allowlist:"))
					lines.push("")
					for (const line of command.split("\n")) {
						add(`  ${theme.fg("text", line)}`)
					}
					lines.push("")
					add(theme.fg("text", " Allow?"))
					lines.push("")

					for (let i = 0; i < options.length; i++) {
						const selected = i === optionIndex
						const prefix = selected
							? theme.fg("accent", "> ")
							: "  "
						if (selected && editMode) {
							add(prefix + theme.fg("accent", `${options[i]} ✎`))
						} else if (selected) {
							add(prefix + theme.fg("accent", options[i]))
						} else {
							add(`  ${theme.fg("text", options[i])}`)
						}
					}

					if (editMode) {
						lines.push("")
						add(theme.fg("muted", " Message (optional):"))
						for (const line of editor.render(width - 2)) {
							add(` ${line}`)
						}
					}

					lines.push("")
					if (editMode) {
						add(theme.fg(
							"dim",
							" Enter to submit • Esc to go back",
						))
					} else {
						add(theme.fg(
							"dim",
							" ↑↓ navigate • Enter to confirm • Tab to add message • Esc to cancel",
						))
					}
					add(theme.fg("accent", "─".repeat(width)))

					cachedLines = lines
					return lines
				}

				let timeoutId: ReturnType<typeof setTimeout> | undefined
				if (autoDenyTimeoutEnabled) {
					timeoutId = setTimeout(() => {
						done("timeout")
					}, autoDenyTimeoutMs)
				}

				const resolve = (
					value: PermissionResult | null | "timeout",
				) => {
					if (timeoutId) {
						clearTimeout(timeoutId)
						timeoutId = undefined
					}
					done(value)
				}

				// Patch done calls inside closures to use resolve
				editor.onSubmit = () => {
					const msg = editor.getText().trim()
					resolve({
						choice: options[optionIndex] as "Yes" | "No",
						message: msg || undefined,
					})
				}

				return {
					render,
					invalidate: () => {
						cachedLines = undefined
					},
					handleInput(data: string) {
						if (editMode) {
							if (matchesKey(data, Key.escape)) {
								editMode = false
								editor.setText("")
								refresh()
								return
							}
							editor.handleInput(data)
							refresh()
							return
						}

						if (matchesKey(data, Key.up)) {
							optionIndex = Math.max(0, optionIndex - 1)
							refresh()
							return
						}
						if (matchesKey(data, Key.down)) {
							optionIndex = Math.min(
								options.length - 1,
								optionIndex + 1,
							)
							refresh()
							return
						}
						if (matchesKey(data, Key.tab)) {
							editMode = true
							refresh()
							return
						}
						if (matchesKey(data, Key.enter)) {
							resolve({
								choice: options[optionIndex] as "Yes" | "No",
							})
							return
						}
						if (matchesKey(data, Key.escape)) {
							resolve(null)
							return
						}
					},
					cleanup: () => {
						if (timeoutId) {
							clearTimeout(timeoutId)
							timeoutId = undefined
						}
					},
				}
			},
		)

		if (result === "timeout") {
			const sec = Math.round(autoDenyTimeoutMs / 1000)
			const reason =
				`Timed out after ${sec}s. You can try an alternative command`
			logBlockedCommand(command, ctx.cwd, reason)
			return { block: true, reason }
		}

		if (result === null || result === undefined) {
			logBlockedCommand(command, ctx.cwd, "Blocked by user")
			return { block: true, reason: "Blocked by user" }
		}

		if (result.choice === "Yes") {
			if (result.message) {
				ctx.ui.notify(`Approved: ${result.message}`, "info")
			}
			return undefined
		}

		// result.choice === "No"
		const reason = result.message
			? `Blocked by user: ${result.message}`
			: "Blocked by user"
		logBlockedCommand(command, ctx.cwd, reason)
		return { block: true, reason }
	})
}
