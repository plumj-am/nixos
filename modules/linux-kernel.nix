{ self, ... }:
{
  flake.nixosModules.default = self.nixosModules.linux-kernel;
  flake.nixosModules.linux-kernel = {
    security.lockKernelModules = true;

    # Credits from me:
    # - https://github.com/RGBCube/ncc/blob/c5714110d951f57e66d5ee47a244c0a93f3406a1/modules/linux/kernel.nix
    # From RGBCube:
    # - https://github.com/NotAShelf/nyx/blob/main/modules/core/common/system/security/kernel.nix
    # - "hsslister" user - raf (NotAShelf) - "I actually forgot the dudes GitHub"
    boot.kernel.sysctl = {
      # The Magic SysRq key is a key combo that allows users connected to the
      # system console of a Linux kernel to perform some low-level commands.
      # Disable it, since we don't need it, and is a potential security concern.
      "kernel.sysrq" = 0;

      # Hide kptrs even for processes with CAP_SYSLOG.
      # Also prevents printing kernel pointers.
      "kernel.kptr_restrict" = 2;

      # Disable bpf() JIT (to eliminate spray attacks).
      "net.core.bpf_jit_enable" = false;

      # Avoid kernel memory address exposures via dmesg (this value can also be set by CONFIG_SECURITY_DMESG_RESTRICT).
      "kernel.dmesg_restrict" = 1;

      # Prevent unintentional fifo writes.
      "fs.protected_fifos" = 2;

      # Prevent unintended writes to already-created files.
      "fs.protected_regular" = 2;

      # Disable SUID binary dump.
      "fs.suid_dumpable" = 0;

      # Disallow profiling at all levels without CAP_SYS_ADMIN.
      "kernel.perf_event_paranoid" = 3;

      # Require CAP_BPF to use bpf.
      "kernel.unprivileged_bpf_disabled" = 1;

      # From plumjam: Prevent "inotify watch limit reached".
      "fs.inotify.max_user_watches" = 524288;
      "fs.inotify.max_user_instances" = 524288;
      "fs.inotify.max_queued_events" = 524288;
    };

    # https://www.kernel.org/doc/html/latest/admin-guide/kernel-parameters.html
    boot.kernelParams = [
      # Make stack-based attacks on the kernel harder.
      "randomize_kstack_offset=on"

      # Controls the behavior of vsyscalls. This has been defaulted to none back in 2016 - break really old binaries for security.
      "vsyscall=none"

      # Reduce most of the exposure of a heap attack to a single cache.
      "slab_nomerge"

      # Kernel module signature enforcement and integrity/confidentiality
      # lockdown are deliberately absent. nixpkgs builds the `linux-zen` >= 7.3
      # modules in a separate derivation (`linux-zen-*-modules.drv`) whose kbuild
      # auto-generates its own signing key (the kernel config pins
      # `CONFIG_MODULE_SIG_KEY=""`), so module signatures never verify against
      # the key embedded in the booted bzImage. With `module.sig_enforce=1` or
      # `lockdown=confidentiality` every module load is then rejected, the initrd
      # cannot load nvme/ext4, root never mounts and the machine drops into the
      # emergency shell (emergency, then systemd-boot's boot counting marks the
      # generation bad and falls back to an older one). Verified 2026-11-25 by
      # booting the 27.05 initrd in QEMU with and without each parameter: only
      # with both off does `systemd-modules-load` succeed. Restore both once
      # modules are signed with the kernel's key again.

      # Enable buddy allocator free poisoning.
      "page_poison=1"

      # Performance improvement for direct-mapped memory-side-cache utilization, reduces the predictability of page allocations.
      "page_alloc.shuffle=1"

      # Disable sysrq keys. sysrq is seful for debugging, but also insecure.
      "sysrq_always_enabled=0"

      # Ignore access time (atime) updates on files, except when they coincide with updates to the ctime or mtime.
      "rootflags=noatime"

      # Linux security modules. This list is inert: nixpkgs' `security.lsm`
      # option emits its own `lsm=` later in the command line and the kernel
      # honours the last one (`/sys/kernel/security/lsm` shows
      # capability,landlock,yama,bpf,ima). When lockdown is re-enabled, add
      # `lockdown` to `security.lsm` instead of relying on this string.
      "lsm=landlock,lockdown,yama,integrity,apparmor,bpf,tomoyo,selinux"

      # Prevent the kernel from blanking plymouth out of the fb.
      "fbcon=nodefer"
    ];

    boot.blacklistedKernelModules = [
      # Obscure network protocols.
      "af_802154" # IEEE 802.15.4
      "appletalk" # Appletalk
      "atm" # ATM
      "ax25" # Amatuer X.25
      "can" # Controller Area Network
      "dccp" # Datagram Congestion Control Protocol
      "decnet" # DECnet
      "econet" # Econet
      "ipx" # Internetwork Packet Exchange
      "n-hdlc" # High-level Data Link Control
      "netrom" # NetRom
      "p8022" # IEEE 802.3
      "p8023" # Novell raw IEEE 802.3
      "psnap" # SubnetworkAccess Protocol
      "rds" # Reliable Datagram Sockets
      "rose" # ROSE
      "sctp" # Stream Control Transmission Protocol
      "tipc" # Transparent Inter-Process Communication
      "x25" # X.25

      # Old or rare or insufficiently audited filesystems.
      "adfs" # Active Directory Federation Services
      "affs" # Amiga Fast File System
      "befs" # "Be File System"
      "bfs" # BFS, used by SCO UnixWare OS for the /stand slice
      "cifs" # Common Internet File System
      "cramfs" # compressed ROM/RAM file system
      "efs" # Extent File System
      "erofs" # Enhanced Read-Only File System
      "exofs" # EXtended Object File System
      "f2fs" # Flash-Friendly File System
      "freevxfs" # Veritas filesystem driver
      "gfs2" # Global File System 2
      "hfs" # Hierarchical File System (Macintosh)
      "hfsplus" # Same as above, but with extended attributes.
      "hpfs" # High Performance File System (used by OS/2)
      "jffs2" # Journalling Flash File System (v2)
      "jfs" # Journaled File System - only useful for VMWare sessions
      "ksmbd" # SMB3 Kernel Server
      "minix" # minix fs - used by the minix OS
      "nfs" # Network File System
      "nfsv3" # Network File System (v3)
      "nfsv4" # Network File System (v4)
      "nilfs2" # New Implementation of a Log-structured File System
      "omfs" # Optimized MPEG Filesystem
      "qnx4" # Extent-based file system used by the QNX4 OS.
      "qnx6" # Extent-based file system used by the QNX6 OS.
      "squashfs" # compressed read-only file system (used by live CDs)
      "sysv" # implements all of Xenix FS, SystemV/386 FS and Coherent FS.
      "udf" # https://docs.kernel.org/5.15/filesystems/udf.html
      "vivid" # Virtual Video Test Driver (unnecessary)

      # Disable Thunderbolt and FireWire to prevent DMA attacks
      "firewire-core"
      "thunderbolt"
    ];

  };
}
