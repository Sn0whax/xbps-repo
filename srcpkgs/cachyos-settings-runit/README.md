# cachyos-settings-runit

A **systemd-free port of [CachyOS-Settings](https://github.com/CachyOS/CachyOS-Settings)** for runit-based Void Linux. Packaged as an xbps-src template for [`Sn0whax/xbps-repo`](https://github.com/Sn0whax/xbps-repo).

It delivers the "feels-like-CachyOS" tuning layer — sysctl, udev, THP, PAM limits, and zram integration — **without** pulling in `systemd`, `zram-generator`, or `power-profiles-daemon`.

> **Scope:** This packages the *settings/tuning* layer only. The optimized v3 userland repos and the `linux-cachyos` kernel are separate concerns (the kernel is buildable via a community xbps-src template).

---

## What it installs

| File (in package) | Installed to | Purpose |
|---|---|---|
| `70-cachyos-settings.conf` | `/usr/lib/sysctl.d/` | Memory/IO/network kernel tunables |
| `60-cachyos-io.rules` | `/usr/lib/udev/rules.d/` | Per-device I/O scheduler assignment |
| `61-cachyos-misc.rules` | `/usr/lib/udev/rules.d/` | SATA/hdparm/rtc/zram/NVIDIA rules |
| `cachyos-nvidia.conf` | `/usr/lib/modprobe.d/` | NVIDIA module options (auto-relevant only if present) |
| `20-cachyos-audio.conf` | `/etc/security/limits.d/` | Audio-group rtprio/nice/memlock |
| `cachyos-boot-tune/run` | `/etc/sv/cachyos-boot-tune/` | runit one-shot: THP tuning at boot |
| `fetch-ananicy-rules.sh` | `/usr/bin/cachyos-fetch-ananicy-rules` | Helper to pull CachyOS ananicy rules |

**Hard dependencies:** `zramen`, `hdparm` (both in Void's official repos).

---

## Tuning details

### sysctl — `70-cachyos-settings.conf`

| Key | Value | Rationale |
|---|---|---|
| `vm.swappiness` | `100` | Favor compressed zram swap over dropping page cache |
| `vm.vfs_cache_pressure` | `50` | Keep FS metadata (inode/dentry) hot longer |
| `vm.dirty_bytes` | `268435456` | Bound writeback by absolute bytes (better latency) |
| `vm.dirty_background_bytes` | `67108864` | Start background writeback earlier |
| `vm.dirty_writeback_centisecs` | `1500` | Writeback interval |
| `vm.page-cluster` | `0` | 1-page swap readahead — ideal for zram |
| `kernel.nmi_watchdog` | `0` | Drop per-CPU watchdog overhead |
| `kernel.split_lock_mitigate` | `0` | Don't stall on split-lock (some games trigger it) |
| `kernel.unprivileged_userns_clone` | `1` | Needed by Steam/Flatpak/browser sandboxes |
| `kernel.kptr_restrict` | `2` | Hide kernel pointers from unprivileged users |
| `kernel.printk` | `3 3 3 3` | Quiet console (dmesg still intact) |
| `net.core.netdev_max_backlog` | `4096` | Deeper NIC backlog for high-throughput links |
| `fs.file-max` | `2097152` | Raise global open-file ceiling |
| `vm.max_map_count` | `1048576` | Required by many Proton/native games |
| `fs.inotify.max_user_instances` | `1024` | inotify headroom for large game libraries |
| `fs.inotify.max_user_watches` | `524288` | inotify headroom |
| `net.ipv4.tcp_keepalive_time` | `120` | Faster dead-connection detection |

### I/O schedulers — `60-cachyos-io.rules`

| Device class | Scheduler |
|---|---|
| Rotational HDD (`sd*`, `mmcblk*`) | `bfq` |
| SATA/eMMC SSD (non-rotational) | `mq-deadline` |
| NVMe SSD (`nvme*n*`) | 'adios' else `kyber` |

### Misc device tuning — `61-cachyos-misc.rules`

- **SATA link power management** → `max_performance` (desktop bias)
- **hdparm** `-B 254 -S 0` on rotational ATA disks (no head-park / no spindown)
- **rtc0 / hpet** → group `audio` (low-latency audio access)
- **cpu_dma_latency** → group `audio`, mode `0660` (PM-QoS access)
- **zram activation** → bumps `vm.swappiness` to `150`
- **NVIDIA bind/unbind** → toggles runtime power management (RTD3)

### PAM limits — `20-cachyos-audio.conf`

```
@audio  -  rtprio   99
@audio  -  nice     -20
@audio  -  memlock  unlimited
```
Enables low-latency PipeWire/JACK; mirrors CachyOS's rtkit rtprio 99 default.

### Transparent Hugepages — `cachyos-boot-tune` runit service

- `enabled` → `always`
- `defrag` → `defer+madvise`
- `khugepaged/max_ptes_none` → `409`

(THP lives in a boot service because it can't be set via `sysctl.d`.)

### NVIDIA — `cachyos-nvidia.conf`

- `NVreg_PreserveVideoMemoryAllocations=1` (fixes black-screen-on-resume)
- `NVreg_DynamicPowerManagement=0x02` (RTD3 runtime PM)
- `nvidia_drm modeset=1 fbdev=1` (Wayland-friendly framebuffer)

---

## Installation

```sh
sudo xbps-install -S cachyos-settings-runit
```

Apply immediately (or just reboot):

```sh
sudo xbps-reconfigure -f cachyos-settings-runit
sudo sysctl --system
sudo udevadm control --reload && sudo udevadm trigger
```

Enable services:

```sh
sudo ln -s /etc/sv/cachyos-boot-tune /var/service/    # THP tuning
sudo ln -s /etc/sv/zramen            /var/service/    # compressed swap
```

Verify:

```sh
sysctl vm.swappiness vm.max_map_count net.ipv4.tcp_keepalive_time
cat /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/block/nvme0n1/queue/scheduler   # adjust device
ulimit -r
zramctl
```

---

## Optional: ananicy-cpp (per-app nice/io tuning)

**Not required and not a dependency.** All tuning above works without it.
`ananicy-cpp` is **not** in Void's official repos, so it must be built from a
community template first:

1. Build `ananicy-cpp` (see
   [`prostitutionofthesoul/ananicy-cpp-void-template`](https://github.com/prostitutionofthesoul/ananicy-cpp-void-template)).
2. Fetch the CachyOS rule set:
   ```sh
   sudo cachyos-fetch-ananicy-rules
   ```
3. Enable the daemon (service action is `start`, not `run`):
   ```sh
   sudo ln -s /etc/sv/ananicy-cpp /var/service/
   sudo sv restart ananicy-cpp
   ```

---

## Modifications & divergence from upstream CachyOS-Settings

### Design changes (systemd → runit)

| Upstream mechanism | This port |
|---|---|
| `zram-generator` (systemd) | Replaced with **`zramen`** dependency |
| systemd-set sysctl (`max_map_count`, `tcp_keepalive_time`, inotify) | Folded into the plain `sysctl.d` file |
| systemd THP oneshot | Replaced with **runit one-shot service** |
| `power-profiles-daemon` / `game-performance` | **Dropped** (systemd/ppd-bound) |
| Package-managed ananicy rules | **Runtime fetch script** (rolling repo has no stable checksum) |

### Deliberately omitted (desktop-focused)

- `snd-hda-intel` AC/battery audio power toggle (laptop anti-crackle)
- Wi-Fi regulatory-domain trigger (region-specific)

### Packaging fix history

- **`depends` corrected:** `ananicy-cpp` was **removed** from `depends`.
  It is not in Void's repos, so hard-depending on it made the package
  **unbuildable** (`target dependency 'ananicy-cpp' does not exist`) and would
  have made it uninstallable. It is now an optional, separately-installed
  component. Current: `depends="zramen hdparm"`.

---

## Notes & tradeoffs

- `split_lock_mitigate=0` and (if you add it to the kernel cmdline)
  `mitigations=off` are **performance-vs-security** trades — fine on a gaming
  box, your call elsewhere.
- SATA `max_performance` costs idle power — comment it out on a laptop.
- THP `always` can slightly raise RAM use; `madvise` is the conservative
  alternative.
- Services are **not** auto-enabled — this is standard Void behavior; enable
  via the `ln -s … /var/service/` symlinks above.

## Credits

- Tuning derived from [CachyOS/CachyOS-Settings](https://github.com/CachyOS/CachyOS-Settings) (GPL-3.0)
- ananicy rules from [CachyOS/ananicy-rules](https://github.com/CachyOS/ananicy-rules) (GPL-3.0)

## License

GPL-3.0-or-later
