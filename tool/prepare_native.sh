#!/usr/bin/env bash
# Builds the native libraries the app loads, at the revisions pinned in
# tool/native.lock.json, into build/native/<platform>/:
#
#   libdocudis_capi.dylib        docudis-core (with language identification)
#   libdocudis_ner_capi.dylib    docudis-ner
#   libonnxruntime.dylib         ONNX Runtime, verified against its SHA-256
#
# The Xcode build copies them into Docudis.app/Contents/Frameworks.
#
#   tool/prepare_native.sh            # release builds
#   DOCUDIS_CORE_SOURCE=../docudis-core tool/prepare_native.sh
#
# DOCUDIS_CORE_SOURCE / DOCUDIS_NER_SOURCE use a local checkout instead of a
# fresh clone; it must be at the pinned revision. Only macOS (Apple silicon)
# for now: ONNX Runtime 1.30 ships no Intel macOS build.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
lock="$repo_root/tool/native.lock.json"

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) platform=macos; ort_key=macos-arm64 ;;
  *) echo "prepare_native.sh supports macOS on Apple silicon only" >&2; exit 2 ;;
esac

field() { python3 -c "import json,sys; d=json.load(open('$lock')); print(d$1)"; }

out="$repo_root/build/native/$platform"
cache="$repo_root/build/native-cache"
export CARGO_TARGET_DIR="$cache/target"
mkdir -p "$out" "$cache"

# Checks out repository $2 at revision $3 into the cache, or verifies the
# local checkout in the environment variable named $1.
source_at() {
  local override="${!1:-}" repository="$2" revision="$3" name="$4"
  if [[ -n "$override" ]]; then
    local actual
    actual="$(git -C "$override" rev-parse HEAD)"
    [[ "$actual" == "$revision" ]] || {
      echo "$1 is at $actual, expected $revision" >&2
      exit 1
    }
    (cd "$override" && pwd)
    return
  fi
  local dir="$cache/src/$name-$revision"
  if [[ ! -d "$dir/.git" ]]; then
    mkdir -p "$dir"
    git -C "$dir" init -q
    git -C "$dir" remote add origin "$repository"
  fi
  if [[ "$(git -C "$dir" rev-parse -q --verify HEAD || true)" != "$revision" ]]; then
    git -C "$dir" fetch -q --depth 1 origin "$revision"
    git -C "$dir" checkout -q --detach FETCH_HEAD
  fi
  echo "$dir"
}

# Copies a built dylib into $out under @rpath, so the app finds it in its
# Frameworks folder.
install_dylib() {
  local from="$1" name="$2"
  cp "$from" "$out/$name"
  chmod u+w "$out/$name"
  install_name_tool -id "@rpath/$name" "$out/$name"
  # Rewriting the install name voids the signature; Apple silicon refuses
  # to load an unsigned library. The app build signs it again for real.
  codesign --force --sign - "$out/$name"
}

core_src="$(source_at DOCUDIS_CORE_SOURCE \
  "$(field "['docudis_core']['repository']")" \
  "$(field "['docudis_core']['revision']")" docudis-core)"
echo "Building docudis-core ($(git -C "$core_src" rev-parse --short HEAD))"
(cd "$core_src" && cargo build --release -p docudis-capi \
  --features "$(field "['docudis_core']['features']")")
install_dylib "$CARGO_TARGET_DIR/release/libdocudis_capi.dylib" libdocudis_capi.dylib

ner_src="$(source_at DOCUDIS_NER_SOURCE \
  "$(field "['docudis_ner']['repository']")" \
  "$(field "['docudis_ner']['revision']")" docudis-ner)"
echo "Building docudis-ner ($(git -C "$ner_src" rev-parse --short HEAD))"
(cd "$ner_src" && cargo build --release -p docudis-ner-capi)
install_dylib "$CARGO_TARGET_DIR/release/libdocudis_ner_capi.dylib" libdocudis_ner_capi.dylib

ort_version="$(field "['onnxruntime']['version']")"
ort_url="$(field "['onnxruntime']['$ort_key']['url']")"
ort_sha="$(field "['onnxruntime']['$ort_key']['sha256']")"
archive="$cache/$(basename "$ort_url")"
if [[ ! -f "$archive" ]] || [[ "$(shasum -a 256 "$archive" | cut -d' ' -f1)" != "$ort_sha" ]]; then
  echo "Downloading ONNX Runtime $ort_version"
  curl -fL --retry 3 -o "$archive.part" "$ort_url"
  mv "$archive.part" "$archive"
fi
actual_sha="$(shasum -a 256 "$archive" | cut -d' ' -f1)"
[[ "$actual_sha" == "$ort_sha" ]] || {
  echo "ONNX Runtime archive SHA-256 is $actual_sha, expected $ort_sha" >&2
  exit 1
}
tar -xzf "$archive" -C "$cache"
install_dylib "$cache/onnxruntime-osx-arm64-$ort_version/lib/libonnxruntime.$ort_version.dylib" \
  libonnxruntime.dylib

ls -lh "$out"
