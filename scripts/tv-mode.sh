#!/system/bin/sh
# s20fe: adapta a imagem à TV/monitor conectado (roda como root pelo Magisk, service.d).
# O LineageOS espelha a tela do celular (20:9) na TV; numa TV 16:9 a imagem sairia menor, com
# faixas pretas. Com a TV conectada, a resolução lógica do celular passa a ter a proporção da TV
# (wm size 1080x<altura>, em retrato; deitado vira <largura>x1080), e o espelho ocupa a TV inteira.
# Na tela do próprio celular aparecem faixas pretas enquanto isso. Ao desconectar: wm size reset.
# A proporção vem do modo preferido da TV (1ª linha de /sys/class/drm/card0-DP-1/modes, do EDID).
# Para desligar: apagar este arquivo de /data/adb/service.d e rodar "wm size reset".
# Log: /data/local/tmp/s20fe-tv.log

DP=/sys/class/drm/card0-DP-1
LOG=/data/local/tmp/s20fe-tv.log
PANEL_W=1080                     # lado menor do painel (retrato 1080x2400)

log() { echo "$(date '+%F %T') $*" >> $LOG; }

apply_tv() {
    mode=$(head -1 $DP/modes 2>/dev/null)          # ex.: 1920x1080
    w=${mode%%x*}; h=${mode#*x}; h=${h%%[!0-9]*}
    case "$w$h" in ''|*[!0-9]*) w=1920; h=1080; log "modo da TV desconhecido ('$mode'), usando 16:9" ;; esac
    [ "$h" -gt "$w" ] && { t=$w; w=$h; h=$t; }      # sempre largura > altura
    long=$((PANEL_W * w / h))
    long=$((long / 2 * 2))                           # par, para não sobrar meia linha
    if [ $long -ge 2400 ]; then                      # TV mais larga que o celular: nada a fazer
        wm size reset; log "TV $mode (mais larga que o celular): tamanho normal"
    else
        wm size ${PANEL_W}x$long; log "TV $mode conectada: wm size ${PANEL_W}x$long"
    fi
}

if [ "$1" = apply ]; then apply_tv; exit; fi        # teste manual: sh tv-mode.sh apply

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
# o wm size sobrevive ao reinício: se desligou com a TV e ligou sem ela, volta ao normal
if [ "$(cat $DP/status 2>/dev/null)" != connected ] && wm size | grep -q "Override"; then
    wm size reset; log "boot sem TV: tamanho normal"
fi
last=""
while true; do
    st=$(cat $DP/status 2>/dev/null)
    if [ "$st" != "$last" ]; then
        if [ "$st" = connected ]; then
            sleep 2; apply_tv                        # dá tempo de o EDID ser lido
        elif [ -n "$last" ]; then
            wm size reset; log "TV desconectada: tamanho normal"
        fi
        last=$st
    fi
    sleep 2
done
