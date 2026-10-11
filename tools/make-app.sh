#!/bin/bash
# make-app.sh [version]: build "dist/Deus Ex.app" from the engine build in SurrealEngine/build.
# The app has the engine, its libraries and the start script in it. It has no game data.
set -e
W="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-$(cd "$W" && git rev-parse --short HEAD 2>/dev/null || echo dev)}"
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

# The app icon is the icon of the engine. The game has its own logo, which is not ours to put in the app.
ICONSET="$(mktemp -d "${TMPDIR:-/tmp}/dx-icon.XXXXXX")/AppIcon.iconset"
mkdir -p "$ICONSET"
RES="$W/SurrealEngine/Resources"
cp "$RES/surreal-engine-icon-16.png" "$ICONSET/icon_16x16.png"
cp "$RES/surreal-engine-icon-32.png" "$ICONSET/icon_16x16@2x.png"
cp "$RES/surreal-engine-icon-32.png" "$ICONSET/icon_32x32.png"
cp "$RES/surreal-engine-icon-64.png" "$ICONSET/icon_32x32@2x.png"
cp "$RES/surreal-engine-icon-128.png" "$ICONSET/icon_128x128.png"
cp "$RES/surreal-engine-icon-256.png" "$ICONSET/icon_128x128@2x.png"
cp "$RES/surreal-engine-icon-256.png" "$ICONSET/icon_256x256.png"
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
