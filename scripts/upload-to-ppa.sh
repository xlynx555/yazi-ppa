#!/bin/bash
# upload-to-ppa.sh — Upload a signed source package to a Launchpad PPA.
# Usage: ./scripts/upload-to-ppa.sh <ppa> [changes-file]
# Example: ./scripts/upload-to-ppa.sh ppa:myuser/yazi
#          ./scripts/upload-to-ppa.sh ppa:myuser/yazi ../yazi_26.1.22-1~ppa1~noble1_source.changes
#
# If [changes-file] is omitted the most recently modified *.changes file in
# the parent directory of the repository is used.

set -euo pipefail

PPA="${1:?Usage: $0 <ppa:owner/name> [changes-file]}"
CHANGES_FILE="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -z "${CHANGES_FILE}" ]; then
    CHANGES_FILE="$(ls -t "${PARENT_DIR}"/*.changes 2>/dev/null | head -1 || true)"
    if [ -z "${CHANGES_FILE}" ]; then
        echo "Error: no .changes file found in ${PARENT_DIR}" >&2
        exit 1
    fi
fi

echo "Uploading '${CHANGES_FILE}' to '${PPA}'..."
dput "${PPA}" "${CHANGES_FILE}"
echo "Upload complete."
