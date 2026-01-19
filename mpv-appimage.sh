#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(cat ~/version)
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DESKTOP=/usr/share/applications/mpv.desktop
export ICON=/usr/share/icons/hicolor/128x128/apps/mpv.png
export OUTNAME=mpv-"$VERSION"-anylinux-"$ARCH".AppImage
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1
export URUNTIME_PRELOAD=1

# Deploy dependencies
quick-sharun /usr/bin/mpv

# Turn AppDir into AppImage
quick-sharun --make-appimage

# make appbundle
UPINFO="$(echo "$UPINFO" | sed 's#.AppImage#*.AppBundle#g')"
wget -O ./pelf "https://github.com/xplshn/pelf/releases/latest/download/pelf_$ARCH"
chmod +x ./pelf
echo "Generating [dwfs]AppBundle..."
./pelf --add-appdir ./AppDir \
	--appbundle-id="io.mpv.Mpv#github.com/$GITHUB_REPOSITORY:$VERSION@$(date +%d_%m_%Y)" \
	--appimage-compat \
	--disable-use-random-workdir \
	--add-updinfo "$UPINFO" \
	--compression "-C zstd:level=22 -S26 -B8" \
	--output-to mpv-"$VERSION"-anylinux-"$ARCH".dwfs.AppBundle
zsyncmake *.AppBundle -u *.AppBundle

mkdir -p ./dist
mv -v ./*.AppBundle* ./dist
echo "All Done!"
