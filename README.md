# Sn0whax XBPS Repository

Unofficial third-party [XBPS](https://docs.voidlinux.org/xbps/index.html) repository for Void Linux glibc (`x86_64`): CachyOS-optimized kernels with prebuilt signed NVIDIA modules, the NVIDIA userspace driver stack, and performance-tuning tools.

> [!WARNING]
> Independently maintained. Not reviewed, endorsed, or distributed by the Void Linux project. Review the templates in `srcpkgs/` and the workflow runs before installing.

## Packages

**Kernels (CachyOS — EEVDF + BORE, thin-LTO/Clang, 1000 Hz, THP)**
- `linux-cachyos` — baseline `x86_64`
- `linux-cachyos-v3` — optimized for the `x86_64-v3` feature level
- `linux-cachyos-nvidia-open` / `linux-cachyos-v3-nvidia-open` — prebuilt NVIDIA open kernel modules, **opt-in**, matched and signed to their kernel (see NVIDIA notes)

**NVIDIA userspace**
- `nvidia` and its components: `nvidia-libs`, `nvidia-libs-32bit`, `nvidia-opencl`, `nvidia-firmware`, `nvidia-gtklibs`

**Performance / tuning**
- `ananicy-cpp` — per-app nice/ioclass/sched auto-tuning (built from source, runit service)
- `cachyos-settings-runit` — CachyOS sysctl/udev/THP/zram tuning ported to runit (systemd-free)
- `nlohmann-json` — header-only JSON lib (build dep of `ananicy-cpp`)

**Applications** (repackaged upstream binaries)
- `brave-origin`, `discord`, `faugus-launcher`, `helium-browser`, `heroic-games-launcher`, `spotify`, `tutanota-desktop`, `unimatrix`. `mocp`

> Kernels, the NVIDIA driver, `ananicy-cpp`, and `nlohmann-json` are compiled from source by CI. `cachyos-settings-runit` is config-only. The rest repackage upstream binaries. See each `srcpkgs/*/template` for source URLs, checksums, and dependencies.

## Requirements

Void Linux glibc on `x86_64`. Confirm glibc:

```bash
ldd --version
```

The `-v3` kernel needs an `x86_64-v3`-capable CPU (roughly Intel Haswell / AMD Excavator and newer):

```bash
/lib/ld-linux-x86-64.so.2 --help | grep x86-64-v3
```

If `x86-64-v3 (supported, searched)` appears, `-v3` is safe; otherwise use `linux-cachyos`.

## Add the repository

```bash
echo 'repository=https://github.com/Sn0whax/xbps-repo/releases/latest/download' | sudo tee /etc/xbps.d/sn0whax-xbps-repo.conf
sudo xbps-install -S
```

On first use XBPS asks to import this repo's signing key — verify the fingerprint before accepting.

## Install & configure

### CachyOS kernels

```bash
sudo xbps-install linux-cachyos        # or linux-cachyos-v3
```

Headers are integrated (no separate `-headers` package).

**Secure Boot:** if the host has a kernel-signing hook (e.g. `sbsigntool` in `/etc/kernel.d/post-install/`), the installed `vmlinuz` is signed on install with your enrolled DB/MOK key. Verify before rebooting — your previous kernel stays in GRUB as a fallback:

```bash
sudo sbverify --list /boot/vmlinuz-$(uname -r)   # want: "image signature verifies"
```

### NVIDIA (prebuilt open modules — no DKMS)

The `nvidia-open` kernel module is built **in CI against the exact kernel** and **signed with that kernel's own module-signing key** (sha512/ECDSA) — so it works under Secure Boot module enforcement with no local compile and no DKMS. It is a separate **opt-in** package, strictly pinned to its kernel version; installing a kernel does **not** pull it automatically.

> Requires a **Turing (RTX 20-series) or newer** GPU. Older GPUs are not supported by the open module.

```bash
# baseline kernel + open module + userspace driver
sudo xbps-install linux-cachyos linux-cachyos-nvidia-open \
    nvidia-libs nvidia-libs-32bit nvidia-opencl nvidia-gtklibs
```

Use `linux-cachyos-v3-nvidia-open` with the `-v3` kernel. Because the module is version-locked to its kernel, both update together via `xbps-install -Su`.

### `cachyos-settings-runit`

Config only — nothing is enabled automatically:

```bash
sudo xbps-reconfigure -f cachyos-settings-runit   # apply sysctl/udev now (or reboot)
sudo ln -s /etc/sv/cachyos-boot-tune /var/service/   # THP tuning
sudo ln -s /etc/sv/zramen            /var/service/   # zram swap
```

Verify: `cat /sys/kernel/mm/transparent_hugepage/enabled`, `zramctl`, `sysctl vm.swappiness`.

### `ananicy-cpp`

Needs a rules set to do anything:

```bash
sudo xbps-install ananicy-cpp
sudo cachyos-fetch-ananicy-rules              # helper from cachyos-settings-runit
sudo ln -s /etc/sv/ananicy-cpp /var/service/
```

Config: `/etc/ananicy-cpp/ananicy.conf`; rules: `/etc/ananicy.d/`. `nlohmann-json` comes in automatically as a build dep. Confirm it's tuning (launch a browser/game first):

```bash
ps -eo pid,ni,cls,comm --sort=ni | awk '$4 !~ /kworker|ksoftirq|migration|rcu_/ && $2!=0' | head
```

### `faugus-launcher`

GTK4 front-end for Windows games via UMU/Proton. Python deps come from Void's repos automatically; `umu-launcher` isn't required (Faugus manages Proton at runtime):

```bash
sudo xbps-install faugus-launcher
```

## Update

```bash
sudo xbps-install -Su
```

CI builds and publishes ahead of time; nothing is auto-installed or auto-rebooted — updates land only when you run `-Su`. New kernels are Secure Boot–signed on install by the host hook.

## Remove the repository

```bash
sudo rm /etc/xbps.d/sn0whax-xbps-repo.conf
```

This does not uninstall already-installed packages.

## Build automation

- **`update-packages.yaml`** (every 6 h) — detects new upstream versions for apps + `ananicy-cpp`/`faugus-launcher`, bumps templates, triggers a build.
- **`update-packages-kernel.yaml`** (daily) — same for kernels, `nlohmann-json`, and `nvidia`; keeps the `nvidia-open` module version in lockstep with the driver.
- **`build.yaml`** — parallel matrix build (kernels, NVIDIA, apps on separate runners), then a single job signs the full repo and publishes to the `latest` release. Built archives are uploaded exactly as indexed and signed, so the served `.xbps`, its `.sig2`, and the repodata always agree.

Signing uses the `PRIVATE_PEM` / `PRIVATE_PEM_PASSPHRASE` repository secrets. Never commit keys, passphrases, or tokens.

## Credits

Forked from [`noid-linux/xbps-repo`](https://github.com/noid-linux/xbps-repo). Kernel and tuning work derive from [CachyOS/linux-cachyos](https://github.com/CachyOS/linux-cachyos) and [CachyOS/CachyOS-Settings](https://github.com/CachyOS/CachyOS-Settings) (GPL-3.0); `ananicy-cpp` from [ananicy-cpp](https://gitlab.com/ananicy-cpp/ananicy-cpp) (GPL-3.0); `faugus-launcher` from [Faugus/faugus-launcher](https://github.com/Faugus/faugus-launcher) (MIT). The NVIDIA driver is subject to NVIDIA's proprietary license.

## License

See [`LICENSE`](LICENSE). Individual applications remain subject to their upstream licenses and trademark terms.
