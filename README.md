# Sn0whax XBPS Repository

Unofficial third-party XBPS repository for a small selection of packages on Void Linux glibc, including CachyOS-optimized kernels, the NVIDIA proprietary driver stack, and performance-tuning tooling.

> [!WARNING]
> This repository is independently maintained and is not reviewed, endorsed, signed, or distributed by the Void Linux project. Review package templates and workflow runs before installing packages.

## Available packages

**Kernels (CachyOS)**

- `linux-cachyos` — CachyOS kernel (BORE scheduler, LRU_GEN, thin LTO), baseline `x86_64`
- `linux-cachyos-v3` — same kernel built for the `x86_64-v3` microarchitecture level

**Graphics (NVIDIA proprietary)**

- `nvidia` — NVIDIA proprietary driver (production branch)
- `nvidia-dkms`, `nvidia-firmware`, `nvidia-libs`, `nvidia-libs-32bit`, `nvidia-opencl`, `nvidia-gtklibs` — supporting driver components

**Performance / tuning**

- `ananicy-cpp` — per-app nice/ioclass/sched auto-tuning (built from source, runit service)
- `cachyos-settings-runit` — CachyOS performance tuning ported to runit
- `nlohmann-json` — header-only JSON library (build dependency of `ananicy-cpp`)

**Applications (repackaged upstream binaries)**

- `brave-origin`
- `discord`
- `faugus-launcher`
- `helium-browser`
- `heroic-games-launcher`
- `spotify`
- `tutanota-desktop`

