#!/bin/bash
# Extract the drivers listed in slim.conf from the ISO into build/virtio-win.
# shellcheck source=scripts/common.sh
. "$(dirname "$0")/common.sh"
# shellcheck source=/dev/null
. "$TOPDIR/slim.conf"

iso=$(iso_path "$VIRTIO_WIN_VERSION")
[ -f "$iso" ] || { echo "missing $iso - run scripts/fetch.sh first" >&2; exit 1; }

extract="$BUILDDIR/iso"
out="$BUILDDIR/virtio-win"
rm -rf "$extract" "$out"
mkdir -p "$extract" "$out"

bsdtar -xf "$iso" -C "$extract"
chmod -R u+w "$extract"

for driver in $DRIVERS; do
    found=0
    for os in $OSES; do
        for arch in $ARCHES; do
            src="$extract/$driver/$os/$arch"
            [ -d "$src" ] || continue
            mkdir -p "$out/$driver/$os"
            cp -r "$src" "$out/$driver/$os/$arch"
            found=1
        done
    done
    if [ "$found" -eq 0 ]; then
        echo "driver '$driver' not found for any of: $OSES / $ARCHES" >&2
        exit 1
    fi
done

for file in $EXTRA_FILES; do
    if [ -f "$extract/$file" ]; then
        mkdir -p "$out/$(dirname "$file")"
        cp "$extract/$file" "$out/$file"
    else
        echo "warning: '$file' not found on ISO, skipping" >&2
    fi
done

# guest agent installers from the qemu-guest-agent repository
mkdir -p "$out/guest-agent"
for arch in x86_64 arm64; do
    cp "$(qemu_ga_path "$QEMU_GA_VERSION" "$arch")" "$out/guest-agent/qemu-ga-$arch.msi"
done

# remove debug symbols, they are not needed for installation
find "$out" -type f -iname '*.pdb' -delete

echo "$VIRTIO_WIN_VERSION" > "$out/VERSION"
find "$out" -type d -exec chmod 0755 {} +
find "$out" -type f -exec chmod 0644 {} +

rm -rf "$extract"
du -sh "$out"
