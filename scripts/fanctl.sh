#!/system/bin/sh
# s20fe: ventoinha do console controlada pela temperatura (roda como root pelo Magisk, service.d).
# A ventoinha é comandada por um Raspberry Pi Pico 2 ligado numa USB-A do hub (firmware em
# hardware/cooler-pico/, montagem em hardware/README.md, seção 10). O Pico aparece como HID de
# fabricante "s20fe S20FE Fan" -> /dev/hidrawN (o kernel não tem CONFIG_USB_ACM, por isso não é
# porta serial). A cada 2 s este serviço:
#  1) lê o SoC (maior entre cpuss-0/1 e gpuss-0/1) e a bateria;
#  2) calcula a velocidade: SoC 50 °C -> MINIMO% ... 80 °C -> 100%; bateria 35 -> MINIMO ...
#     40 °C -> 100%; vale o maior. Sobe na hora, desce no máximo DESCE% por ciclo e só para
#     abaixo de (início - histerese), para não ficar liga/desliga;
#  3) manda "F <pct>" ao Pico e grava a resposta em /data/local/tmp/s20fe-fan.txt
#     (<epoch> <pedido> <aplicado> <rpm> <dissipador> <temp do Pico> <modo>), que o thermlog.sh lê.
# O Pico tem segurança própria: sem notícia do celular por 10 s, gira em 100% (ou pela curva do
# NTC). Isto NÃO substitui o controle térmico do Android (thermal-engine continua ativo).
#
# Uso:  fanctl.sh              laço (service.d; não abre duas vezes)
#       fanctl.sh teste        mostra as temperaturas, a velocidade calculada e a resposta do Pico
#       fanctl.sh fixo <pct>   força a velocidade (testes de medição); "fixo auto" volta à curva
# Log: /data/local/tmp/s20fe-fan.log

RUN=/data/local/tmp
LOG=$RUN/s20fe-fan.log
EST=$RUN/s20fe-fan.txt
FIXO=$RUN/s20fe-fan.fixo
PID=$RUN/s20fe-fan.pid
REL=$RUN/s20fe-fan.rel
NOME="S20FE Fan"
INTERVALO=2

MINIMO=30                 # mesmo valor do MINIMO do code.py
SOC_INI=50; SOC_FIM=80
BAT_INI=35; BAT_FIM=40
HIST_SOC=4; HIST_BAT=1    # só para abaixo de 46 °C (SoC) e 34 °C (bateria)
DESCE=5

T=/sys/class/thermal
log() { echo "$(date '+%F %T') $*" >> $LOG; }

ZMAP=$(for z in $T/thermal_zone*; do echo "$(cat $z/type) $z"; done)
zona() { echo "$ZMAP" | grep -m1 "^$1 " | cut -d' ' -f2; }
Z_SOC="$(zona cpuss-0-usr) $(zona cpuss-1-usr) $(zona gpuss-0-usr) $(zona gpuss-1-usr)"

soc() {   # maior temperatura do SoC, °C inteiro
    m=0
    for z in $Z_SOC; do
        v=$(cat $z/temp 2>/dev/null); v=$((${v:-0} / 1000))
        [ $v -gt $m ] && m=$v
    done
    echo $m
}
bateria() { echo $(( $(cat /sys/class/power_supply/battery/temp) / 10 )); }   # °C (o nó dá décimos)

curva() {   # valor início fim -> 0 abaixo do início, MINIMO..100 entre, 100 a partir do fim
    if [ $1 -lt $2 ]; then echo 0
    elif [ $1 -ge $3 ]; then echo 100
    else echo $(( MINIMO + ($1 - $2) * (100 - MINIMO) / ($3 - $2) )); fi
}

atual=0
calcular() {   # usa/atualiza $atual; deixa $s e $b para o registro
    s=$(soc); b=$(bateria)
    if [ -f $FIXO ]; then
        atual=$(cat $FIXO); return
    fi
    a=$(curva $s $SOC_INI $SOC_FIM); c=$(curva $b $BAT_INI $BAT_FIM)
    [ $c -gt $a ] && a=$c
    if [ $a -ge $atual ]; then
        atual=$a; return
    fi
    n=$(( atual - DESCE )); [ $n -lt $a ] && n=$a
    if [ $n -lt $MINIMO ]; then          # só acontece com a = 0: parar, ou segurar no mínimo
        if [ $s -lt $((SOC_INI - HIST_SOC)) ] && [ $b -lt $((BAT_INI - HIST_BAT)) ]; then n=0; else n=$MINIMO; fi
    fi
    atual=$n
}

achar() {   # /dev/hidrawN do Pico, ou vazio
    for h in /sys/class/hidraw/hidraw*; do
        grep -q "^HID_NAME=.*$NOME" $h/device/uevent 2>/dev/null && { echo /dev/${h##*/}; return; }
    done
}

# manda o pedido (1 write de 33 bytes = 1 relatório: ID 1 + 32 bytes) e lê a resposta (fd 3)
conversar() {
    printf '\001%-32.32s' "F $1" > $REL
    dd if=$REL bs=33 count=1 >&3 2>/dev/null || return 1
    timeout 1 dd bs=33 count=1 <&3 2>/dev/null | tr -d '\000\001' | tr -s ' '
}

case "$1" in
fixo)
    case "$2" in
    auto) rm -f $FIXO; echo "curva automática" ;;
    *[!0-9]*|'') echo "uso: fanctl.sh fixo <0-100>|auto" >&2; exit 2 ;;
    *) [ "$2" -le 100 ] || { echo "0 a 100" >&2; exit 2; }; echo "$2" > $FIXO; echo "fixo em $2%" ;;
    esac
    exit ;;
teste)
    calcular
    echo "SoC $s °C, bateria $b °C -> $atual%$( [ -f $FIXO ] && echo ' (fixo)')"
    d=$(achar)
    if [ -z "$d" ]; then echo "Pico não encontrado (nenhum hidraw com \"$NOME\")"; exit 1; fi
    if [ -f $PID ] && kill -0 "$(cat $PID)" 2>/dev/null; then
        echo "Pico em $d; o serviço está rodando: $(cat $EST 2>/dev/null)"; exit
    fi
    ( exec 3<>"$d" ) 2>/dev/null || { echo "não abriu $d"; exit 1; }
    exec 3<>"$d"; echo "Pico em $d: $(conversar $atual)"; exit ;;
esac

[ -f $PID ] && kill -0 "$(cat $PID)" 2>/dev/null && exit 0
echo $$ > $PID
taskset -p 0f $$ >/dev/null 2>&1      # núcleos pequenos

aberto=""
while true; do
    d=$(achar)
    if [ -z "$d" ]; then
        [ -n "$aberto" ] && { log "Pico desconectado"; exec 3<&-; aberto=""; }
        sleep 5; continue
    fi
    if [ "$d" != "$aberto" ]; then
        exec 3<&- 2>/dev/null
        # testa num subshell: falha de redirecionamento no "exec" encerraria o script
        ( exec 3<>"$d" ) 2>/dev/null || { sleep 5; continue; }
        exec 3<>"$d"; aberto=$d; log "Pico encontrado em $d"
    fi
    antes=$atual
    calcular
    r=$(conversar $atual) || { log "falha ao escrever em $d"; exec 3<&-; aberto=""; continue; }
    set -- $r
    if [ "$1" = S ]; then shift; else set -- - - - - -; fi
    echo "$(date +%s) $atual $*" > $EST
    [ $atual -ne $antes ] && log "SoC $s °C, bateria $b °C -> $atual% (Pico: $*)"
    sleep $INTERVALO
done
