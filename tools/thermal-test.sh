#!/usr/bin/env bash
# Teste de resfriamento (hardware/README.md, seção 7), pelo PC.
#   tools/thermal-test.sh start <rotulo> [minutos=40] [gpu_max_mhz]   instala/confere e inicia
#   tools/thermal-test.sh status                                    mostra a última amostra
#   tools/thermal-test.sh stop                                      para antes do tempo
#   tools/thermal-test.sh pull [--sala 26] [--obs "..."]            baixa o último CSV e resume
# Depois do "start" o celular pode sair do PC e ir para o hub: o registrador roda sozinho.
# Os CSV ficam no celular em Games/.perf/ e no PC em hardware/medicoes/.
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."

if [ -x "/c/Program Files/platform-tools/adb.exe" ]; then ADB="/c/Program Files/platform-tools/adb.exe"; else ADB=adb; fi
adb() { "$ADB" -s RX8T10JEJXY "$@"; }
su_() { adb shell "su -c '$1'"; }
BIN=/data/adb/s20fe/bin/thermlog.sh
PY=python3; "$PY" -c 1 2>/dev/null || PY=python      # no Windows, python3 é o atalho da Store

case "${1:-}" in
start)
    [ -n "${2:-}" ] || { echo "falta o rótulo (ex.: A-ventoinha-frente)"; exit 1; }
    [[ "$2" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "rótulo: use apenas letras, números, hífen e sublinhado"; exit 1; }
    minutes=${3:-40}; gpu_max=${4:-}
    [[ "$minutes" =~ ^[0-9]+$ ]] && (( minutes >= 1 && minutes <= 180 )) ||
        { echo "minutos deve ser um inteiro entre 1 e 180"; exit 1; }
    if [ -n "$gpu_max" ]; then
        [[ "$gpu_max" =~ ^[0-9]+$ ]] && (( gpu_max >= 305 && gpu_max <= 670 )) ||
            { echo "teto da GPU deve ser entre 305 e 670 MHz"; exit 1; }
    fi
    local_hash=$(sha256sum scripts/thermlog.sh | cut -d' ' -f1)
    if [ "$(su_ "sha256sum $BIN 2>/dev/null" | cut -d' ' -f1)" != "$local_hash" ]; then
        adb push scripts/thermlog.sh /data/local/tmp/thermlog.sh >/dev/null
        su_ "cp /data/local/tmp/thermlog.sh $BIN; chmod 755 $BIN"
        [ "$(su_ "sha256sum $BIN" | cut -d' ' -f1)" = "$local_hash" ] || { echo "hash do script no celular não confere"; exit 1; }
        echo "script instalado e conferido ($local_hash)"
    fi
    su_ "setsid nohup $BIN $2 $minutes $gpu_max >/data/local/tmp/thermlog.out 2>&1 </dev/null &"
    sleep 4
    su_ "cat /data/local/tmp/thermlog.out; head -1 \$(cat /data/local/tmp/thermlog.csv); tail -1 \$(cat /data/local/tmp/thermlog.csv)"
    echo "Gravando. Pode desconectar do PC e ligar no hub."
    ;;
status)
    su_ "cat /data/local/tmp/thermlog.pid 2>/dev/null && echo rodando || echo parado; f=\$(cat /data/local/tmp/thermlog.csv); sed -n 2p \$f; tail -1 \$f"
    ;;
stop)
    su_ "touch /data/local/tmp/thermlog.stop"; sleep 4; "$0" status
    ;;
pull)
    shift
    f=$(su_ "cat /data/local/tmp/thermlog.csv" | tr -d '\r')
    mkdir -p hardware/medicoes
    adb pull "$f" hardware/medicoes/ >/dev/null 2>&1
    local_f="hardware/medicoes/$(basename "$f")"
    [ "$(sha256sum "$local_f" | cut -d' ' -f1)" = "$(su_ "sha256sum $f" | cut -d' ' -f1)" ] || { echo "hash do CSV não confere"; exit 1; }
    echo "$local_f"
    "$PY" -I tools/thermsum.py "$local_f" "$@"
    ;;
*)
    sed -n 2,7p "$0"; exit 1
    ;;
esac
