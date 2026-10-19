#!/system/bin/sh
# s20fe: atalhos iguais para qualquer controle (roda como root pelo Magisk, service.d).
#   Select + Start                    -> fecha o jogo atual (salvando o estado) e volta ao Pegasus
#   L1 + R1 (segurados) + Select+Start -> abre o menu/configurações do emulador (o jogo continua)
#   Botão PS / Home / Guide           -> "desliga" (apaga a tela, console em espera) e liga de novo;
#                                        com a tela apagada, qualquer botão do controle também liga
# Antes de fechar, salva o estado do jogo do jeito de cada emulador (PPSSPP: tecla F2 mapeada para
# "Save State"; RetroArch: sai pelo Esc, que grava o estado automático). Ao abrir, cada um carrega
# o último estado. Dolphin, Eden e outros: fechados direto (os jogos salvam no cartão de memória).
# Menu do emulador: BACK (NetherSX2, Dolphin, PPSSPP, Eden) ou F1 (RetroArch, input_menu_toggle).
# NetherSX2 (PS2): sai sempre pelo "Sair do jogo" do menu de pausa, que grava o
# <serial> (<CRC>).resume.p2s (EmuCore/SaveStateOnShutdown=true); o Pegasus abre o jogo com
# --es saveStatePath apontando para ele (tools/gen-pegasus.py). Não dá para deixar o NetherSX2
# pausado em segundo plano: abrir outro jogo com ele aberto deixa a tela preta (testado em
# 2026-10-19), e mesmo depois de sair o processo dele não abre um 2º jogo, por isso ele é
# fechado depois de salvar. O item do menu é achado pelo uiautomator (o foco inicial do menu
# varia, então setas não servem), e o subtítulo do menu dá o serial e o CRC do jogo.
# Também reinicia o Pegasus quando um controle novo conecta: o Qt Gamepad do Pegasus só enxerga
# os controles que existiam quando ele abriu (sem isso, só os direcionais funcionam).
# Funciona com qualquer controle porque lê, para cada controle conectado, o mesmo arquivo de mapa
# (.kl) que o Android usa (dumpsys input -> KeyLayoutFile). Controles conectados depois são
# detectados (o leitor é reiniciado quando aparece um dispositivo novo).
# Log: /data/local/tmp/s20fe-hotkeys.log

HOME_PKG=org.pegasus_frontend.android
NETHER_PKG=xyz.aethersx2.android
NETHER_STATES=/storage/emulated/0/Android/data/$NETHER_PKG/files/sstates
GAME_DIRS=/storage/emulated/0/pegasus-frontend/game_dirs.txt
LOG=/data/local/tmp/s20fe-hotkeys.log
MAP=/data/local/tmp/s20fe-hotkeys.map
UI=/data/local/tmp/s20fe-hotkeys-ui.xml

log() { echo "$(date '+%F %T') $*" >> $LOG; }

top_pkg() { dumpsys activity activities | grep -m1 topResumedActivity | sed -E 's/.* u0 ([^/]+)\/.*/\1/'; }

