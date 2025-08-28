#!/bin/sh

set -eux

ARCH="$(uname -m)"
VERSION="$(cat ~/version)"
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/execv-hook/useful-tools/quick-sharun.sh"
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"

export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DESKTOP=/usr/share/applications/mpv.desktop
export ICON=/usr/share/icons/hicolor/128x128/apps/mpv.png
export OUTNAME=mpv-"$VERSION"-anylinux-"$ARCH".AppImage
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1
export DEPLOY_PIPEWIRE=1
export URUNTIME_PRELOAD=1

# ADD LIBRARIES
wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
./quick-sharun /usr/bin/mpv

# MAKE APPIMAGE WITH URUNTIME
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage
./uruntime2appimage

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
mv -v ./*.AppImage*  ./dist
mv -v ./*.AppBundle* ./dist
mv -v ~/version      ./dist
echo "All Done!"
