#!/bin/sh

# dependencies:
# meson cmake automake ninja ninja-build vulkan-headers freetype-dev libass-dev libtool
# fribidi-dev harfbuzz-dev yasm libx11 libx11-dev libxinerama-dev libxrandr-dev
# libxscrnsaver libxscrnsaver-dev xscreensaver-gl-extras jack libpulse pulseaudio-dev
# rubberband libcaca mesa-egl libxpresent-dev lua5.3-dev libxcb-dev desktop-file-utils

set -eux
export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
REPO="https://github.com/mpv-player/mpv-build.git"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
URUNTIME_LITE="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH"
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"

# Build mpv
git clone "$REPO" ./mpv-build && (
	cd ./mpv-build
	printf "%s\n" "--enable-libdav1d" >> ffmpeg_options
	printf "%s\n" "--enable-small" >> ffmpeg_options
	./rebuild -j$(nproc)
	sudo ./install
)
rm -rf ./mpv-build

# bundle libs
mkdir -p ./AppDir
cd ./AppDir

wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
./lib4bin -p -v -s -k "$(command -v mpv)"

VERSION=$(./bin/mpv --version | awk 'FNR==1 {print $2; exit}')
if [ -z "$VERSION" ]; then
	echo "ERROR: Could not get version from mpv"
	exit 1
fi
echo "$VERSION" > ~/version

# prepare AppDir
cp /usr/local/share/applications/mpv.desktop ./
cp /usr/local/share/icons/hicolor/128x128/apps/mpv.png ./
ln -s ./mpv.png ./.DirIcon

cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"
export PATH="$PATH:$CACHEDIR/mpv-appimage_yt-dlp"
export SHARUN_ALLOW_SYS_VKICD=1

# Download yt-dlp if needed
if echo "$@" | grep -q "http" && ! command -v yt-dlp >/dev/null 2>&1; then
	echo "Video link detected but yt-dlp is not installed, installing..."
	mkdir -p "$CACHEDIR"/mpv-appimage_yt-dlp
	YT="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux"
	if command -v wget >/dev/null 2>&1; then
		wget -q "$YT" -O "$CACHEDIR"/mpv-appimage_yt-dlp/yt-dlp
	elif command -v curl >/dev/null 2>&1; then
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
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime
wget --retry-connrefused --tries=30 "$URUNTIME_LITE" -O ./uruntime-lite
chmod +x ./uruntime*

# Keep the mount point (speeds up launch time)
sed -i 's|URUNTIME_MOUNT=[0-9]|URUNTIME_MOUNT=0|' ./uruntime-lite

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime-lite --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S26 -B8 \
	--header uruntime-lite \
	-i ./AppDir -o ./mpv-"$VERSION"-anylinux-"$ARCH".AppImage

wget -O ./pelf "https://github.com/xplshn/pelf/releases/latest/download/pelf_$ARCH"
chmod +x ./pelf

echo "Generating [dwfs]AppBundle...(Go runtime)"
./pelf --add-appdir ./AppDir \
	--appbundle-id="io.mpv.Mpv#github.com/$GITHUB_REPOSITORY:$VERSION@$(date +%d_%m_%Y)" \
	--compression "-C zstd:level=22 -S26 -B8" \
	--output-to mpv-"$VERSION"-anylinux-"$ARCH".dwfs.AppBundle

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
zsyncmake *.AppBundle -u *.AppBundle

echo "All done!"
