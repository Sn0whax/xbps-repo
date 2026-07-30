# Sn0whax XBPS Repository

Unofficial third-party XBPS repository for a small selection of packages on Void Linux glibc.

> [!WARNING]
> This repository is independently maintained and is not reviewed, endorsed, signed, or distributed by the Void Linux project. Review package templates and workflow runs before installing packages.

## Available packages

- `brave-origin`
- `discord`
- `helium-browser`
- `heroic-games-launcher`
- `spotify`
- `tutanota-desktop`

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

Install all packages provided by this repository:

```bash
```

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

- **`.github/workflows/build.yaml`** builds the current package templates, signs the resulting XBPS repository, and publishes release assets to the `latest` GitHub release. It runs on pushes to `main` touching `srcpkgs/**` and on manual dispatch. It does **not** discover new upstream versions on its own; it only builds whatever the templates currently specify.

In normal operation, packages track upstream within roughly six hours: the update workflow detects a new version, commits it, and dispatches a build that republishes the `latest` release.

Required repository secrets:

- `PRIVATE_PEM` - encrypted private key used to sign repository metadata and packages
- `PRIVATE_PEM_PASSPHRASE` - passphrase for the signing key

GitHub provides `GITHUB_TOKEN` automatically. The workflow requires `contents: write` permission to update release assets.

## Security

Packages may repackage upstream binaries rather than compile applications from source. Inspect each template in `srcpkgs/` for its source URL, checksum, dependencies, and installation steps.

Do not commit signing keys, passphrases, access tokens, or other secrets to this repository.

## Credits

Forked from and based on the packaging and automation work in [`noid-linux/xbps-repo`](https://github.com/noid-linux/xbps-repo).

## License

See [`LICENSE`](LICENSE). Individual applications remain subject to their respective upstream licenses and trademark terms.
