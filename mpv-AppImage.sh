#!/bin/sh

# dependencies:
# meson cmake automake ninja ninja-build vulkan-headers freetype-dev libass-dev libtool
# fribidi-dev harfbuzz-dev yasm libx11 libx11-dev libxinerama-dev libxrandr-dev
# libxscrnsaver libxscrnsaver-dev xscreensaver-gl-extras jack libpulse pulseaudio-dev
# rubberband libcaca mesa-egl libxpresent-dev lua5.3-dev libxcb-dev desktop-file-utils

set -eu
export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
REPO="https://github.com/mpv-player/mpv-build.git"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|mpv-AppImage|latest|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
mkdir -p ./mpv/AppDir
cd ./mpv/AppDir

# Build mpv
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
git clone "$REPO" ./mpv-build
cd ./mpv-build
sed -i "s#meson setup build#meson setup build -Dprefix=$CURRENTDIR/shared#g" \
	./scripts/mpv-config
./rebuild -j$(nproc)
./install
cd ..
rm -rf ./mpv-build
ln -s ./shared ./usr

# bundle libs
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
./lib4bin -p -w -v -s ./shared/bin/mpv
VERSION=$(./bin/mpv --version 2>/dev/null | awk 'FNR==1 {print $2; exit}')
if [ -z "$VERSION" ]; then
	echo "ERROR: Could not get version from mpv"
	exit 1
fi
export VERSION
echo "$VERSION" > ~/version
# HACK
sed -i 's|/usr|/KEK|g' ./shared/lib/ld-linux-x86-64.so.2

# prepare AppDir
cp ./usr/share/applications/*.desktop ./
cp ./usr/share/icons/hicolor/128x128/apps/mpv.png ./
ln -s ./mpv.png ./.DirIcon
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
export XDG_DATA_DIRS="$CURRENTDIR/usr/share:$XDG_DATA_DIRS"
export PATH="$CURRENTDIR/bin:$PATH"
CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"
export PATH="$PATH:$CACHEDIR/mpv-appimage_yt-dlp"
export XDG_DATA_DIRS="$CURRENTDIR/usr/share:$XDG_DATA_DIRS"

# Download yt-dlp if needed
if echo "$@" | grep -q "http" && ! command -v yt-dlp >/dev/null 2>&1; then
	echo "Video link detected but yt-dlp is not installed, installing..."
	mkdir -p "$CACHEDIR"/mpv-appimage_yt-dlp
	if command -v wget >/dev/null 2>&1; then
		YT="$(wget -q https://api.github.com/repos/yt-dlp/yt-dlp/releases -O - \
		  | sed 's/[()",{} ]/\n/g' | grep -oi -m1 'https.*yt.*linux$')"
		wget -q "$YT" -O "$CACHEDIR"/mpv-appimage_yt-dlp/yt-dlp
	elif command -v curl >/dev/null 2>&1; then
		YT="$(curl -Ls https://api.github.com/repos/yt-dlp/yt-dlp/releases \
		  | sed 's/[()",{} ]/\n/g' | grep -oi -m1 'https.*yt.*linux$')"
		curl -Ls "$YT" -o "$CACHEDIR"/mpv-appimage_yt-dlp/yt-dlp
	else
		echo "ERROR: You need wget or curl in order to download yt-dlp"
	fi
	chmod +x "$CACHEDIR"/mpv-appimage_yt-dlp/yt-dlp
fi
[ -z "$1" ] && set -- "--player-operation-mode=pseudo-gui"
"$CURRENTDIR"/bin/mpv "$@"
EOF
chmod +x ./AppRun

# MAKE APPIMAGE WITH URUNTIME
cd ..
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

# Keep the mount point (speeds up launch time)
sed -i 's|URUNTIME_MOUNT=[0-9]|URUNTIME_MOUNT=0|' ./uruntime

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S26 -B8 \
	--header uruntime \
	-i ./AppDir -o ./mpv-"$VERSION"-anylinux-"$ARCH".AppImage

wget -qO ./pelf "https://github.com/xplshn/pelf/releases/latest/download/pelf_$ARCH" 
chmod +x ./pelf
echo "Generating [dwfs]AppBundle...(Go runtime)"
./pelf --add-appdir ./AppDir \
	--appbundle-id="mpv-$VERSION" \
	--compression "-C zstd:level=22 -S26 -B8" \
	--output-to mpv-"$VERSION"-anylinux-"$ARCH".dwfs.AppBundle

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
zsyncmake *.AppBundle -u *.AppBundle

mv ./*.AppImage* ../
mv ./*.AppBundle* ../
cd ..
echo "All done!"
