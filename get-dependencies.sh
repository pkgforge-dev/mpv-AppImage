#!/bin/sh

set -ex

sed -i 's/DownloadUser/#DownloadUser/g' /etc/pacman.conf

if [ "$(uname -m)" = 'x86_64' ]; then
	PKG_TYPE='x86_64.pkg.tar.zst'
else
	PKG_TYPE='aarch64.pkg.tar.xz'
fi
LIBXML_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/libxml2-iculess-$PKG_TYPE"
FFMPEG_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/ffmpeg-mini-$PKG_TYPE"
OPUS_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/opus-nano-$PKG_TYPE"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
  alsa-lib \
  base-devel \
  desktop-file-utils \
  ffmpeg \
  git \
  glibc \
  hicolor-icon-theme \
  jack \
  lcms2 \
  libarchive \
  libass \
  libbluray \
  libcdio \
  libcdio-paranoia \
  libdrm \
  libdvdnav \
  libdvdread \
  libegl \
  libgl \
  libglvnd \
  libjpeg-turbo \
  libplacebo \
  libpulse \
  libsixel \
  libva \
  libvdpau \
  libx11 \
  libxext \
  libxkbcommon \
  libxpresent \
  libxrandr \
  libxss \
  libxv \
  luajit \
  mesa \
  meson \
  nasm \
  patchelf \
  libpipewire \
  rubberband \
  openal \
  uchardet \
  vulkan-headers \
  vulkan-icd-loader \
  wayland \
  wayland-protocols \
  wget \
  xorg-server-xvfb \
  zlib \
  zsync

#if [ "$(uname -m)" = 'x86_64' ]; then
#	pacman -Syu --noconfirm vulkan-intel haskell-gnutls gcc13 svt-av1
#else
#	pacman -Syu --noconfirm vulkan-freedreno vulkan-panfrost
#fi

echo "Installing debloated pckages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$LIBXML_URL" -O ./libxml2-iculess.pkg.tar.zst
wget --retry-connrefused --tries=30 "$FFMPEG_URL" -O ./ffmpeg-mini.pkg.tar.zst
wget --retry-connrefused --tries=30 "$OPUS_URL" -O ./opus-nano.pkg.tar.zst
pacman -U --noconfirm ./*.pkg.tar.zst
rm -f ./*.pkg.tar.zst

# Remove vapoursynth since ffmpeg-mini doesn't link to it
pacman -Rsndd --noconfirm vapoursynth

echo "All done!"
echo "---------------------------------------------------------------"
