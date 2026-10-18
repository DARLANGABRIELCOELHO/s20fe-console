#!/system/bin/sh
# s20fe: zram com lz4 (mais rápido que lzo-rle) e 4 GB (folga para emulação de Switch;
# só ocupa RAM o que for usado, comprimido ~2,9x)
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
Z=/sys/block/zram0
SIZE=4294967296
grep -q '\[lz4\]' $Z/comp_algorithm && [ "$(cat $Z/disksize)" = "$SIZE" ] && exit 0
swapoff /dev/block/zram0 || exit 1
echo 1 > $Z/reset
echo lz4 > $Z/comp_algorithm
echo $SIZE > $Z/disksize
mkswap /dev/block/zram0 >/dev/null
swapon /dev/block/zram0
log -t s20fe "zram: $(cat $Z/comp_algorithm) $SIZE"
