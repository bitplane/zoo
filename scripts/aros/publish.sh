#!/bin/sh
set -eu

tag=${1:?usage: publish.sh <tag> <archive>...}
shift
[ "$#" -gt 0 ]
version=${tag#v}
case "$tag" in v[0-9]*|[0-9]*) ;; *) echo "Expected a version tag" >&2; exit 1 ;; esac
case "$version" in *[!0-9.]*) echo "Invalid release version" >&2; exit 1 ;; esac
: "${PKG_SIGNKEY:?Set PKG_SIGNKEY to your signing key file}"

pkg=${PKG:-pkg}
repo=${GITHUB_REPOSITORY:-bitplane/zoo}
channel_url=${PKG_CHANNEL_URL:-https://aros-pkg.azurewebsites.net/bitplane}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM

for archive do
    name=$(basename "$archive")
    case "$name" in
        "zoo-$version-i386-aros.tar.bz2") arch=i386 ;;
        "zoo-$version-aarch64-aros.tar.bz2") arch=aarch64 ;;
        "zoo-$version-x86_64-aros.tar.bz2") arch=x86_64 ;;
        *) echo "Archive does not match release: $name" >&2; exit 1 ;;
    esac
    archive=$(CDPATH='' cd "$(dirname "$archive")" && pwd)/$name
    source="$archive!/zoo"
    "$pkg" MANIFEST "$source" KIND application NAME zoo VERSION "$version" > "$work/manifest"
    for field in "Name: zoo" "Version: $version" "Architecture: $arch"; do
        grep -Fxq "$field" "$work/manifest" || {
            echo "Unexpected package metadata: expected $field" >&2
            exit 1
        }
    done
    "$pkg" PUBLISH "$source" CHANNEL "$work/channel" KIND application \
        NAME zoo VERSION "$version" \
        UPSTREAM "https://github.com/$repo/releases/download/$tag/$name" \
        SHORT 'Zoo archive creator and extractor' \
        CATEGORY util/arc TAGS 'archive, compression' \
        AUTHOR 'Rahul Dhesi' \
        HOMEPAGE "https://github.com/$repo" REPOSITORY "https://github.com/$repo" \
        LICENSE LicenseRef-Zoo-2.1 DISTRIBUTION other
done

"$pkg" PUSH CHANNEL "$work/channel" TO "$channel_url"
