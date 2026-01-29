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
quick-sharun /PATH/TO/BINARY_AND_LIBRARIES_HERE

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage
