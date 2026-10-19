#!/system/bin/sh
# s20fe: adapta a imagem à TV/monitor conectado (roda como root pelo Magisk, service.d).
# O LineageOS espelha a tela do celular (20:9) na TV. Com a TV conectada:
#  1) a resolução lógica do celular passa a ter a proporção da TV (wm size 1080x<altura>, em
#     retrato; deitado vira <largura>x1080), para o espelho ocupar a TV inteira;
#  2) o recorte da câmera é desligado: deitado, ele reserva uma faixa de 120 px (96 px em 16:9)
#     só de um lado, onde os apps não desenham, e a imagem saía deslocada na TV (2026-10-19).
#     Feito com 3 substituições de configuração do sistema criadas na hora ("cmd overlay
#     fabricate", sem gravar nada no sistema): config_mainBuiltInDisplayCutout e ...RectApproximation
#     = "M0,0Z" (caminho vazio) e config_fillMainBuiltInDisplayCutout = false. Valor de texto vazio
#     não funciona (o mapa da substituição fica vazio); precisa declarar o tipo "string".
# Na tela do próprio celular aparecem faixas pretas e o furo da câmera cobre um canto enquanto isso.
# Ao desconectar: tudo volta (wm size reset + substituições desligadas).
# A proporção vem do modo preferido da TV (1ª linha de /sys/class/drm/card0-DP-1/modes, do EDID).
# Para desligar o serviço: apagar este arquivo de /data/adb/service.d, rodar "wm size reset" e
# "cmd overlay disable com.android.shell:s20fe_rec_string" (e _aprox, _fill).
# Log: /data/local/tmp/s20fe-tv.log

DP=/sys/class/drm/card0-DP-1
LOG=/data/local/tmp/s20fe-tv.log
PANEL_W=1080                     # lado menor do painel (retrato 1080x2400)
OVERLAYS="s20fe_rec_string s20fe_rec_aprox s20fe_rec_fill"

log() { echo "$(date '+%F %T') $*" >> $LOG; }

# cria (ou recria) as substituições que tiram o recorte da câmera; ficam desligadas
criar_sem_recorte() {
    cmd overlay fabricate --target android --name s20fe_rec_string \
        android:string/config_mainBuiltInDisplayCutout string "M0,0Z" >/dev/null 2>&1
    cmd overlay fabricate --target android --name s20fe_rec_aprox \
        android:string/config_mainBuiltInDisplayCutoutRectApproximation string "M0,0Z" >/dev/null 2>&1
    cmd overlay fabricate --target android --name s20fe_rec_fill \
        android:bool/config_fillMainBuiltInDisplayCutout 0x12 0x0 >/dev/null 2>&1
}
recorte() {   # on = recorte normal (celular); off = sem recorte (TV)
    for o in $OVERLAYS; do
        if [ "$1" = off ]; then cmd overlay enable com.android.shell:$o; else cmd overlay disable com.android.shell:$o; fi
    done >/dev/null 2>&1
}

apply_tv() {
    mode=$(head -1 $DP/modes 2>/dev/null)          # ex.: 1920x1080
    w=${mode%%x*}; h=${mode#*x}; h=${h%%[!0-9]*}
    case "$w$h" in ''|*[!0-9]*) w=1920; h=1080; log "modo da TV desconhecido ('$mode'), usando 16:9" ;; esac
    [ "$h" -gt "$w" ] && { t=$w; w=$h; h=$t; }      # sempre largura > altura
    long=$((PANEL_W * w / h))
    long=$((long / 2 * 2))                           # par, para não sobrar meia linha
    recorte off
    if [ $long -ge 2400 ]; then                      # TV mais larga que o celular: só tira o recorte
        wm size reset; log "TV $mode (mais larga que o celular): tamanho normal, sem recorte"
    else
        wm size ${PANEL_W}x$long; log "TV $mode conectada: wm size ${PANEL_W}x$long, sem recorte"
    fi
}
# O Android só recalcula o recorte quando o tamanho da tela muda: primeiro religa o recorte, depois
# muda o tamanho (um ajuste de 2 px antes do reset garante a mudança mesmo sem override).
reset_tv() { recorte on; wm size ${PANEL_W}x2398; wm size reset; }

case "$1" in
apply) criar_sem_recorte; apply_tv; exit ;;     # teste manual: sh tv-mode.sh apply
reset) reset_tv; exit ;;                         #               sh tv-mode.sh reset
esac

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
criar_sem_recorte
# o wm size e as substituições sobrevivem ao reinício: se desligou com a TV e ligou sem ela, volta
if [ "$(cat $DP/status 2>/dev/null)" != connected ]; then
    reset_tv; log "boot sem TV: tamanho normal, recorte normal"
fi
last=""
while true; do
    st=$(cat $DP/status 2>/dev/null)
    if [ "$st" != "$last" ]; then
        if [ "$st" = connected ]; then
            sleep 2; apply_tv                        # dá tempo de o EDID ser lido
        elif [ -n "$last" ]; then
            reset_tv; log "TV desconectada: tamanho normal, recorte normal"
        fi
        last=$st
    fi
    sleep 2
done
