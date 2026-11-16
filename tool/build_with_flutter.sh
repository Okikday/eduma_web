#!/bin/sh
set -eu

project_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
flutter_source="${EDUMA_FLUTTER_SOURCE_DIR:-$project_root/../eduma}"

case "$flutter_source" in
  /*) ;;
  *) flutter_source="$project_root/$flutter_source" ;;
esac

if [ ! -f "$flutter_source/pubspec.yaml" ]; then
  echo "Flutter source workspace not found at: $flutter_source" >&2
  echo "Set EDUMA_FLUTTER_SOURCE_DIR to the eduma source checkout." >&2
  exit 1
fi

if ! command -v fvm >/dev/null 2>&1; then
  echo "FVM is required to build the pinned Flutter web app." >&2
  exit 1
fi

cd "$project_root"
sh tool/jaspr_with_google.sh build "$@"

mkdir -p "$project_root/build/jaspr/flutter"
(
  cd "$flutter_source"
  fvm flutter build web \
    --release \
    --base-href /flutter/ \
    --output "$project_root/build/jaspr/flutter"
)
