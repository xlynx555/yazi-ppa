#!/bin/bash
# update-changelog.sh — Insert a new version entry into debian/changelog.
# Usage: ./scripts/update-changelog.sh <version> [distro] [ppa-revision]
# Example: ./scripts/update-changelog.sh 26.1.22 noble 1
#
# The resulting version string will be:  <version>-<ppa-rev>~ppa1~<distro>1
# e.g.  26.1.22-1~ppa1~noble1

set -euo pipefail

VERSION="${1:?Usage: $0 <version> [distro] [ppa-revision]}"
DISTRO="${2:-noble}"
PPA_REV="${3:-1}"

DEB_VERSION="${VERSION}-${PPA_REV}~ppa1~${DISTRO}1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_DIR}"

# Resolve maintainer from environment, git config, or fall back to a placeholder.
if [ -z "${DEBFULLNAME:-}" ]; then
    DEBFULLNAME="$(git config user.name 2>/dev/null || echo 'PPA Maintainer')"
fi
if [ -z "${DEBEMAIL:-}" ]; then
    DEBEMAIL="$(git config user.email 2>/dev/null || echo 'ppa@example.com')"
fi

export DEBFULLNAME DEBEMAIL

dch \
    --newversion "${DEB_VERSION}" \
    --distribution "${DISTRO}" \
    --force-distribution \
    "New upstream release ${VERSION}."

echo "changelog updated: yazi (${DEB_VERSION}) ${DISTRO}"
