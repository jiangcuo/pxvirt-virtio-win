# shellcheck shell=bash
set -euo pipefail

TOPDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILDDIR=${BUILDDIR:-$TOPDIR/build}

BASE_URL=${BASE_URL:-https://fedorapeople.org/groups/virt/virtio-win/direct-downloads}
QEMU_GA_REPO=${QEMU_GA_REPO:-jiangcuo/qemu-guest-agent}
QEMU_GA_BASE_URL=${QEMU_GA_BASE_URL:-https://github.com/$QEMU_GA_REPO/releases/download}

# shellcheck source=/dev/null
. "$TOPDIR/VERSION"

iso_url() {
    local version=$1 release=$2
    echo "$BASE_URL/archive-virtio/virtio-win-$version-$release/virtio-win-$version.iso"
}

iso_path() {
    echo "$BUILDDIR/virtio-win-$1.iso"
}

qemu_ga_url() {
    local version=$1 arch=$2
    echo "$QEMU_GA_BASE_URL/v$version/qemu-ga-$arch.msi"
}

qemu_ga_path() {
    echo "$BUILDDIR/qemu-ga-$1-$2.msi"
}

download() {
    local url=$1 dest=$2
    echo "downloading $url" >&2
    curl -fL --retry 5 --retry-delay 5 -o "$dest.tmp" "$url"
    mv "$dest.tmp" "$dest"
}
