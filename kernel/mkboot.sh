#!/bin/bash
# Uso: ./mkboot.sh <out-nome> <imagem-saida>
# Monta um boot.img = kernel de out-<nome> + ramdisk/DTB do boot do Magisk + rodapé AVB do boot do Magisk.
# Se existir out-<nome>/s20fe-dtb.img, usa esse DTB no lugar do DTB do Magisk.
set -euo pipefail
B="$HOME/s20fe-build"; T="$B/tools/mkbootimg"; P="$B/pieces/magisk"; M="$B/backup-celular/boot-magisk-2026-10-12.img"
K="$B/out-$1/arch/arm64/boot/Image"; OUT="$2"; TMP=$(mktemp -d)
D="$P/dtb"; [ -f "$B/out-$1/s20fe-dtb.img" ] && D="$B/out-$1/s20fe-dtb.img"; echo "DTB: $D"
CMD='androidboot.hardware=qcom androidboot.memcg=1 androidboot.usbcontroller=a600000.dwc3 console=null firmware_class.path=/vendor/firmware_mnt/image loop.max_part=7 lpm_levels.sleep_disabled=1 msm_rtb.filter=0x237 printk.devkmsg=on service_locator.enable=1 swiotlb=2048'
python3 "$T/mkbootimg.py" --header_version 2 --os_version 16.0.0 --os_patch_level 2026-10 \
  --kernel "$K" --ramdisk "$P/ramdisk" --dtb "$D" --pagesize 0x1000 --base 0 --kernel_offset 0x8000 \
  --ramdisk_offset 0x01000000 --second_offset 0 --tags_offset 0x100 --dtb_offset 0x01f00000 --board '' \
  --cmdline "$CMD" -o "$TMP/payload.img"
N=$(stat -c %s "$TMP/payload.img")
{ cat "$TMP/payload.img"; tail -c +$((N+1)) "$M"; } > "$OUT"
python3 "$T/unpack_bootimg.py" --boot_img "$OUT" --out "$TMP/v" >/dev/null
cmp "$TMP/v/kernel" "$K"; cmp "$TMP/v/ramdisk" "$P/ramdisk"; cmp "$TMP/v/dtb" "$D"
[ "$(stat -c %s "$OUT")" = 67108864 ]
rm -rf "$TMP"
(cd "$(dirname "$OUT")" && sha256sum "$(basename "$OUT")" | tee "$(basename "$OUT").sha256")
