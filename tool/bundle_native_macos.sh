#!/bin/sh
# Xcode build phase: copies the libraries tool/prepare_native.sh built into
# Docudis.app/Contents/Frameworks and signs them with the app's identity.
set -eu

src="$PROJECT_DIR/../build/native/macos"
dest="$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH"
mkdir -p "$dest"
for name in libdocudis_capi.dylib libdocudis_ner_capi.dylib libonnxruntime.dylib; do
  if [ ! -f "$src/$name" ]; then
    echo "error: $src/$name is missing; run tool/prepare_native.sh first" >&2
    exit 1
  fi
  cp -f "$src/$name" "$dest/$name"
  codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY:--}" --timestamp=none "$dest/$name"
done
