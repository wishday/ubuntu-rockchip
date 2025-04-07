#!/bin/bash

set -eE 
trap 'echo Error: in $0 on line $LINENO' ERR

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

cd "$(dirname -- "$(readlink -f -- "$0")")" && cd ..
mkdir -p build && cd build

if [[ -z ${UBOOT_PACKAGE} ]]; then
    echo "Error: UBOOT_PACKAGE is not set"
    exit 1
fi

if [ ! -d "${UBOOT_PACKAGE}" ]; then
    # shellcheck source=/dev/null
    source ../packages/"${UBOOT_PACKAGE}"/debian/upstream
    git clone --single-branch --progress -b "${BRANCH}" "${GIT}" "${UBOOT_PACKAGE}"
    git -C "${UBOOT_PACKAGE}" checkout "${COMMIT}"
    echo 24
    cp -r ../packages/"${UBOOT_PACKAGE}"/debian "${UBOOT_PACKAGE}"
    echo 26
    # copy customed uboot_defconfig
    cp ../packages/"${UBOOT_PACKAGE}"/debian/smart-am60-rk3588_defconfig "${UBOOT_PACKAGE}"/configs
    echo 29

fi
cd "${UBOOT_PACKAGE}"

# Target package to build
rules=${UBOOT_RULES_TARGET},package-${UBOOT_RULES_TARGET}
if [[ -n ${UBOOT_RULES_TARGET_EXTRA} ]]; then
    rules=${UBOOT_RULES_TARGET_EXTRA},${rules}
fi

# Compile u-boot into a deb package
dpkg-source --before-build .
dpkg-buildpackage -a "$(cat debian/arch)" -d -b -nc -uc --rules-target="${rules}"
dpkg-source --after-build .

rm -f ../*.buildinfo ../*.changes
