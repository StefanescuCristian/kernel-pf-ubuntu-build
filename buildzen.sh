make mrproper
cp /boot/config-`uname -r` .config
make oldconfig
#make menuconfig
sed -i 's/-O2/-Ofast -fgraphite -fgraphite-identity -floop-parallelize-all -floop-interchange -ftree-loop-distribution -floop-strip-mine -floop-block -ftree-vectorize -floop-nest-optimize -fgcse -fgcse-lm -fgcse-sm -fgcse-las -fgcse-after-reload -march=native/g' Makefile
time make-kpkg -j4 --initrd --rootcmd fakeroot kernel_image kernel_headers modules_image
