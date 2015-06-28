cp /boot/config-`uname -r` .config
make oldconfig
#make menuconfig
time make-kpkg -j4 --initrd --rootcmd fakeroot kernel_image kernel_headers modules_image
