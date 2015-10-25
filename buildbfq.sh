#!/bin/bash
. ./functions.h #include functions

#http://viajemotu.wordpress.com/2012/08/13/kernel-ck-for-ubuntu-precise/
#https://github.com/chilicuil/learn/blob/master/sh/is/kernel-ck-ubuntu

# $ time sh kernel-ck-ubuntu

#####################################
#kernel version base
kernel="4.2"
#kernel specific version
patchkernel="4.2.4"
#BFQ patch
bfq="4.2.0-v7r9"
#####################################

################################################################################
############DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING#################
################################################################################

trap _cleanup SIGINT SIGTERM #trap ctrl-c

#/tmp partition could have noexec
tmp_path="${HOME}/.tmp/kernel-ubuntu-${patchkernel}"
curr_path="${PWD}"
vbfq="$(printf "%s" "${bfq}" | cut -d'-' -f2)"

_header
_getroot

_printfl "Downloading archives"
_printfs "downloading main vanilla kernel tree ..."
_cmd     mkdir -p "${tmp_path}"
_cmd     cd "${tmp_path}"
_waitfor wget --no-check-certificate -N http://www.kernel.org/pub/linux/kernel/v4.x/linux-"${kernel}".tar.gz
[ ! -f linux-"${kernel}".tar.gz ] && _die "couldn't get http://www.kernel.org/pub/linux/kernel/v4.x/linux-${kernel}.tar.gz"

if [ "$patchkernel" != 0 ]; then
_printfs "downloading mainstream patches ..."
_waitfor wget --no-check-certificate -N http://www.kernel.org/pub/linux/kernel/v4.x/patch-"${patchkernel}".gz
[ ! -f patch-"${patchkernel}".gz ] && _die "couldn't get http://www.kernel.org/pub/linux/kernel/v4.x/patch-${patchkernel}.gz"
fi;

_printfl "downloading bfq patches ..."
_waitfor wget -N "http://algo.ing.unimo.it/people/paolo/disk_sched/patches/${bfq}/0001-block-cgroups-kconfig-build-bits-for-BFQ-${vbfq}-${kernel}.patch"
[ ! -f "0001-block-cgroups-kconfig-build-bits-for-BFQ-${vbfq}-${kernel}.patch" ] && \
    _die "couldn't get http://algo.ing.unimo.it/people/paolo/disk_sched/patches/${bfq}/0001-block-cgroups-kconfig-build-bits-for-BFQ-${vbfq}-${kernel}.patch"
_waitfor wget -N "http://algo.ing.unimo.it/people/paolo/disk_sched/patches/${bfq}/0002-block-introduce-the-BFQ-${vbfq}-I-O-sched-for-${kernel}.patch"
[ ! -f "0002-block-introduce-the-BFQ-${vbfq}-I-O-sched-for-${kernel}.patch" ] && \
    _die "couldn't get http://algo.ing.unimo.it/people/paolo/disk_sched/patches/${bfq}/0002-block-introduce-the-BFQ-${vbfq}-I-O-sched-for-${kernel}.patch"
_waitfor wget -N "http://algo.ing.unimo.it/people/paolo/disk_sched/patches/${bfq}/0003-block-bfq-add-Early-Queue-Merge-EQM-to-BFQ-${vbfq}-for-${kernel}.0.patch"
[ ! -f "0003-block-bfq-add-Early-Queue-Merge-EQM-to-BFQ-${vbfq}-for-${kernel}.0.patch" ] && \
    _die "couldn't get http://algo.ing.unimo.it/people/paolo/disk_sched/patches/${bfq}/0003-block-bfq-add-Early-Queue-Merge-EQM-to-BFQ-${vbfq}-for-${kernel}.0.patch"
_waitfor wget -N "https://raw.githubusercontent.com/graysky2/kernel_gcc_patch/master/enable_additional_cpu_optimizations_for_gcc_v4.9%2B_kernel_v3.15%2B.patch"

_printfl "Applying patches"
_printfs "uncompresing kernel to ${tmp_path}/linux-${kernel}/ ..."
if [ ! -d "/${tmp_path}/linux-${kernel}/" ]; then
    _waitfor tar zxf "${tmp_path}/linux-${kernel}.tar.gz"
    [ ! -d "${tmp_path}/linux-${kernel}" ] && _die "couldn't unpack ${tmp_path}/linux-${kernel}.tar.gz"
fi

if [ "$patchkernel" != 0 ]; then
_printfs "uncompresing patches ..."
_waitfor gunzip  patch-"${patchkernel}".gz; [ ! -f patch-"${patchkernel}" ] && _die "couldn't unpack patch-${patchkernel}.gz"
fi

_printfs "moving to ${tmp_path}/linux-${patchkernel}-${bfq}"
_waitfor sudo rm -rf "linux-${patchkernel}-${bfq}"
_waitfor cp -R --  linux-"${kernel}" "linux-${patchkernel}-${bfq}"
_cmd     cd "linux-${patchkernel}-${bfq}"

_printfs "applying patches ..."
if [ "$patchkernel" != 0 ]; then _cmd     "patch -p1 < ../patch-${patchkernel}"; fi
_cmd     "patch -p1 < ../0001-block-cgroups-kconfig-build-bits-for-BFQ-${vbfq}-${kernel}.patch"
_cmd     "patch -p1 < ../0002-block-introduce-the-BFQ-${vbfq}-I-O-sched-for-${kernel}.patch"
_cmd     "patch -p1 < ../0003-block-bfq-add-Early-Queue-Merge-EQM-to-BFQ-${vbfq}-for-${kernel}.0.patch"
_cmd	 "sed -i 's/-O2/-Ofast -fgraphite -fgraphite-identity -floop-parallelize-all -floop-interchange -ftree-loop-distribution -floop-strip-mine -floop-block -ftree-vectorize -floop-nest-optimize -fgcse -fgcse-lm -fgcse-sm -fgcse-las -fgcse-after-reload -march=native/g' Makefile"
_cmd	 "patch -p1 < ../enable_additional_cpu_optimizations_for_gcc_v4.9+_kernel_v3.15+.patch"
make mrproper
cp /boot/config-4.2.3-040203-generic .config
make oldconfig
#make menuconfig
time make-kpkg -j5 --initrd --rootcmd fakeroot kernel_image kernel_headers modules_image

_printfl "DONE"
_printfs "copying debs files ..."
_cmd     cp -- ../linux-*.deb "${curr_path}"
_printfs "you may want to install the generated packages and reboot your system, run: $ sudo dpkg -i linux-*.deb"
_printfs "have fun ^_^!"
