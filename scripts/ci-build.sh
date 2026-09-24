#!/bin/sh
set -eu

target=${1:?usage: ci-build.sh <linux-x86_64|macos-arm64|windows-x86_64>}
case "$target" in
    linux-x86_64|macos-arm64) exe=; cc=cc ;;
    windows-x86_64) exe=.exe; cc=gcc ;;
    *) echo "Unknown target: $target" >&2; exit 1 ;;
esac

make linux CC="$cc"
test -x "./zoo$exe"
test -x "./fiz$exe"

root=$(pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir "$work/out"
printf 'zoo release smoke\n\000\032\r\n\377' > "$work/hello.bin"
(
    cd "$work"
    "$root/zoo$exe" -add sample.zoo hello.bin
    "$root/zoo$exe" -list sample.zoo
    cd out
    "$root/zoo$exe" -extract ../sample.zoo
    cmp ../hello.bin hello.bin
)

if [ "${GITHUB_REF_TYPE:-}" = tag ]; then
    version=${GITHUB_REF_NAME#v}
    case "$version" in ''|*[!0-9.]*) echo "Invalid release version: $version" >&2; exit 1 ;; esac
    stage="zoo-$version-$target"
    mkdir -p "dist/$stage"
    cp "zoo$exe" "fiz$exe" Copyright Install zoo.1 fiz.1 "dist/$stage/"
    tar -C dist -czf "dist/$stage.tar.gz" "$stage"
fi
