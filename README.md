# Sn0whax XBPS Repository

Unofficial third-party XBPS repository for a small selection of packages on Void Linux glibc.

> [!WARNING]
> This repository is independently maintained and is not reviewed, endorsed, signed, or distributed by the Void Linux project. Review package templates and workflow runs before installing packages.

## Available packages

- `ananicy-cpp`
- `brave-origin`
- `cachyos-settings-runit`
- `discord`
- `helium-browser`
- `heroic-games-launcher`
- `nlohmann-json`
- `spotify`
- `tutanota-desktop`

> Packages fall into three kinds. Most repackage upstream binaries (`brave-origin`, `discord`, `helium-browser`, `heroic-games-launcher`, `spotify`, `tutanota-desktop`). `cachyos-settings-runit` is a source-free configuration package that ports the [CachyOS-Settings](https://github.com/CachyOS/CachyOS-Settings) performance tuning (sysctl, udev I/O schedulers, THP, PAM limits, zram integration) to runit, with no dependency on systemd. `ananicy-cpp` and `nlohmann-json` are compiled from source by the build workflow: `ananicy-cpp` is a C++ rewrite of Ananicy for per-app nice/ioclass/sched auto-tuning (built with systemd integration disabled and shipping a runit service), and `nlohmann-json` is a header-only JSON library packaged as its build dependency. See each template and `README` under `srcpkgs/` for full details.

## Requirements

This repository targets Void Linux glibc on `x86_64`.

Confirm that the system uses glibc:

```console
ldd --version
```

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

### Notes for `ananicy-cpp`

`ananicy-cpp` is built and shipped by this repository. It requires a rules set to do anything useful:

```bash
sudo xbps-install ananicy-cpp
sudo cachyos-fetch-ananicy-rules      # helper provided by cachyos-settings-runit
sudo ln -s /etc/sv/ananicy-cpp /var/service/
sudo sv status ananicy-cpp
```

The runit service runs `ananicy-cpp start` in the foreground under supervision. The default config is installed to `/etc/ananicy-cpp/ananicy.conf`; rules live in `/etc/ananicy.d/`. `nlohmann-json` is pulled in automatically as a build dependency and does not need to be installed manually.

## Update

Packages from this repository update through XBPS with the rest of the system:

```bash
sudo xbps-install -Su
```

## Remove the repository

Remove the repository configuration:

```bash
sudo rm /etc/xbps.d/sn0whax-xbps-repo.conf
```

Removing the repository configuration does not uninstall packages that were already installed from it.

## Build and release automation

Two workflows work together:

- **`.github/workflows/update-packages.yaml`** discovers new upstream versions. It runs automatically every 6 hours (`cron: "17 */6 * * *"`, UTC) and on manual dispatch. When it finds a newer version it rewrites the affected template's `version`/`checksum`, commits the change, and triggers the build workflow. If nothing is newer, it exits without building.

- **`.github/workflows/build.yaml`** builds the current package templates, signs the resulting XBPS repository, and publishes release assets to the `latest` GitHub release. It runs on pushes to `main` touching `srcpkgs/**` and on manual dispatch. It does **not** discover new upstream versions on its own; it only builds whatever the templates currently specify. Build dependencies between templates (for example, `ananicy-cpp` requiring `nlohmann-json`) are resolved automatically by `xbps-src`.

In normal operation, packages track upstream within roughly six hours: the update workflow detects a new version, commits it, and dispatches a build that republishes the `latest` release.

> Note: `cachyos-settings-runit` and `nlohmann-json` have fixed versions that the update workflow does not auto-bump (the former is source-free; the latter is pinned to the version `ananicy-cpp` expects). `ananicy-cpp` tracks a GitLab tag. To publish changes to any of these, edit the template, increment `revision` (or `version`) in its template, and push to `main` to trigger a build.

Required repository secrets:

- `PRIVATE_PEM` - encrypted private key used to sign repository metadata and packages
- `PRIVATE_PEM_PASSPHRASE` - passphrase for the signing key

GitHub provides `GITHUB_TOKEN` automatically. The workflow requires `contents: write` permission to update release assets.

## Security

Packages may repackage upstream binaries rather than compile applications from source. Inspect each template in `srcpkgs/` for its source URL, checksum, dependencies, and installation steps.

Do not commit signing keys, passphrases, access tokens, or other secrets to this repository.

## Credits

Forked from and based on the packaging and automation work in [`noid-linux/xbps-repo`](https://github.com/noid-linux/xbps-repo).

Tuning in `cachyos-settings-runit` is derived from [CachyOS/CachyOS-Settings](https://github.com/CachyOS/CachyOS-Settings) (GPL-3.0). `ananicy-cpp` is built from [ananicy-cpp](https://gitlab.com/ananicy-cpp/ananicy-cpp) (GPL-3.0).

## License

See [`LICENSE`](LICENSE). Individual applications remain subject to their respective upstream licenses and trademark terms.