> Packages fall into a few kinds. Most applications repackage upstream binaries (`brave-origin`, `discord`, `faugus-launcher`, `helium-browser`, `heroic-games-launcher`, `spotify`, `tutanota-desktop`). `cachyos-settings-runit` is a source-free configuration package that ports the [CachyOS-Settings](https://github.com/CachyOS/CachyOS-Settings) performance tuning (sysctl, udev I/O schedulers, THP, PAM limits, zram integration) to runit, with no dependency on systemd. `ananicy-cpp` and `nlohmann-json` are compiled from source by the build workflow: `ananicy-cpp` is a C++ rewrite of Ananicy for per-app nice/ioclass/sched auto-tuning (built with systemd integration disabled and shipping a runit service), and `nlohmann-json` is a header-only JSON library packaged as its build dependency. The `linux-cachyos` kernels and the `nvidia` driver set are also built from source by the workflow. See each template and `README` under `srcpkgs/` for full details.

## Requirements

This repository targets Void Linux glibc on `x86_64`.

Confirm that the system uses glibc:

```console
ldd --version
```

The `linux-cachyos-v3` variant additionally requires a CPU that supports the `x86_64-v3` feature level (roughly Intel Haswell / AMD Excavator and newer). Check compatibility with:

```console
/lib/ld-linux-x86-64.so.2 --help | grep -A1 x86-64-v3
```

If `x86-64-v3 (supported, searched)` appears, the v3 kernel is safe to run; otherwise install the baseline `linux-cachyos`.

## Add the repository

Create an XBPS repository configuration file:

```bash
echo 'repository=https://github.com/Sn0whax/xbps-repo/releases/latest/download' | sudo tee /etc/xbps.d/sn0whax-xbps-repo.conf
```

Refresh repository metadata:

```bash
sudo xbps-install -S
```

On first use, XBPS may ask whether to import and trust this repository's signing key. Verify the displayed fingerprint before accepting it.

## Install packages

Install one package:

```bash
sudo xbps-install brave-origin
```

### Notes for the CachyOS kernels

Install the baseline kernel:

```bash
sudo xbps-install linux-cachyos
```

…or the `x86_64-v3`-optimized build (see the CPU check above):

```bash
sudo xbps-install linux-cachyos-v3
```

The kernels ship with headers integrated (no separate `-headers` package) and are built with the CachyOS configuration: BORE scheduler, `CONFIG_CACHY`, 1000 Hz tick, thin LTO (Clang), and transparent hugepages. DKMS modules such as `nvidia-dkms` build against them automatically.

**Secure Boot:** if the host uses an existing kernel-signing hook (for example `sbsigntool` under `/etc/kernel.d/post-install/`), the installed `vmlinuz` is signed automatically on install with the machine's enrolled DB/MOK key, exactly like Void's stock kernels. Confirm before rebooting:

```bash
sudo sbverify --list /boot/vmlinuz-$(uname -r)
```

A `signature 1 … image signature verifies` line means the kernel is signed for Secure Boot. Your previous kernel remains in the GRUB menu as a fallback in case a new kernel is ever rejected.

### Notes for `cachyos-settings-runit`

This package installs configuration only; nothing is enabled automatically. After installing, apply the tuning and enable the services you want:

```bash
# Apply sysctl/udev now (or just reboot)
sudo xbps-reconfigure -f cachyos-settings-runit
sudo sysctl --system
sudo udevadm control --reload && sudo udevadm trigger

# Enable runit services
sudo ln -s /etc/sv/cachyos-boot-tune /var/service/   # THP tuning at boot
sudo ln -s /etc/sv/zramen            /var/service/   # compressed zram swap
```

Verify:

```bash
cat /sys/kernel/mm/transparent_hugepage/enabled   # THP mode
zramctl                                            # zram swap device
sysctl vm.swappiness vm.max_map_count              # tuned values
```

### Notes for `ananicy-cpp`

`ananicy-cpp` is built and shipped by this repository. It requires a rules set to do anything useful:

```bash
sudo xbps-install ananicy-cpp
sudo cachyos-fetch-ananicy-rules      # helper provided by cachyos-settings-runit
sudo ln -s /etc/sv/ananicy-cpp /var/service/
sudo sv status ananicy-cpp
```

The runit service runs `ananicy-cpp start` in the foreground under supervision. The default config is installed to `/etc/ananicy-cpp/ananicy.conf`; rules live in `/etc/ananicy.d/` (the CachyOS rule set installs ~360 `.rules` files under `/etc/ananicy.d/00-default/`). `nlohmann-json` is pulled in automatically as a build dependency and does not need to be installed manually.

Confirm it is actually tuning userspace processes (launch a browser or game first):

```bash
ps -eo pid,ni,cls,comm --sort=ni | awk '$4 !~ /kworker|ksoftirq|migration|rcu_/ && $2!=0' | head
```

Non-zero `NI` values on real applications indicate the rules are firing.

### Notes for `faugus-launcher`

A GTK4 front-end for running Windows games via UMU-Launcher (Proton). It is a Python application repackaged from the upstream Debian `.deb`; all Python and GObject-introspection dependencies are pulled from Void's official repositories automatically:

```bash
sudo xbps-install faugus-launcher
```

`umu-launcher` is not a hard dependency — Faugus downloads and manages Proton/UMU at runtime through its built-in Proton Manager.

### Notes for `nvidia`

The proprietary NVIDIA driver and its components are built by the workflow. A typical install pairs the driver with a CachyOS kernel:

```bash
sudo xbps-install linux-cachyos nvidia nvidia-libs nvidia-libs-32bit nvidia-opencl nvidia-gtklibs
```

`nvidia-dkms` rebuilds the kernel module against installed kernels automatically.

## Update

Packages from this repository update through XBPS with the rest of the system:

```bash
sudo xbps-install -Su
```

Newly published kernels are Secure Boot–signed on install by the host's kernel hook (see the kernel notes above). Nothing is auto-installed or auto-rebooted: the automation only builds and publishes ahead of time, and updates land on the machine only when you run `-Su`.

## Remove the repository

Remove the repository configuration:

```bash
sudo rm /etc/xbps.d/sn0whax-xbps-repo.conf
```

Removing the repository configuration does not uninstall packages that were already installed from it.

## Build and release automation

Three workflows work together:

- **`.github/workflows/update-packages.yaml`** — the **6-hour** updater. Runs on `cron: "17 */6 * * *"` (UTC) and on manual dispatch. It discovers new upstream versions for the fast-moving packages (`brave-origin`, `discord`, `helium-browser`, `heroic-games-launcher`, `spotify`, `tutanota-desktop`, `ananicy-cpp`, `faugus-launcher`), rewrites the affected template's `version`/`checksum`, commits, and triggers a build. If nothing is newer, it exits without building.

- **`.github/workflows/update-packages-kernel.yaml`** — the **24-hour** updater for heavy, compile-from-source packages. Runs on `cron: "23 4 * * *"` (UTC) and on manual dispatch. It detects new versions of `linux-cachyos`, `linux-cachyos-v3`, `nlohmann-json`, and `nvidia`; for each, it reconstructs the source URL from the template, fetches the tarball, recomputes the `sha256` checksum, bumps `version`/`revision`/`checksum`, commits, and triggers a build. Kernel and driver builds are separated onto a daily cadence because each run compiles two full kernels plus the NVIDIA modules and takes considerably longer than the application updates.

- **`.github/workflows/build.yaml`** — builds the current package templates, signs the resulting XBPS repository and packages, and publishes release assets to the `latest` GitHub release. It runs on pushes to `main` touching `srcpkgs/**` and on manual dispatch. It does **not** discover new upstream versions on its own; it only builds whatever the templates currently specify. Build dependencies between templates (for example, `ananicy-cpp` requiring `nlohmann-json`) are resolved automatically by `xbps-src`.

In normal operation, applications track upstream within roughly six hours and kernels/drivers within about a day: an update workflow detects a new version, commits it, and dispatches a build that republishes the `latest` release.

### Build pipeline correctness

The `build.yaml` release step uploads the **exact** package archives that were indexed and signed (`~/packages/*.xbps` together with their `.sig2` signatures and the generated `x86_64-repodata`). This guarantees that, for every package, the served `.xbps`, its `.sig2` signature, and the recorded `repodata` hash all describe the same archive. Uploading a pre-index copy of a package instead would produce an RSA signature mismatch at install time.

The masterdir setup does **not** add this repository as a remote build source. Building is self-contained against Void's official repositories, which avoids an interactive "import public key?" prompt that would otherwise block a non-interactive CI run.

> Note: `cachyos-settings-runit` has a fixed version that the update workflows do not auto-bump (it is source-free). `nlohmann-json` is bumped by the 24-hour workflow but is normally held at the version `ananicy-cpp` expects. To publish changes to any package manually, edit the template, increment `revision` (or `version`), and push to `main` to trigger a build.

Required repository secrets:

- `PRIVATE_PEM` — encrypted private key used to sign repository metadata and packages
- `PRIVATE_PEM_PASSPHRASE` — passphrase for the signing key

GitHub provides `GITHUB_TOKEN` automatically. The workflow requires `contents: write` permission to update release assets.

## Troubleshooting

**`the RSA signature is not valid!` on install.** The served package archive does not match its signature/repodata. This is a publishing desync, not a corrupt download. The fix is to rebuild the affected package so its archive, `.sig2`, and repodata are regenerated together — bump the template's `revision` and push to `main`, then re-run `sudo xbps-install -S`. The build pipeline uploads indexed-and-signed archives specifically to prevent this.

**A build hangs for a long time on "Build and check packages".** In CI this is usually an interactive prompt with no TTY (for example importing an untrusted repository key). Builds here are kept self-contained against Void's official repositories to avoid it.

## Security

Packages may repackage upstream binaries rather than compile applications from source. Inspect each template in `srcpkgs/` for its source URL, checksum, dependencies, and installation steps.

Do not commit signing keys, passphrases, access tokens, or other secrets to this repository.

## Credits

Forked from and based on the packaging and automation work in [`noid-linux/xbps-repo`](https://github.com/noid-linux/xbps-repo).

Kernel configuration and tuning are derived from [CachyOS/linux-cachyos](https://github.com/CachyOS/linux-cachyos) and [CachyOS/CachyOS-Settings](https://github.com/CachyOS/CachyOS-Settings) (GPL-3.0). `ananicy-cpp` is built from [ananicy-cpp](https://gitlab.com/ananicy-cpp/ananicy-cpp) (GPL-3.0). `faugus-launcher` is repackaged from [Faugus/faugus-launcher](https://github.com/Faugus/faugus-launcher) (MIT). The NVIDIA driver remains subject to NVIDIA's proprietary license.

## License

See [`LICENSE`](LICENSE). Individual applications remain subject to their respective upstream licenses and trademark terms.
