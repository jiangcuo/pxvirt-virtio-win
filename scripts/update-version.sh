#!/bin/bash
# Update VERSION, debian/changelog and the RPM spec to new virtio-win and qemu-ga releases.
#
# usage: scripts/update-version.sh [--channel stable|latest] [--qemu-ga VERSION] [VERSION]
#
# Without VERSION the virtio-win version the channel currently points to is used, without
# --qemu-ga the latest release of the qemu-guest-agent repository. The files are downloaded
# to compute the checksums that are pinned in VERSION.
# shellcheck source=scripts/common.sh
. "$(dirname "$0")/common.sh"

channel=stable
version=
ga_version=
while [ $# -gt 0 ]; do
    case "$1" in
        --channel) channel=$2; shift 2 ;;
        --qemu-ga) ga_version=$2; shift 2 ;;
        -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
        *) version=$1; shift ;;
    esac
done

MAINTAINER=${MAINTAINER:-Lierfang Support Team <itsupport@lierfang.com>}

# virtio-win
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

# qemu-ga
if [ -z "$ga_version" ]; then
    auth=()
    [ -n "${GITHUB_TOKEN:-}" ] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
    ga_version=$(curl -fsSL "${auth[@]}" \
        "https://api.github.com/repos/$QEMU_GA_REPO/releases/latest" \
        | sed -n 's/^ *"tag_name": *"v\([^"]*\)".*/\1/p')
    [ -n "$ga_version" ] || { echo "unable to determine latest qemu-ga release" >&2; exit 1; }
fi

mkdir -p "$BUILDDIR"
changes=()

sha256=$VIRTIO_WIN_SHA256
if [ "$version" != "$VIRTIO_WIN_VERSION" ] || [ "$release" != "$VIRTIO_WIN_RELEASE" ] \
    || [ -z "$sha256" ]; then
    iso=$(iso_path "$version")
    download "$(iso_url "$version" "$release")" "$iso"
    sha256=$(sha256sum "$iso" | cut -d' ' -f1)
    if [ "$version" != "$VIRTIO_WIN_VERSION" ] || [ "$release" != "$VIRTIO_WIN_RELEASE" ]; then
        changes+=("update to virtio-win $version-$release")
    fi
fi

ga_sha256_x86_64=$QEMU_GA_SHA256_X86_64
ga_sha256_arm64=$QEMU_GA_SHA256_ARM64
if [ "$ga_version" != "$QEMU_GA_VERSION" ] || [ -z "$ga_sha256_x86_64" ] \
    || [ -z "$ga_sha256_arm64" ]; then
    for arch in x86_64 arm64; do
        msi=$(qemu_ga_path "$ga_version" "$arch")
        download "$(qemu_ga_url "$ga_version" "$arch")" "$msi"
    done
    ga_sha256_x86_64=$(sha256sum "$(qemu_ga_path "$ga_version" x86_64)" | cut -d' ' -f1)
    ga_sha256_arm64=$(sha256sum "$(qemu_ga_path "$ga_version" arm64)" | cut -d' ' -f1)
    if [ "$ga_version" != "$QEMU_GA_VERSION" ]; then
        changes+=("update qemu-ga to $ga_version")
    fi
fi

if [ "$sha256" = "$VIRTIO_WIN_SHA256" ] && [ "$ga_sha256_x86_64" = "$QEMU_GA_SHA256_X86_64" ] \
    && [ "$ga_sha256_arm64" = "$QEMU_GA_SHA256_ARM64" ] && [ ${#changes[@]} -eq 0 ]; then
    echo "already at virtio-win $version-$release and qemu-ga $ga_version"
    exit 0
fi

if [ "$version" != "$VIRTIO_WIN_VERSION" ]; then
    pkg_release=1
elif [ ${#changes[@]} -gt 0 ]; then
    pkg_release=$((PKG_RELEASE + 1))
else
    # only pinned the checksums of the current versions
    pkg_release=$PKG_RELEASE
fi

cat > "$TOPDIR/VERSION" <<EOV
# managed by scripts/update-version.sh - sourced by make and shell scripts
# leave the checksums empty after changing a version, CI pins them on push
VIRTIO_WIN_VERSION=$version
VIRTIO_WIN_RELEASE=$release
VIRTIO_WIN_SHA256=$sha256
QEMU_GA_VERSION=$ga_version
QEMU_GA_SHA256_X86_64=$ga_sha256_x86_64
QEMU_GA_SHA256_ARM64=$ga_sha256_arm64
PKG_RELEASE=$pkg_release
EOV

if [ ${#changes[@]} -eq 0 ]; then
    message="pin checksums of virtio-win $version-$release and qemu-ga $ga_version"
else
    message=$(printf '%s, ' "${changes[@]}")
    message=${message%, }

    # debian/changelog
    changelog="$TOPDIR/debian/changelog"
    {
        echo "pxvirt-virtio-win ($version-$pkg_release) bookworm; urgency=medium"
        echo
        for change in "${changes[@]}"; do
            echo "  * $change"
        done
        echo
        echo " -- $MAINTAINER  $(LC_ALL=C date -R)"
        echo
        cat "$changelog"
    } > "$changelog.new"
    mv "$changelog.new" "$changelog"

    # rpm/pxvirt-virtio-win.spec %changelog
    spec="$TOPDIR/rpm/pxvirt-virtio-win.spec"
    entry="* $(LC_ALL=C date '+%a %b %d %Y') $MAINTAINER - $version-$pkg_release"
    for change in "${changes[@]}"; do
        entry+="\n- $change"
    done
    sed -i "/^%changelog$/a $entry\n" "$spec"
fi

echo "$message (package release $pkg_release)"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
        echo "changed=true"
        echo "version=$version-$pkg_release"
        echo "message=$message"
    } >> "$GITHUB_OUTPUT"
fi
