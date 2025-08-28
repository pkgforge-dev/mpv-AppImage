#!/bin/sh

set -ex
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	base-devel        \
	git               \
	jack              \
	lcms2             \
	libarchive        \
	libass            \
	libbluray         \
	libcdio           \
	libcdio-paranoia  \
	libdrm            \
	libdvdnav         \
	libdvdread        \
	libjpeg-turbo     \
	libplacebo        \
	libpulse          \
	libsixel          \
	libx11            \
	libxext           \
	libxkbcommon      \
	libxpresent       \
	libxrandr         \
	libxss            \
	libxv             \
	luajit            \
	meson             \
	nasm              \
	pipewire-audio    \
	pulseaudio        \
	pulseaudio-alsa   \
	rubberband        \
	openal            \
	uchardet          \
	vulkan-headers    \
	vulkan-icd-loader \
	wayland           \
	wayland-protocols \
	wget              \
	xorg-server-xvfb  \
	zlib              \
	zsync

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-mesa --prefer-nano ffmpeg-mini libxml2-mini opus-mini

pacman -Rsndd --noconfirm vapoursynth # ffmpeg-mini doesn't link to it

echo "Building mpv..."
echo "---------------------------------------------------------------"
git clone "https://github.com/mpv-player/mpv-build.git" ./mpv-build 

cd ./mpv-build
printf "%s\n" "--enable-libdav1d" >> ffmpeg_options
printf "%s\n" "--enable-small" >> ffmpeg_options

# install in /usr rather than /usr/local
#sed -i -e 's|meson setup build|meson setup build --prefix=/usr|' ./scripts/mpv-config

./rebuild -j$(nproc)
sudo ./install
/usr/bin/mpv --version | awk '{print $2; exit}' > ~/version

echo "All done!"
echo "---------------------------------------------------------------"
