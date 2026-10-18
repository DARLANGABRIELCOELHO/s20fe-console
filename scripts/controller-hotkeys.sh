#!/system/bin/sh
# s20fe: atalhos de saída iguais para qualquer controle (roda como root pelo Magisk, service.d).
#   Select + Start             -> volta ao menu (Home = Pegasus); o jogo fica pausado em segundo plano
#   LB + RB + Select + Start   -> fecha o app em primeiro plano e volta ao menu
# Também reinicia o Pegasus quando um controle novo conecta: o Qt Gamepad do Pegasus só enxerga
# os controles que existiam quando ele abriu (sem isso, só os direcionais funcionam).
# Funciona com qualquer controle porque lê, para cada controle conectado, o mesmo arquivo de mapa
# (.kl) que o Android usa (dumpsys input -> KeyLayoutFile). Controles conectados depois são
# detectados (o leitor é reiniciado quando aparece um dispositivo novo).
# Log: /data/local/tmp/s20fe-hotkeys.log

HOME_PKG=org.pegasus_frontend.android
LOG=/data/local/tmp/s20fe-hotkeys.log
MAP=/data/local/tmp/s20fe-hotkeys.map

log() { echo "$(date '+%F %T') $*" >> $LOG; }

action() {
    case "$1" in
    home)
        input keyevent KEYCODE_HOME
        log "home" ;;
    close)
        pkg=$(dumpsys activity activities | grep -m1 topResumedActivity | sed -E 's/.* u0 ([^/]+)\/.*/\1/')
        case "$pkg" in
        ""|"$HOME_PKG"|com.android.systemui|com.android.launcher3) log "close ignorado ($pkg)" ;;
        *) am force-stop "$pkg"; log "close $pkg" ;;
        esac
        input keyevent KEYCODE_HOME ;;
    restart-home)
        top=$(dumpsys activity activities | grep -m1 topResumedActivity)
        am force-stop $HOME_PKG
        case "$top" in
        *" $HOME_PKG/"*) sleep 1; monkey -p $HOME_PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
                         log "Pegasus reaberto (controle novo)" ;;
        *) log "Pegasus fechado em segundo plano (controle novo; reabre no Home)" ;;
        esac ;;
    esac
}

# "caminho arquivo.kl" de cada dispositivo que o Android classifica como GAMEPAD
build_map() {
    dumpsys input | awk '
        /^ +[0-9]+: / { path = ""; pad = 0 }
        /Classes:/ && /GAMEPAD/ { pad = 1 }
        /Path:/ { path = $2 }
        /KeyLayoutFile:/ { if (pad && path != "") print path, $2 }
    ' > $MAP
    ls /dev/input/event* > $MAP.all
}

if [ "$1" = action ]; then action "$2"; exit; fi

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
log "iniciado"
first=1
while true; do
    build_map
    log "controles: $(tr '\n' ';' < $MAP)"
    # controle novo (fora do boot): reiniciar o Pegasus para ele enxergar todos os botões
    new=$(cut -d' ' -f1 $MAP | sort)
    if [ $first = 0 ] && [ -n "$(echo "$new" | grep -vxF -f $MAP.pads 2>/dev/null)" ]; then
        sleep 1; action restart-home
    fi
    echo "$new" > $MAP.pads
    first=0
    # getevent sem -q: mostra "add device" quando um controle novo conecta; aí o awk sai e o mapa é refeito
    getevent 2>/dev/null | awk -v map="$MAP" -v self="$0" '
        BEGIN {
            while ((getline p < (map ".all")) > 0) known[p] = 1
            close(map ".all")
            while ((getline line < map) > 0) {
                split(line, f, " "); dev = f[1]
                while ((getline kl < f[2]) > 0) {
                    n = split(kl, k, /[ \t]+/)
                    if (k[1] != "key" || k[2] == "usage") continue
                    code = (k[2] ~ /^0x/) ? k[2] : sprintf("%04x", k[2] + 0)
                    sub(/^0x/, "", code); while (length(code) < 4) code = "0" code
                    role = ""
                    if (k[3] == "BUTTON_SELECT" || k[3] == "BACK") role = "S"
                    else if (k[3] == "BUTTON_START") role = "T"
                    else if (k[3] == "BUTTON_L1") role = "L"
                    else if (k[3] == "BUTTON_R1") role = "R"
                    if (role != "") roles[dev SUBSEP code] = role
                }
                close(f[2])
            }
            close(map)
        }
        /^add device/ { if (!($4 in known)) exit }          # dispositivo novo: refazer o mapa
        /^remove device/ { exit }                           # desconectou: refazer (religar conta como novo)
        /^\/dev\/input\/event/ {
            dev = $1; sub(/:$/, "", dev)
            if ($2 != "0001" || !((dev SUBSEP $3) in roles)) next
            r = roles[dev SUBSEP $3]
            down[dev, r] = ($4 != "00000000")
            both = down[dev, "S"] && down[dev, "T"]
            if (both && !fired[dev]) {
                fired[dev] = 1
                a = (down[dev, "L"] && down[dev, "R"]) ? "close" : "home"
                system("sh " self " action " a)
            } else if (!both) fired[dev] = 0
        }
    '
    sleep 2
done
