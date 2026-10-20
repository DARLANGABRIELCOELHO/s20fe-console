#!/system/bin/sh
# s20fe: registrador térmico para os testes de resfriamento (hardware/README.md, seção 7).
# Roda como root, sozinho, sem depender do adb: no teste a USB-C fica no hub, longe do PC.
# Grava a cada 2 s: clocks e uso da GPU, CPU, temperaturas (SoC, pele, USB, bateria), bateria
# (carga, corrente, tensão) e tela, em /storage/emulated/0/Games/.perf/termico-<data>-<rotulo>.csv
#
# Uso:  thermlog.sh <rotulo> [minutos=40] [gpu_max_mhz]
#   gpu_max_mhz (ex.: 670): sobe o teto da GPU durante o teste e devolve o anterior no fim.
#   O controle térmico do Android (thermal-engine) continua ativo, como sempre.
# Parar antes:  touch /data/local/tmp/thermlog.stop
# Em execução:  /data/local/tmp/thermlog.pid (o caminho do CSV fica em thermlog.csv)
# Instalado em /data/adb/s20fe/bin/ (não fica no service.d: só roda quando chamado).

RUN=/data/local/tmp
OUT=/storage/emulated/0/Games/.perf
T=/sys/class/thermal
K=/sys/class/kgsl/kgsl-3d0
B=/sys/class/power_supply/battery
CPU=/sys/devices/system/cpu/cpufreq
INTERVAL=2

LABEL=$(printf %s "${1:-teste}" | tr -c 'A-Za-z0-9_-' '_')
MIN=${2:-40}
GPU_MAX=${3:-}

case "$MIN" in ''|*[!0-9]*) echo "minutos deve ser um inteiro entre 1 e 180" >&2; exit 2 ;; esac
[ "$MIN" -ge 1 ] && [ "$MIN" -le 180 ] || { echo "minutos deve ser um inteiro entre 1 e 180" >&2; exit 2; }
if [ -n "$GPU_MAX" ]; then
    case "$GPU_MAX" in *[!0-9]*) echo "teto da GPU deve ser entre 305 e 670 MHz" >&2; exit 2 ;; esac
    [ "$GPU_MAX" -ge 305 ] && [ "$GPU_MAX" -le 670 ] || { echo "teto da GPU deve ser entre 305 e 670 MHz" >&2; exit 2; }
fi

[ -f $RUN/thermlog.pid ] && kill -0 "$(cat $RUN/thermlog.pid)" 2>/dev/null && { echo "já está rodando (pid $(cat $RUN/thermlog.pid))"; exit 1; }
echo $$ > $RUN/thermlog.pid
rm -f $RUN/thermlog.stop

# Zona térmica pelo nome (os números podem mudar entre versões do kernel); mapa lido uma vez só
ZMAP=$(for z in $T/thermal_zone*; do echo "$(cat $z/type) $z"; done)
zone() { p=$(echo "$ZMAP" | grep -m1 "^$1 " | cut -d' ' -f2); if [ -n "$p" ]; then echo $p/temp; else echo /dev/null; fi; }
# miligraus -> "41.6"; vazio se a leitura falhar
c() { v=$(cat $1 2>/dev/null); [ -n "$v" ] && echo "$((v/1000)).$(((v%1000)/100))"; }
mhz() { echo $(( $(cat $1) / 1000 )); }          # cpufreq em kHz
ghz() { echo $(( $(cat $1) / 1000000 )); }       # kgsl em Hz

Z_CPU0=$(zone cpuss-0-usr); Z_CPU1=$(zone cpuss-1-usr)
Z_GPU0=$(zone gpuss-0-usr); Z_GPU1=$(zone gpuss-1-usr)
Z_DDR=$(zone ddr-usr); Z_PELE=$(zone modem-skin-usr); Z_AMB=$(zone modem-ambient-usr)
Z_USB=$(zone usb-therm); Z_AC=$(zone ac)

# ventoinha (scripts/fanctl.sh): "<epoch> <pedido> <aplicado> <rpm> <dissipador> <pico> <modo>";
# vazio se o arquivo tiver mais de 10 s (serviço parado ou Pico desligado)
FAN=$RUN/s20fe-fan.txt
fan() {
    [ -f $FAN ] && read ts _p ap rpm dis _t modo < $FAN && [ $(( $(date +%s) - ts )) -le 10 ] \
        && echo "$ap,${rpm#-},${dis#-},$modo" || echo ",,,"
}

taskset -p 0f $$ >/dev/null 2>&1      # fica nos núcleos pequenos, longe da carga do teste

mkdir -p $OUT
CSV="$OUT/termico-$(date +%Y%m%d-%H%M%S)-$LABEL.csv"
echo "$CSV" > $RUN/thermlog.csv

OLD_MAX=$(cat $K/max_gpuclk)
restore() {
    [ -n "$GPU_MAX" ] && echo $OLD_MAX > $K/max_gpuclk
    rm -f $RUN/thermlog.pid
}
trap 'restore; exit 0' TERM INT
[ -n "$GPU_MAX" ] && echo $((GPU_MAX * 1000000)) > $K/max_gpuclk

{
    echo "# rotulo=$LABEL inicio=$(date '+%F %T') minutos=$MIN gpu_max=$(( $(cat $K/max_gpuclk) / 1000000 )) kernel=$(uname -r)"
    echo "seg,gpu_mhz,gpu_busy,gpu_max,cpu0_mhz,cpu4_mhz,cpu7_mhz,t_cpu0,t_cpu1,t_gpu0,t_gpu1,t_ddr,t_pele,t_amb,t_usb,t_ac,t_bat,bat_pct,bat_ma,bat_mv,status,tela,brilho,tv,fan_pct,fan_rpm,t_dissip,fan_modo"
} > "$CSV"

start=$(cut -d. -f1 /proc/uptime)
end=$((start + MIN * 60))
while :; do
    now=$(cut -d. -f1 /proc/uptime)
    [ $now -ge $end ] || [ -f $RUN/thermlog.stop ] && break
    echo "$((now - start)),$(ghz $K/gpuclk),$(cat $K/gpu_busy_percentage | tr -d ' %'),$(ghz $K/max_gpuclk),$(mhz $CPU/policy0/scaling_cur_freq),$(mhz $CPU/policy4/scaling_cur_freq),$(mhz $CPU/policy7/scaling_cur_freq),$(c $Z_CPU0),$(c $Z_CPU1),$(c $Z_GPU0),$(c $Z_GPU1),$(c $Z_DDR),$(c $Z_PELE),$(c $Z_AMB),$(c $Z_USB),$(c $Z_AC),$(echo "$(cat $B/temp)" | sed 's/.$/.&/'),$(cat $B/capacity),$(( $(cat $B/current_now) / 1000 )),$(( $(cat $B/voltage_now) / 1000 )),$(cat $B/status),$(cat /sys/class/drm/card0-DSI-1/dpms),$(cat /sys/class/backlight/panel0-backlight/brightness 2>/dev/null),$(cat /sys/class/drm/card0-DP-1/status),$(fan)" >> "$CSV"
    sleep $INTERVAL
done
echo "# fim=$(date '+%F %T')" >> "$CSV"
restore
