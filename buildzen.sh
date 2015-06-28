cp /boot/config-`uname -r` .config
make oldconfig
#make menuconfig
sed -i 's/-O2/-O3 -fgraphite -fgraphite-identity -floop-parallelize-all -floop-interchange -ftree-loop-distribution -floop-strip-mine -floop-block -ftree-vectorize/g' Makefile
time make-kpkg -j4 --initrd --rootcmd fakeroot kernel_image kernel_headers modules_image
