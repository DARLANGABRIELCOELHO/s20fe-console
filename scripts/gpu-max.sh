#!/system/bin/sh
# s20fe: limite máximo da GPU no boot (Hz). Subir só depois de testar estabilidade.
# Níveis: 670000000 625000000 587000000 (fábrica) ...
# 625 MHz: estável em 20 min de Wild Life Extreme Stress (2026-10-12), sem cooler pico de 96 °C. 670 ainda não testado.
MAX=625000000
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
echo $MAX > /sys/class/kgsl/kgsl-3d0/max_gpuclk
log -t s20fe "gpu max: $(cat /sys/class/kgsl/kgsl-3d0/max_gpuclk)"