# NetherSX2: abre o menu de pausa e sai pelo "Sair do jogo" (grava o .resume.p2s).
# Devolve 0 se saiu e o estado foi gravado; 2 se, além disso, o estado é novo e o metadata do
# Pegasus foi atualizado (o Pegasus precisa recarregar); 1 se falhou.
nether_exit() {
    menu=0
    for try in 1 2; do        # 2ª tentativa: o BACK pode ter fechado um menu que já estava aberto
        input keyevent KEYCODE_BACK; sleep 1
        uiautomator dump $UI >/dev/null 2>&1
        grep -q "$NETHER_PKG:id/subtitle" $UI 2>/dev/null && { menu=1; break; }
    done
    [ $menu = 1 ] || { log "NetherSX2: o menu de pausa não abriu"; return 1; }
    sed 's/<node/\n<node/g' $UI > $UI.l
    # subtítulo: "Black (USA).chd (SLUS-21376 / 5C891FF1)"
    game=$(grep "$NETHER_PKG:id/subtitle" $UI.l | sed -n 's/.*text="[^"]*(\([^ ()]*\) \/ \([0-9A-F]\{8\}\))".*/\1 (\2)/p')
    box=$(grep -E 'text="(Sair do jogo|Exit Game|Shutdown|Salir del juego)"' $UI.l |
          sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p' | head -1)
    rm -f $UI $UI.l
    if [ -z "$box" ]; then
        log "NetherSX2: item 'Sair do jogo' não encontrado no menu"; input keyevent KEYCODE_BACK; return 1
    fi
    st="$NETHER_STATES/$game.resume.p2s"
    before=$(stat -c %Y "$st" 2>/dev/null || echo novo)
    echo "$box" > $UI.b; read x1 y1 x2 y2 < $UI.b; rm -f $UI.b
    input tap $(((x1 + x2) / 2)) $(((y1 + y2) / 2))
    i=0
    while [ $i -lt 20 ]; do   # até 10 s para sair e gravar
        sleep 0.5; i=$((i + 1))
        after=$(stat -c %Y "$st" 2>/dev/null || echo novo)
        [ "$(top_pkg)" != "$NETHER_PKG" ] && [ "$after" != "$before" ] && break
    done
    if [ -z "$game" ] || [ "$after" = "$before" ]; then
        log "NetherSX2: saiu, mas o estado não mudou ($game)"; return 1
    fi
    # o NetherSX2 só roda um jogo por processo: o 2º jogo no mesmo processo encerra a emulação em
    # menos de 1 s (tela preta). Com o estado salvo e a emulação encerrada, fechar é seguro.
    am force-stop $NETHER_PKG
    log "estado salvo (NetherSX2 $game.resume.p2s)"
    [ "$before" = novo ] && nether_register "$st" && return 2
    return 0
}

# Estado novo: põe --es saveStatePath no launch: do jogo cujo x-nethersx2-state é este arquivo,
# em cada metadata.pegasus.txt das pastas do Pegasus (o gerador só põe o extra quando o arquivo
# existe; sem ele o NetherSX2 recusa abrir o jogo).
nether_register() {
    changed=1
    while IFS= read -r dir; do
        meta="$dir/metadata.pegasus.txt"
        grep -qF "x-nethersx2-state: $1" "$meta" 2>/dev/null || continue
        awk -v st="$1" '
            function flush(   i, hit) {
                hit = 0; for (i = 1; i <= n; i++) if (b[i] == "x-nethersx2-state: " st) hit = 1
                for (i = 1; i <= n; i++) {
                    if (hit && b[i] ~ /^launch: / && index(b[i], "saveStatePath") == 0)
                        b[i] = b[i] " --es saveStatePath '\''" st "'\''"
                    print b[i]
                }
                n = 0
            }
            /^game:/ { flush() }
            { b[++n] = $0 }
            END { flush() }' "$meta" > $UI.m && cat $UI.m > "$meta" && changed=0
        rm -f $UI.m
        log "metadata: saveStatePath incluído em $meta"
    done < $GAME_DIRS
    return $changed
}

# salva o estado antes de sair; devolve 0 se o emulador já saiu sozinho
save_state() {
    case "$1" in
    "$NETHER_PKG")
        nether_exit; r=$?
        [ $r = 2 ] && am force-stop $HOME_PKG    # o Home reabre o Pegasus lendo o metadata novo
        [ $r = 1 ] && return 1
        return 0 ;;
    org.ppsspp.ppsspp)
        input keyevent KEYCODE_F2; sleep 2; log "estado salvo (PPSSPP F2)"; return 1 ;;
    com.retroarch)
        input keyevent KEYCODE_ESCAPE        # sai do jeito normal: grava o estado automático
        i=0; while pidof com.retroarch >/dev/null && [ $i -lt 10 ]; do sleep 0.5; i=$((i+1)); done
        if pidof com.retroarch >/dev/null; then log "RetroArch não saiu pelo Esc"; return 1; fi
        log "estado salvo (RetroArch saiu pelo Esc)"; return 0 ;;
    esac
    return 1
}

action() {
    case "$1" in
    close)
        pkg=$(top_pkg)
        case "$pkg" in
        ""|"$HOME_PKG"|com.android.systemui|com.android.launcher3) log "close ignorado ($pkg)"; return ;;
        *) save_state "$pkg" || am force-stop "$pkg"; log "close $pkg" ;;
        esac
        input keyevent KEYCODE_HOME ;;
    menu)
        pkg=$(top_pkg)
        case "$pkg" in
        ""|"$HOME_PKG"|com.android.systemui|com.android.launcher3) log "menu ignorado ($pkg)" ;;
        com.retroarch) input keyevent KEYCODE_F1; log "menu $pkg (F1)" ;;
        *) input keyevent KEYCODE_BACK; log "menu $pkg (BACK)" ;;
        esac ;;
    power)
        st=$(dumpsys power | sed -n 's/^ *mWakefulness=\([A-Za-z]*\).*/\1/p' | head -1)
        ago=$(dumpsys power | sed -n 's/^ *mLastWakeTime=.*(\([0-9]*\) ms ago).*/\1/p' | head -1)
        if [ "$st" != Awake ]; then
            input keyevent KEYCODE_WAKEUP; wm dismiss-keyguard; log "ligado (botão Home do controle)"
        elif [ "${ago:-999999}" -lt 2500 ]; then
            wm dismiss-keyguard; log "botão Home ignorado: a tela acabou de acordar"
        else
            input keyevent KEYCODE_SLEEP; log "desligado (espera) pelo botão Home do controle"
        fi ;;
    nether-exit)    # usado pelo perfd (calamidade): sai salvando, sem voltar ao Home
        nether_exit ;;
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
                    else if (k[3] == "BUTTON_MODE") role = "P"
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
            down[dev, r] = ($4 != "00000000")      # 1 = apertou, 2 = repetição, 0 = soltou
            if (r == "P") { if ($4 == "00000001") system("sh " self " action power"); next }
            both = down[dev, "S"] && down[dev, "T"]
            if (both && !fired[dev]) {
                fired[dev] = 1
                a = (down[dev, "L"] && down[dev, "R"]) ? "menu" : "close"
                system("sh " self " action " a)
            } else if (!both) fired[dev] = 0
        }
    '
    sleep 2
done
