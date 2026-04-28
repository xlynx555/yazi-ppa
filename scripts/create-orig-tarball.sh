#!/bin/bash
# create-orig-tarball.sh — Download upstream musl binaries and create the orig tarball.
# Usage: ./scripts/create-orig-tarball.sh <version>
# Example: ./scripts/create-orig-tarball.sh 26.1.22
#
# The resulting tarball is placed in the parent directory of the repository,
# which is where dpkg-buildpackage expects it.

set -euo pipefail

VERSION="${1:?Usage: $0 <version>}"
PACKAGE="yazi"
ORIG_NAME="${PACKAGE}_${VERSION}.orig.tar.xz"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PARENT_DIR="$(cd "${REPO_DIR}/.." && pwd)"
OUTPUT="${PARENT_DIR}/${ORIG_NAME}"

TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "${TMPDIR}"; }
trap cleanup EXIT

BASE_URL="https://github.com/sxyazi/yazi/releases/download/v${VERSION}"

ARCH_SUFFIXES=(
    "x86_64-unknown-linux-musl"
    "aarch64-unknown-linux-musl"
)

echo "Creating orig tarball for yazi ${VERSION}..."

ORIG_DIR="${TMPDIR}/${PACKAGE}-${VERSION}"
mkdir -p "${ORIG_DIR}"

for SUFFIX in "${ARCH_SUFFIXES[@]}"; do
    ZIP_NAME="yazi-${SUFFIX}.zip"
    echo "  Downloading ${ZIP_NAME}..."
    curl -fsSL --retry 3 "${BASE_URL}/${ZIP_NAME}" -o "${ORIG_DIR}/${ZIP_NAME}"
done

echo "  Packing ${ORIG_NAME}..."
tar -C "${TMPDIR}" -cJf "${OUTPUT}" "${PACKAGE}-${VERSION}/"

echo "Done: ${OUTPUT}"
