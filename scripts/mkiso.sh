#!/bin/bash
# Create the slim virtio-win ISO from build/virtio-win and the extra installers.
# shellcheck source=scripts/common.sh
. "$(dirname "$0")/common.sh"

out="$BUILDDIR/virtio-win"
iso_extra="$BUILDDIR/iso-extra"
iso="$BUILDDIR/pxvirt-virtio-win.iso"

[ -f "$out/VERSION" ] || { echo "run scripts/slim.sh first" >&2; exit 1; }

rm -f "$iso"
xorriso -as mkisofs -quiet -J -joliet-long -R \
    -V "virtio-win-$VIRTIO_WIN_VERSION" \
    -o "$iso" "$out" "$iso_extra"
chmod 0644 "$iso"
du -h "$iso"
