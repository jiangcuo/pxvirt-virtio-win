#!/bin/bash
# Update VERSION, debian/changelog and the RPM spec to a new virtio-win release.
#
# usage: scripts/update-version.sh [--channel stable|latest] [VERSION]
#
# Without VERSION the version the channel currently points to is used. The ISO is
# downloaded to compute the checksum that is pinned in VERSION.
# shellcheck source=scripts/common.sh
. "$(dirname "$0")/common.sh"

channel=stable
version=
while [ $# -gt 0 ]; do
    case "$1" in
        --channel) channel=$2; shift 2 ;;
        -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
        *) version=$1; shift ;;
    esac
done

MAINTAINER=${MAINTAINER:-Lierfang Support Team <itsupport@lierfang.com>}

if [ -z "$version" ]; then
    version=$(curl -fsSL "$BASE_URL/$channel-virtio/" \
        | grep -oE 'virtio-win-[0-9]+\.[0-9]+\.[0-9]+\.iso' \
        | sed -E 's/^virtio-win-(.*)\.iso$/\1/' | sort -uV | tail -n1)
    [ -n "$version" ] || { echo "unable to determine $channel version" >&2; exit 1; }
fi

release=$(curl -fsSL "$BASE_URL/archive-virtio/" \
    | grep -oE "virtio-win-${version//./\\.}-[0-9]+/" \
    | sed -E 's/.*-([0-9]+)\/$/\1/' | sort -un | tail -n1)
[ -n "$release" ] || { echo "virtio-win $version not found in archive" >&2; exit 1; }

if [ "$version" = "$VIRTIO_WIN_VERSION" ] && [ "$release" = "$VIRTIO_WIN_RELEASE" ] \
    && [ -n "$VIRTIO_WIN_SHA256" ]; then
    echo "already at virtio-win $version-$release"
    exit 0
fi

mkdir -p "$BUILDDIR"
iso=$(iso_path "$version")
download "$(iso_url "$version" "$release")" "$iso"
sha256=$(sha256sum "$iso" | cut -d' ' -f1)

pkg_release=1
new_entry=1
if [ "$version" = "$VIRTIO_WIN_VERSION" ]; then
    if [ -z "$VIRTIO_WIN_SHA256" ] && [ "$release" = "$VIRTIO_WIN_RELEASE" ]; then
        # only pin the checksum of the current version
        pkg_release=$PKG_RELEASE
        new_entry=0
    else
        pkg_release=$((PKG_RELEASE + 1))
    fi
fi

cat > "$TOPDIR/VERSION" <<EOV
# managed by scripts/update-version.sh - sourced by make and shell scripts
VIRTIO_WIN_VERSION=$version
VIRTIO_WIN_RELEASE=$release
VIRTIO_WIN_SHA256=$sha256
PKG_RELEASE=$pkg_release
EOV

message="update to virtio-win $version-$release"

if [ "$new_entry" -eq 0 ]; then
    echo "pinned checksum of virtio-win $version-$release"
    if [ -n "${GITHUB_OUTPUT:-}" ]; then
        {
            echo "changed=true"
            echo "version=$version-$pkg_release"
            echo "message=pin checksum of virtio-win $version-$release"
        } >> "$GITHUB_OUTPUT"
    fi
    exit 0
fi

# debian/changelog
changelog="$TOPDIR/debian/changelog"
{
    echo "pxvirt-virtio-win ($version-$pkg_release) bookworm; urgency=medium"
    echo
    echo "  * $message"
    echo
    echo " -- $MAINTAINER  $(LC_ALL=C date -R)"
    echo
    cat "$changelog"
} > "$changelog.new"
mv "$changelog.new" "$changelog"

# rpm/pxvirt-virtio-win.spec %changelog
spec="$TOPDIR/rpm/pxvirt-virtio-win.spec"
entry="* $(LC_ALL=C date '+%a %b %d %Y') $MAINTAINER - $version-$pkg_release\n- $message\n"
sed -i "/^%changelog$/a $entry" "$spec"

echo "$message (package release $pkg_release)"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
        echo "changed=true"
        echo "version=$version-$pkg_release"
        echo "message=$message"
    } >> "$GITHUB_OUTPUT"
fi
