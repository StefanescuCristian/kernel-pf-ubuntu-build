#!/bin/bash
# © Stefanescu Cristian 2014
# This bash script checks the last kernel version available from Ubuntu mainline PPA
# and downloads the debs so you can install them easier.
# It's a stupid description and I'll probably change it in the near future.


ARCH=`dpkg --print-architecture`
URL="http://kernel.ubuntu.com/~kernel-ppa/mainline"
TEMP="/tmp/mainline.html"
STRIP="/tmp/mainline.strip"
SORTED="/tmp/mainline.sort"
KVPAGE="/tmp/kver.html"

# download and save the mainpage to a temporary location
echo "Downloading URL"
wget "$URL" -O "$TEMP" > /dev/null 2>&1

# get rid of html tags, print the first column and sort it in reverse
sed 's/<[^>]\+>/ /g' -i "$TEMP"; awk '{print $1}' "$TEMP" > "$STRIP"; sort -rV "$STRIP" > "$SORTED"

# stable or rc?
# grep for rc if the user wants an rc version, exclude rc from searching if the user wants a stable version
# store the lines in an array, but no more then 10 kernel versions
# You can set the number of kernel versions in head -n10, but since we want the latest kernel, only 10 versions are fine
read -p "Do you want to install a stable version? [Y/n]
" kver
if [[ $kver == [Yy] || $kver == "" ]]; then
    ver_arr=( $(grep -v "rc" "$SORTED" | head -n10 | awk '{for (f = 1; f <= NF; f++) { a[NR, f] = $f } } NF > nf { nf = NF } END { for (f = 1; f <= nf; f++) { for (r = 1; r <= NR; r++) { printf a[r, f] (r==NR ? RS : FS) } } }') ) 
else
    ver_arr=( $(grep "rc" "$SORTED" | head -n10 | awk '{for (f = 1; f <= NF; f++) { a[NR, f] = $f } } NF > nf { nf = NF } END { for (f = 1; f <= nf; f++) { for (r = 1; r <= NR; r++) { printf a[r, f] (r==NR ? RS : FS) } } }') )
fi
# the following code depends on the previous answer, because we use the same array for each case (stable/rc)
# present the array in a friendly way so we can choose a number for a kernel version, if we don't want the latest kernel
echo "Select the version you want to install (Default is the latest, [0])"
for i in $(seq 0 $((${#ver_arr[@]} - 1))); do
	line="${ver_arr[$i]}"
	echo "[$i]. ${line}"
done

read -p "Enter the number correpsonding to the kernel version you want installed
" v
if [[ $v == "" ]]; then
	ver_id=$(echo ${ver_arr[0]} | awk '{ print $NF }')
else ver_id=$(echo ${ver_arr[$v]} | awk '{ print $NF }')
fi

# get the kernel's version page, so we can build the download links from the html
# save it as $KVPAGE
# grep through $KVPAGE for a generic or a lowlatency kernel
# grep for the headers
wget  "$URL/$ver_id" -O "$KVPAGE" > /dev/null 2>&1

read -p "Do you want a lowlatency kernel? [N/y]
" latency
if [[ $latency == [Yy] ]]; then
	KERNEL=`grep -E "href.*image.*$ARCH.*latency.*deb" $KVPAGE | sed 's/<[^>]\+>/ /g' | sed 's/&nbsp;//g' |awk '{print $1}' | tail -n1`
	KERNELM=`grep -E "href.*modules.*$ARCH.*latency.*deb" $KVPAGE | sed 's/<[^>]\+>/ /g' | sed 's/&nbsp;//g' |awk '{print $1}' | tail -n1`
else KERNEL=`grep -E "href.*image.*$ARCH.*generic.*deb" $KVPAGE | sed 's/<[^>]\+>/ /g' | sed 's/&nbsp;//g' | awk '{print $1}' | tail -n1`
       	KERNELM=`grep -E "href.*modules.*$ARCH.*generic.*deb" $KVPAGE | sed 's/<[^>]\+>/ /g' | sed 's/&nbsp;//g' | awk '{print $1}' | tail -n1`
fi

read -p "Download headers? [Y/n]
" headers
if [[ $headers == [Yy] || $headers == "" ]] && [[ $latency == [Yy] ]]; then
	HEADERS=`grep -E "href.*headers.*$ARCH.*latency.*deb" $KVPAGE | sed 's/<[^>]\+>/ /g' | sed 's/&nbsp;//g' |awk '{print $1}' | tail -n1`
else HEADERS=`grep -E "href.*headers.*$ARCH.*generic.*deb" $KVPAGE | sed 's/<[^>]\+>/ /g' | sed 's/&nbsp;//g' |awk '{print $1}' | tail -n1`
fi

echo "Downloading the files"
cd /tmp
axel -c -n10 "$URL"/"$ver_id"/"$KERNEL"
axel -c -n10 "$URL"/"$ver_id"/"$KERNELM"
if [[ $headers == [Yy] || $headers == "" ]]; then
	HEADERS_ALL=`grep -E "href.*headers.*all.*deb" $KVPAGE | sed 's/<[^>]\+>/ /g' | sed 's/&nbsp;//g' | awk '{print $1}' | tail -n1`
	axel -c -n10 "$URL"/"$ver_id"/"$HEADERS"
	axel -c -n10 "$URL"/"$ver_id"/"$HEADERS_ALL" 
fi

#strip ARCH from the ARCH/linux-*

K=`echo $KERNEL | sed "s,$ARCH/,,g"`
KM=`echo $KERNELM | sed "s,$ARCH/,,g"`
KH=`echo $HEADERS | sed "s,$ARCH/,,g"`
KHA=`echo $HEADERS_ALL | sed "s,$ARCH/,,g"`

read -p "Install the mthrf0cker? [Y/n]
" install
if [[ $install == [Yy] || $install == "" ]]; then 
	if [[ $headers == [Yy] || $headers == "" ]]; then
		sudo dpkg -i $KHA $KH
	fi
	sudo dpkg -i $K $KM
fi

read -p "Delete the *.deb files? [Y/n]
" deb
if [[ $deb == [Yy] || $deb == "" ]]; then
       rm -v $K
       if [[ -e $HEADERS ]]; then
               rm -v $KHA $KH
       fi
fi

#cleanup
rm $TEMP $STRIP $SORTED $KVPAGE
unset ver_arr 
