#!/bin/sh

set -ex
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	base-devel        \
	dav1d             \
	git               \
	lame              \
	lcms2             \
	libarchive        \
	libass            \
	libcdio           \
	libcdio-paranoia  \
	libdrm            \
	libdvdnav         \
	libdvdread        \
	libfdk-aac        \
	libjpeg-turbo     \
	libogg            \
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
./get-debloated-pkgs.sh --add-common --prefer-nano

echo "Building mpv..."
echo "---------------------------------------------------------------"
git clone "https://github.com/mpv-player/mpv-build.git" ./mpv-build 

cd ./mpv-build
echo "--enable-libdav1d"      >> ./ffmpeg_options
echo "--enable-small"         >> ./ffmpeg_options
echo "--enable-libshaderc"    >> ./ffmpeg_options
echo "-Dlibmpv=false"         >> ./mpv_options
echo "-Dlibbluray=disabled"   >> ./mpv_options
echo "-Dvapoursynth=disabled" >> ./mpv_options

# install in /usr rather than /usr/local
sed -i -e 's|meson setup build|meson setup build --prefix=/usr|' ./scripts/mpv-config

./rebuild -j$(nproc)
sudo ./install
/usr/bin/mpv --version | awk '{print $2; exit}' > ~/version

echo "All done!"
echo "---------------------------------------------------------------"
