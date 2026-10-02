#!/bin/bash
# Download the pinned virtio-win ISO and verify its checksum.
# shellcheck source=scripts/common.sh
. "$(dirname "$0")/common.sh"

if [ -z "$VIRTIO_WIN_SHA256" ]; then
    echo "VIRTIO_WIN_SHA256 is not set in VERSION - run scripts/update-version.sh first" >&2
    exit 1
fi

mkdir -p "$BUILDDIR"
iso=$(iso_path "$VIRTIO_WIN_VERSION")

if [ -f "$iso" ] && echo "$VIRTIO_WIN_SHA256  $iso" | sha256sum -c --quiet - 2>/dev/null; then
    echo "using cached $iso"
    exit 0
fi

download "$(iso_url "$VIRTIO_WIN_VERSION" "$VIRTIO_WIN_RELEASE")" "$iso"
echo "$VIRTIO_WIN_SHA256  $iso" | sha256sum -c -
