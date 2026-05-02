#!/usr/bin/env bash
set -euo pipefail

ALIAS="plumjam-fsn1"
BUCKET="plumjam"
SRC="$ALIAS/$BUCKET"
DST="$ALIAS/$BUCKET/nix"
JOBS=16

echo "Removing originals..."
echo "Removing nix-cache-info..."
sudo mc rm --recursive --force --versions "$SRC/nix-cache-info" || true

echo "Removing nar/..."
sudo mc rm --recursive --force --versions "$SRC/nar" || true

echo "Removing hex directories..."
for hex in {0..9} {a..f}; do
  for hex2 in {0..9} {a..f}; do
    dir="${hex}${hex2}"
    echo "Removing $dir"
    sudo mc rm --recursive --force --versions "$SRC/$dir/" || true
  done
done

echo "Migration complete."
echo "Verify: nix store info --store 's3://$BUCKET/nix?endpoint=fsn1.your-objectstorage.com'"
