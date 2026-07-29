# Sn0whax XBPS Repository

Unofficial third-party XBPS repository for a small selection of packages on Void Linux glibc.

> [!WARNING]
> This repository is independently maintained and is not reviewed, endorsed, signed, or distributed by the Void Linux project. Review package templates and workflow runs before installing packages.

## Available packages

- `brave-origin`
- `discord`
- `helium-browser`
- `heroic-games-launcher`
- `intel-media-driver-nonfree`
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
sudo xbps-install brave-origin discord helium-browser heroic-games-launcher intel-media-driver-nonfree spotify tutanota-desktop
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

The workflow in `.github/workflows/build.yaml` builds changed package templates, signs the resulting XBPS repository, and publishes release assets to the `latest` GitHub release.

The workflow supports pushes to `main` and manual runs through GitHub Actions. A successful build workflow does not by itself discover new upstream versions; package templates must still be updated by a maintainer or by separate package-specific update automation.

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
