#!/bin/bash
#
# Copyright (c) 2017 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

cidir=$(dirname "$0")

echo "Add clear containers sources to apt list"
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/home:/clearlinux:/preview:/clear-containers-2.1/xUbuntu_16.10/ /' >> /etc/apt/sources.list.d/cc-oci-runtime.list"
curl -fsSL http://download.opensuse.org/repositories/home:clearlinux:preview:clear-containers-2.1/xUbuntu_16.10/Release.key | sudo apt-key add -

echo "Install clear containers dependencies"
sudo -E apt-get install -y libtool automake autotools-dev autoconf bc

echo "Install chronic"
sudo -E apt-get install -y moreutils

echo "Install rpm2cpio"
chronic sudo -E apt-get install -y rpm2cpio

echo "Update apt repositories"
chronic sudo -E apt-get update

echo "Install qemu-lite binary"
chronic sudo -E apt-get install -y --force-yes qemu-lite

echo "Install CRI-O dependencies"
sudo -E apt-get install -y libglib2.0-dev libseccomp-dev libapparmor-dev libgpgme11-dev

echo "Install libdevmapper"
devmapper_version="2.02.172"
curl -LOk ftp://sources.redhat.com/pub/lvm2/LVM2.${devmapper_version}.tgz
tar -xf LVM2.${devmapper_version}.tgz
pushd LVM2.${devmapper_version}/
./configure
make -j$(nproc) libdm
sudo -E PATH=$PATH sh -c "make libdm.install"
popd
rm -rf LVM2.${devmapper_version}/ LVM2.${devmapper_version}.tgz

echo "Install btrfs-tools"
sudo -E apt-get install -y asciidoc xmlto --no-install-recommends
sudo -E apt-get install -y uuid-dev libattr1-dev zlib1g-dev libacl1-dev e2fslibs-dev libblkid-dev liblzo2-dev
git clone http://git.kernel.org/pub/scm/linux/kernel/git/kdave/btrfs-progs.git
pushd btrfs-progs
./autogen.sh
./configure
make -j$(nproc) btrfs
sudo -E PATH=$PATH sh -c "make install btrfs"
popd

clear_release=$(curl -sL https://download.clearlinux.org/latest)
cc_img_path="/usr/share/clear-containers"

"${cidir}/install_clear_image.sh" ${clear_release} "${cc_img_path}"

bug_url="https://github.com/clearcontainers/runtime/issues/91"
kernel_clear_release=12760
kernel_version="4.5-50"
echo -e "\nWARNING:"
echo "WARNING: Using backlevel kernel version ${kernel_version} due to bug ${bug_url}"
echo -e "WARNING:\n"

"${cidir}/install_clear_kernel.sh" ${kernel_clear_release} ${kernel_version} "${cc_img_path}"

echo "Install bison binary"
chronic sudo -E apt-get install -y bison

echo "Install nsenter"
nsenter_version="2.30"
chronic sudo -E apt-get install -y autopoint
curl -LOk https://www.kernel.org/pub/linux/utils/util-linux/v${nsenter_version}/util-linux-${nsenter_version}.tar.xz
tar -xf util-linux-${nsenter_version}.tar.xz
pushd util-linux-${nsenter_version}/
./autogen.sh
./configure --without-python --disable-all-programs --enable-nsenter
make nsenter
sudo cp nsenter /usr/bin/
popd
rm -rf util-linux-${nsenter_version}/ util-linux-${nsenter_version}.tar.xz
