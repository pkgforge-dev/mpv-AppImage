#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DESKTOP=/usr/share/applications/mpv.desktop
export ICON=/usr/share/icons/hicolor/128x128/apps/mpv.png
export APPNAME=mpv
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1
export URUNTIME_PRELOAD=1

# Deploy dependencies
quick-sharun /usr/bin/mpv

# mpv only supports LC_NUMERIC=C or LC_NUMERIC=C.UTF-8
# https://github.com/mpv-player/mpv/blob/c41ee4b95fa8d9827be943247249eae56b372847/player/main.c#L248-L264
# so we cannot be relying on anylinux.so to set the locale to anything else
echo 'LC_NUMERIC=C.UTF-8' >> ./AppDir/.env

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage
