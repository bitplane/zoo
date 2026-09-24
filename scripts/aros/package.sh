#!/bin/sh
set -eu

target=${1:?usage: package.sh <target> <version>}
version=${2:?usage: package.sh <target> <version>}
case "$target" in i386-aros|aarch64-aros|x86_64-aros) ;; *) exit 1 ;; esac
case "$version" in ''|*[!0-9.]*) echo "Invalid release version: $version" >&2; exit 1 ;; esac

name="zoo-$version-$target"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/zoo/C" "$work/zoo/Help/zoo" dist
cp zoo fiz "$work/zoo/C/"
cp Copyright Install zoo.1 fiz.1 "$work/zoo/Help/zoo/"
chmod 755 "$work/zoo/C/"*
chmod 644 "$work/zoo/Help/zoo/"*
epoch=${SOURCE_DATE_EPOCH:-$(git show -s --format=%ct HEAD)}
tar -C "$work" --sort=name --mtime="@$epoch" --owner=0 --group=0 \
    --numeric-owner -cjf "dist/$name.tar.bz2" zoo
(cd dist && sha256sum "$name.tar.bz2") > "dist/$name.tar.bz2.sha256"
