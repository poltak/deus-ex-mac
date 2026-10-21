#!/bin/bash
# make-app.sh [version]: build "dist/Deus Ex.app" from the engine build in SurrealEngine/build.
# The app has the engine, its libraries, the start script and the license texts in it. It has no game data.
# A version with a "v" at the start (a release tag such as v0.1.0) goes into the app without the "v".
set -e
W="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-$(cd "$W" && git rev-parse --short HEAD 2>/dev/null || echo dev)}"
VERSION="${VERSION#v}"
BUILD="$W/SurrealEngine/build"
SRC="$BUILD/SurrealEngine.app"
APP="$W/dist/Deus Ex.app"

[ -x "$SRC/Contents/MacOS/SurrealEngine" ] || { echo "Build the engine first: (cd SurrealEngine/build && ninja SurrealEngine)"; exit 1; }

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Frameworks" "$APP/Contents/Resources"

cp "$SRC/Contents/MacOS/SurrealEngine" "$APP/Contents/MacOS/SurrealEngine"
cp "$SRC/Contents/Resources/SurrealEngine.pk3" "$APP/Contents/Resources/"
cp "$SRC/Contents/Frameworks/libMoltenVK.dylib" "$APP/Contents/Frameworks/"
cp "$BUILD/libSurrealVideo.dylib" "$APP/Contents/Frameworks/"
cp -L "$BUILD/Thirdparty/openal-soft/libopenal.1.dylib" "$APP/Contents/Frameworks/"
cp "$W/packaging/DeusEx.sh" "$APP/Contents/MacOS/DeusEx"
chmod +x "$APP/Contents/MacOS/DeusEx" "$APP/Contents/MacOS/SurrealEngine"
sed "s/VERSION/$VERSION/g" "$W/packaging/Info.plist" > "$APP/Contents/Info.plist"

# The licenses of this project, of the engine and of the libraries in the app. LICENSE.md of the engine has the
# libraries that are part of the engine binary. OpenAL Soft and MoltenVK are separate files in Contents/Frameworks.
LIC="$APP/Contents/Resources/Licenses"
mkdir -p "$LIC"
cp "$W/packaging/Licenses-README.txt" "$LIC/README.txt"
cp "$W/LICENSE" "$LIC/deus-ex-mac.txt"
cp "$W/SurrealEngine/LICENSE.md" "$LIC/SurrealEngine.md"
cp "$W/SurrealEngine/Thirdparty/schrift/LICENSE.txt" "$LIC/schrift.txt"
cp "$W/SurrealEngine/Thirdparty/openal-soft/COPYING" "$LIC/openal-soft.txt"
cp "$BUILD/_deps/moltenvk-src/LICENSE" "$LIC/MoltenVK.txt"

# The app icon is our own picture (packaging/AppIcon.svg). The game has its own logo, which is not ours to put in the
# app. packaging/AppIcon-1024.png is the SVG rendered with rsvg-convert, with fine noise against color bands in the
# dark background (magick -channel RGB -attenuate 0.12 +noise Gaussian). sips makes the smaller sizes from it, so the
# build needs no tool that is not on each Mac.
ICONSET="$(mktemp -d "${TMPDIR:-/tmp}/dx-icon.XXXXXX")/AppIcon.iconset"
mkdir -p "$ICONSET"
ICON="$W/packaging/AppIcon-1024.png"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$ICON" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  sips -z "$((size * 2))" "$((size * 2))" "$ICON" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns" 2>/dev/null || echo "note: the app icon was not made (iconutil failed)"
rm -rf "$(dirname "$ICONSET")"

# The engine must find its libraries in the app only, not in the build folder of this computer
BIN="$APP/Contents/MacOS/SurrealEngine"
otool -l "$BIN" | awk '/LC_RPATH/ {getline; getline; sub(/^ *path /, ""); sub(/ \(offset [0-9]+\)$/, ""); print}' | while IFS= read -r rpath; do
  case "$rpath" in
    @executable_path/*) ;;
    *) install_name_tool -delete_rpath "$rpath" "$BIN" ;;
  esac
done

# A change of the binary makes its signature invalid. Sign the app again (ad hoc, no developer account).
codesign --force --deep --sign - "$APP" >/dev/null 2>&1

echo "Made: $APP ($(du -sh "$APP" | cut -f1)), version $VERSION"
echo "Libraries that the engine loads from outside the app and the system:"
otool -L "$BIN" "$APP/Contents/Frameworks/"*.dylib | grep -v "^/\|@rpath\|/usr/lib/\|/System/Library/" | grep -v ":$" || echo "  none"
