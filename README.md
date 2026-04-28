# yazi PPA packaging

Debian/Ubuntu packaging for [yazi](https://github.com/sxyazi/yazi) — blazing-fast terminal file manager.

The PPA repackages the **official upstream musl static binaries** for amd64 and arm64.  
No Rust toolchain is required on the build host; Launchpad simply unpacks the right binary for each architecture.

---

## Repository layout

```
debian/
    changelog        version history
    control          package metadata & dependencies
    copyright        upstream licence text
    rules            debhelper build rules
    source/format    "3.0 (quilt)"
    watch            uscan upstream-version tracking
scripts/
    create-orig-tarball.sh   download upstream zips → *.orig.tar.xz
    update-changelog.sh      bump debian/changelog for a target series
    upload-to-ppa.sh         dput a .changes file to Launchpad
.github/workflows/
    update-ppa.yml           automatic nightly check + PPA upload
```

---

## One-time setup

### 1 — Create a Launchpad account and PPA

1. Sign up at <https://launchpad.net>.
2. Go to **Your PPAs** → **Create a new PPA**.
   * Name it, e.g. `yazi`.
   * Enable **arm64** builds under *Processors* (amd64 is on by default).
3. Note your PPA address, e.g. `ppa:youruser/yazi`.

### 2 — Generate a GPG key and register it on Launchpad

```bash
# Generate a new key (use a strong passphrase or no passphrase for automation)
gpg --full-generate-key
# Recommended: RSA 4096, never expires (or a long expiry)

# Find your key ID / fingerprint
gpg --list-secret-keys --keyid-format LONG

# Upload the public key to the Ubuntu keyserver (required by Launchpad)
gpg --keyserver keyserver.ubuntu.com --send-keys <KEY-ID>
```

Then in your Launchpad profile go to **OpenPGP keys** and add the fingerprint.

### 3 — Export and store the key for GitHub Actions

```bash
# Export the private key as base64
gpg --export-secret-keys --armor <KEY-ID> | base64 > gpg-private-key.b64
```

In your GitHub repository go to **Settings → Secrets and variables → Actions** and add:

| Secret name       | Value                                                        |
|-------------------|--------------------------------------------------------------|
| `GPG_PRIVATE_KEY` | Content of `gpg-private-key.b64` (base64-encoded ASCII key) |
| `GPG_KEY_ID`      | Your GPG key fingerprint (no spaces), e.g. `ABCD1234...`    |
| `LAUNCHPAD_PPA`   | Your PPA address, e.g. `ppa:youruser/yazi`                   |
| `DEBFULLNAME`     | Your full name as registered on Launchpad                    |
| `DEBEMAIL`        | E-mail address attached to your Launchpad/GPG key            |

> **Security note:** A key used in CI should ideally be a dedicated subkey with no expiry, separate from your personal master key.

### 4 — Update the maintainer field

Edit `debian/changelog` and `debian/control` to replace the placeholder maintainer:

```
Maintainer: Your Name <you@example.com>
```

### 5 — Grant Actions write permission to the repository

In **Settings → Actions → General** enable *"Read and write permissions"* (the workflow commits the updated changelog back to main).

---

## Triggering a build manually

Go to **Actions → Update Launchpad PPA → Run workflow**.  
You can optionally pin a specific upstream version (e.g. `26.1.22`) or leave the field empty to pick the latest release automatically.

---

## Local workflow (building without CI)

### Prerequisites

```bash
sudo apt-get install devscripts dpkg-dev debhelper dput unzip curl gpg
```

### Step-by-step

```bash
# 1. Clone this repo
git clone https://github.com/youruser/yazi-ppa.git
cd yazi-ppa

# 2. Download upstream binaries and create the orig tarball
./scripts/create-orig-tarball.sh 26.1.22
# → creates ../yazi_26.1.22.orig.tar.xz

# 3. Update debian/changelog for the target series
./scripts/update-changelog.sh 26.1.22 noble 1
# → inserts yazi (26.1.22-1~ppa1~noble1) noble

# 4. Build a signed, source-only package
cd ..
dpkg-buildpackage -S -sa -k<YOUR-GPG-KEY-ID>
# → creates yazi_26.1.22-1~ppa1~noble1_source.changes (and friends) in ../

# 5. Upload to your PPA
cd yazi-ppa
./scripts/upload-to-ppa.sh ppa:youruser/yazi
```

Repeat steps 3–5 for each additional Ubuntu series (jammy, oracular, …) before pushing.

---

## Adding or removing Ubuntu series

Edit `.github/workflows/update-ppa.yml` and update the `UBUNTU_SERIES` environment variable:

```yaml
env:
  UBUNTU_SERIES: noble jammy oracular plucky
```

The first entry is treated as the *primary* series — the one whose changelog entry is committed back to the repository.

---

## How it works

1. **Orig tarball** — `scripts/create-orig-tarball.sh` downloads  
   `yazi-x86_64-unknown-linux-musl.zip` and `yazi-aarch64-unknown-linux-musl.zip`  
   from the upstream GitHub release and bundles them into `yazi_<version>.orig.tar.xz`.

2. **Source package** — `debian/rules` unpacks the architecture-appropriate zip at build time using `DEB_HOST_ARCH`.  Launchpad's amd64 builders unpack the x86_64 zip; arm64 builders unpack the aarch64 zip.

3. **Signing and upload** — `dpkg-buildpackage -S -sa` produces a signed  
   `_source.changes` file; `dput` transmits it to Launchpad over HTTPS/FTP.

4. **Launchpad builds** — Launchpad queues binary builds automatically.  
   Monitor progress at `https://launchpad.net/~youruser/+archive/ubuntu/yazi`.

---

## Installing from the PPA

```bash
sudo add-apt-repository ppa:youruser/yazi
sudo apt-get update
sudo apt-get install yazi
```
