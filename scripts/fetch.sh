#!/bin/bash
# Download the pinned virtio-win ISO and qemu-ga installers and verify their checksums.
# shellcheck source=scripts/common.sh
. "$(dirname "$0")/common.sh"

if [ -z "$VIRTIO_WIN_SHA256" ] || [ -z "$QEMU_GA_SHA256_X86_64" ] \
    || [ -z "$QEMU_GA_SHA256_ARM64" ]; then
    echo "checksums are not set in VERSION - run scripts/update-version.sh first" >&2
    exit 1
fi

mkdir -p "$BUILDDIR"

fetch() {
    local url=$1 dest=$2 sha256=$3

    if [ -f "$dest" ] && echo "$sha256  $dest" | sha256sum -c --quiet - 2>/dev/null; then
        echo "using cached $dest"
        return
    fi
    download "$url" "$dest"
    echo "$sha256  $dest" | sha256sum -c -
}

fetch "$(iso_url "$VIRTIO_WIN_VERSION" "$VIRTIO_WIN_RELEASE")" \
    "$(iso_path "$VIRTIO_WIN_VERSION")" "$VIRTIO_WIN_SHA256"
fetch "$(qemu_ga_url "$QEMU_GA_VERSION" x86_64)" \
    "$(qemu_ga_path "$QEMU_GA_VERSION" x86_64)" "$QEMU_GA_SHA256_X86_64"
fetch "$(qemu_ga_url "$QEMU_GA_VERSION" arm64)" \
    "$(qemu_ga_path "$QEMU_GA_VERSION" arm64)" "$QEMU_GA_SHA256_ARM64"
