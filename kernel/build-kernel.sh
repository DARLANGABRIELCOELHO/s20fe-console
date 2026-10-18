#!/bin/bash
# Compila o kernel do LineageOS (r8q / sm8250) do mesmo jeito que o build oficial
# (vendor/lineage/build/tasks/kernel.mk + BoardConfigKernel.mk, lineage-23.2, TARGET_KERNEL_NO_GCC).
#
# Uso: ./build-kernel.sh [nome-da-saida] [jobs]
#   nome-da-saida: pasta em ~/s20fe-build/out-<nome> (padrão: ref)
#   jobs: processos paralelos do make (padrão: 8; com 8 GB de RAM não usar 16)
set -euo pipefail

BASE="$HOME/s20fe-build"
KSRC="$BASE/kernel"
CLANG="$BASE/clang-r563880c/bin"
OUT="$BASE/out-${1:-ref}"
JOBS="${2:-8}"

CONFIGS=(
    vendor/kona-perf_defconfig
    vendor/samsung/kona-sec-common.config
    vendor/samsung/r8q.config
)

export PATH="$CLANG:$PATH"
MAKE=(make -C "$KSRC" O="$OUT" ARCH=arm64 -j"$JOBS"
      CC=clang LD=ld.lld AR=llvm-ar LLVM=1 LLVM_IAS=1
      HOSTCC=clang HOSTCXX=clang++ HOSTLD=ld.lld HOSTAR=llvm-ar
      HOSTLDFLAGS="-fuse-ld=lld")

mkdir -p "$OUT"

# Mesma sequência do make-kernel-config do LineageOS
cp "$KSRC/arch/arm64/configs/${CONFIGS[0]}" "$OUT/.config"
"${MAKE[@]}" olddefconfig
for frag in "${CONFIGS[@]:1}"; do
    "$KSRC/scripts/kconfig/merge_config.sh" -m -O "$OUT" "$OUT/.config" \
        "$KSRC/arch/arm64/configs/$frag"
    "${MAKE[@]}" olddefconfig
done

"${MAKE[@]}" Image dtbs

ls -l "$OUT/arch/arm64/boot/Image"
sha256sum "$OUT/arch/arm64/boot/Image" | tee "$OUT/Image.sha256"
