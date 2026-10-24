#!/bin/sh

set -eu

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	dav1d             \
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
	spirv-headers     \
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
get-debloated-pkgs --add-common --prefer-nano

echo "Building mpv..."
echo "---------------------------------------------------------------"
git clone "https://github.com/mpv-player/mpv-build.git" ./mpv-build
cd ./mpv-build

if [ "${DEVEL_RELEASE-}" = 1 ]; then
	./use-mpv-master
else
	./use-mpv-release
fi

echo "--enable-libdav1d"       >> ./ffmpeg_options
echo "--enable-small"          >> ./ffmpeg_options
echo "--disable-gnutls"        >> ./ffmpeg_options
echo "--enable-openssl"        >> ./ffmpeg_options
echo "--enable-version3"       >> ./ffmpeg_options
echo "--disable-librsvg"       >> ./ffmpeg_options
echo "--disable-programs"      >> ./ffmpeg_options
echo "--disable-encoders"      >> ./ffmpeg_options
echo "--enable-encoder=rawvideo" >> ./ffmpeg_options
echo "--enable-encoder=png"    >> ./ffmpeg_options
echo "--disable-muxers"        >> ./ffmpeg_options
echo "--enable-muxer=mp4"      >> ./ffmpeg_options
echo "--enable-muxer=matroska" >> ./ffmpeg_options
echo "--enable-muxer=webm"     >> ./ffmpeg_options
echo "--enable-muxer=image2"   >> ./ffmpeg_options
echo "--disable-avdevice"      >> ./ffmpeg_options
echo "-Dlibmpv=false"          >> ./mpv_options
echo "-Dlibbluray=disabled"    >> ./mpv_options
echo "-Dvapoursynth=disabled"  >> ./mpv_options
echo "-Dpipewire=disabled"     >> ./mpv_options
echo "-Drubberband=disabled"   >> ./mpv_options
echo "-Dlibavdevice=disabled"  >> ./mpv_options

# install in /usr rather than /usr/local
sed -i -e 's|meson setup build|meson setup build --prefix=/usr|' ./scripts/mpv-config

# Same as ./rebuild, with the ffmpeg sources patched in between.
# --enable-small makes ffmpeg drop the codec names (codec_desc.c) and the
# profile names (profiles.c), so mpv prints no codec and no "HW:" line in its
# stats overlay, which looks like hardware decoding is off.
# codec_desc.c refers to the tables of profiles.c, so both need the patch.
export LC_ALL=C
./update
sed -i 's/NULL_IF_CONFIG_SMALL(\(.*\)),$/\1,/' ./ffmpeg/libavcodec/codec_desc.c
sed -i 's/^#if !CONFIG_SMALL$/#if 1/' ./ffmpeg/libavcodec/profiles.c
./clean
./build -j$(nproc)
sudo ./install
/usr/bin/mpv --version | awk '{print $2; exit}' > ~/version

echo "All done!"
echo "---------------------------------------------------------------"
