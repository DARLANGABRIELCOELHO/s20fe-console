#!/system/bin/sh
# s20fe: deixa o Android iniciar com a placa SEM A TELA conectada (placa fora do chassi).
#
# Problema: o manifesto do vendor declara interfaces de HALs do LineageOS que só são registradas
# quando o painel existe, e o system_server espera por elas para sempre no boot (watchdog em loop):
#  - vendor.lineage.touch: IGloveMode, IHighTouchPollingRate, ITouchscreenGesture
#    (o serviço só registra se /sys/class/sec/tsp/cmd_list listar os comandos);
#  - vendor.lineage.livedisplay: IDisplayColorCalibration, IDisplayModes, ISunlightEnhancement
#    (o serviço só registra se existir /sys/class/mdnie/mdnie/{sensorRGB,mode,outdoor}).
# Solução sem gravar nada no sistema: uma 2ª cópia de cada serviço OFICIAL (binários do vendor, sem
# alteração) roda num espaço de montagem próprio, onde um tmpfs cobre o diretório do /sys com
# arquivos falsos. Só esses processos veem o tmpfs (montagens privadas, conferido antes de montar).
# O que o Android mandar para esses recursos (luva, polling alto, modos de cor) cai em arquivos sem efeito.
# Com a tela conectada, os arquivos reais existem e o script não faz nada.
# Log: /data/local/tmp/s20fe-semtela.log

LOG=/data/local/tmp/s20fe-semtela.log
B=/data/adb/magisk/busybox
log() { echo "$(date '+%F %T') $*" >> $LOG; }

# roda "$2" (binário) com um tmpfs sobre "$1", preenchido pelo trecho de shell "$3"
isolado() {
    $B unshare -m --propagation private sh -c '
        # segurança: o /sys tem que estar privado aqui dentro, senão o tmpfs vazaria para o sistema
        if grep -E "^[0-9]+ [0-9]+ [0-9:]+ [^ ]+ /sys(/[^ ]*)? .* shared:" /proc/self/mountinfo; then exit 11; fi
        '"$B"' mount -t tmpfs -o mode=0755 s20fe_semtela '"$1"' || exit 12
        '"$3"'
        exec '"$2"'
    ' >> $LOG 2>&1 &
}

conta() { pidof "$1" | wc -w; }

TOUCH=/vendor/bin/hw/vendor.lineage.touch-service.samsung
if [ -e /sys/class/sec/tsp/cmd_list ]; then
    log "touchscreen presente: serviço de toque oficial basta"
elif [ "$(conta vendor.lineage.touch-service.samsung)" -ge 2 ]; then
    log "toque: cópia já rodando"
else
    log "sem touchscreen: iniciando cópia do serviço de toque"
    isolado /sys/class/sec $TOUCH '
        mkdir /sys/class/sec/tsp
        printf "glove_mode\nset_scan_rate\nsingletap_enable\n" > /sys/class/sec/tsp/cmd_list
        : > /sys/class/sec/tsp/cmd; : > /sys/class/sec/tsp/cmd_result
        chmod 0666 /sys/class/sec/tsp/cmd /sys/class/sec/tsp/cmd_result'
fi

LIVE=/vendor/bin/hw/vendor.lineage.livedisplay-service.samsung-qcom
if [ -e /sys/class/mdnie/mdnie/mode ]; then
    log "mdnie presente: LiveDisplay oficial basta"
elif [ "$(conta vendor.lineage.livedisplay-service.samsung-qcom)" -ge 2 ]; then
    log "LiveDisplay: cópia já rodando"
else
    log "sem mdnie: iniciando cópia do LiveDisplay"
    # tmpfs sobre /sys/class inteiro: o AdaptiveBacklight (/sys/class/lcd/panel) fica escondido e
    # a cópia não tenta registrá-lo de novo (o oficial já registrou)
    isolado /sys/class $LIVE '
        mkdir -p /sys/class/mdnie/mdnie
        echo 0 > /sys/class/mdnie/mdnie/mode
        echo 6 > /sys/class/mdnie/mdnie/mode_max
        echo "255 255 255" > /sys/class/mdnie/mdnie/sensorRGB
        echo 0 > /sys/class/mdnie/mdnie/outdoor
        chmod 0666 /sys/class/mdnie/mdnie/*'
fi
