#!/system/bin/sh
# s20fe: atalhos iguais para qualquer controle (roda como root pelo Magisk, service.d).
#   Select + Start                    -> fecha o jogo atual (salvando o estado) e volta ao Pegasus
#   L1 + R1 (segurados) + Select+Start -> abre o menu/configurações do emulador (o jogo continua)
#   Botão PS / Home / Guide (BUTTON_MODE ou HOME, de qualquer interface do controle)
#                                     -> "desliga" (fecha o jogo salvando, apaga a tela) e liga de
#                                        novo; com a tela apagada, qualquer botão também liga. Ao
#                                        ligar, o perfis.sh mostra a escolha de perfil
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

# Com o Pegasus fechado: a próxima abertura dele pula a escolha de perfil (o tema lê "pularPerfil"
# no api.memory). Usado quando o Pegasus é reaberto por baixo dos panos.
PEGASUS_MEM=/data/media/0/Android/data/$HOME_PKG/files/pegasus-frontend/theme_settings/s20fe-console.json
pegasus_skip_picker() {
    [ -f $PEGASUS_MEM ] || return
    /data/adb/s20fe/bin/jq -c '.pularPerfil = true' $PEGASUS_MEM > $UI.mem &&
        cat $UI.mem > $PEGASUS_MEM          # cat: mantém dono e contexto do arquivo
    rm -f $UI.mem
}

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
    nether_bind        # controle trocado com o jogo aberto: mapeia agora, com ele fechado
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
        [ $r = 2 ] && { am force-stop $HOME_PKG; pegasus_skip_picker; }   # o Home reabre o Pegasus lendo o metadata novo
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
            # desligar = fechar o jogo salvando (como Select+Start) e apagar a tela; ao ligar, o
            # perfis.sh vê o aviso e reabre o Pegasus na escolha de perfil
            pkg=$(top_pkg)
            case "$pkg" in
            ""|"$HOME_PKG"|com.android.systemui|com.android.launcher3) ;;
            *) save_state "$pkg" || am force-stop "$pkg"; log "close $pkg (desligando)" ;;
            esac
            touch /data/local/tmp/s20fe-desligado
            input keyevent KEYCODE_SLEEP; log "desligado (espera) pelo botão Home do controle"
        fi ;;
    nether-exit)    # usado pelo perfd (calamidade): sai salvando, sem voltar ao Home
        nether_exit ;;
    restart-home)
        top=$(dumpsys activity activities | grep -m1 topResumedActivity)
        am force-stop $HOME_PKG
        pegasus_skip_picker
        case "$top" in
        *" $HOME_PKG/"*) sleep 1; monkey -p $HOME_PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
                         log "Pegasus reaberto (controle novo)" ;;
        *) log "Pegasus fechado em segundo plano (controle novo; reabre no Home)" ;;
        esac ;;
    esac
}

# "caminho arquivo.kl controle vendor product" de cada dispositivo que o Android classifica como
# GAMEPAD e das outras interfaces do mesmo controle (mesmo SysfsDevicePath): muitos controles
# Bluetooth mandam o botão Home por uma interface "Consumer Control" separada (ex.: GameSir T3s em
# modo Apple: KEY_HOMEPAGE no event10, botões no event11).
build_map() {
    dumpsys input | awk -v map="$MAP" '
        function flush() {
            if (path != "") { n++; P[n] = path; K[n] = kl; S[n] = sys; G[n] = pad; E[n] = ext; V[n] = ven; D[n] = prod }
            path = kl = sys = ven = prod = ""; pad = ext = 0
        }
        /^  Devices:/ { on = 1; next }
        on && /^  [^ ]/ { flush(); on = 0 }
        !on { next }
        /^    -?[0-9]+: / { flush() }               # inclui o "-1: Virtual"
        /Classes:/ { pad = ($0 ~ /GAMEPAD/); ext = ($0 ~ /EXTERNAL/) }
        /^ +Path:/ { path = $2 }
        /Identifier:/ {
            if (match($0, /vendor=0x[0-9a-f]+/)) ven = substr($0, RSTART + 9, RLENGTH - 9)
            if (match($0, /product=0x[0-9a-f]+/)) prod = substr($0, RSTART + 10, RLENGTH - 10)
        }
        /KeyLayoutFile:/ { kl = $2 }
        /SysfsDevicePath:/ { sys = $2 }
        END {
            flush()
            for (i = 1; i <= n; i++) print P[i] > (map ".reg")   # dispositivos que o Android já registrou
            for (i = 1; i <= n; i++) if (G[i] && S[i] != "<none>") pads[S[i]] = 1
            for (i = 1; i <= n; i++)
                if (K[i] != "" && (G[i] || (E[i] && (S[i] in pads))))
                    print P[i], K[i], (S[i] == "<none>" ? P[i] : S[i]), V[i], D[i]
        }
    ' > $MAP
    # "conhecidos" para o leitor: TODOS os eventN existentes. O getevent anuncia todos ao iniciar,
    # inclusive os que o Android nunca registra; com só os registrados aqui, o leitor via um
    # "dispositivo novo" a cada início e ficava em loop (2026-10-19)
    ls /dev/input/event* > $MAP.all
}

# Ao conectar, o /dev/input/eventN aparece antes de o Android registrar o controle; se o mapa for
# feito nessa janela, o controle fica de fora e, como o "add device" já passou, nunca mais entra
# (visto em 2026-10-19: "controles:" vazio e atalhos mortos). Refaz até todos os eventN novos
# estarem registrados (até ~10 s). Alguns eventN internos o Android nunca registra (event1,
# event4-7 neste aparelho): os que já estavam sem registro na 1ª leitura ficam em $MAP.ign.
build_map_settled() {
    i=0
    while :; do
        build_map
        grep -vxF -f $MAP.reg $MAP.all > $MAP.unreg
        [ -f $MAP.ign ] || cp $MAP.unreg $MAP.ign
        [ -z "$(grep -vxF -f $MAP.ign $MAP.unreg)" ] && return
        i=$((i + 1)); [ $i -ge 10 ] && { log "dispositivo de entrada sem registro no Android após 10 s"; return; }
        sleep 1
    done
}

# Controles sem mapa próprio usam o Generic.kl, que transforma o Home do controle (KEY_HOMEPAGE)
# em HOME do Android: o sistema vai ao Pegasus antes de o jogo ser salvo. Para eles, cria em
# /data/system/devices/keylayout/ (pasta de mapas do usuário, lida pelo Android quando não há mapa
# do fabricante no sistema) uma cópia do Generic.kl com HOME -> WAKEUP: acorda a tela quando ela
# está apagada e, acesa, o Android não repassa a tecla aos apps (fica só para este script). Não
# usar BUTTON_MODE: na interface "Consumer Control" ele faz o Android tratá-la como um 2º gamepad
# (o RetroArch pegava como controle 1). Vale a partir da próxima conexão do controle.
# Para desfazer: apagar o arquivo.
KL_DIR=/data/system/devices/keylayout
fix_home_layout() {
    while read -r path kl grp ven prod; do
        [ -n "$ven" ] && [ -n "$prod" ] || continue
        f=$KL_DIR/Vendor_${ven}_Product_${prod}.kl
        case "$kl" in
        /system/usr/keylayout/Generic.kl) ;;
        "$f") grep -qE '^key[ \t]+172[ \t]+WAKEUP' "$f" && continue
              kl=/system/usr/keylayout/Generic.kl ;;   # versão antiga (BUTTON_MODE): refazer
        *) continue ;;
        esac
        mkdir -p $KL_DIR && chown system:system /data/system/devices $KL_DIR &&
            chmod 755 /data/system/devices $KL_DIR || return
        sed -E 's/^(key[ \t]+172[ \t]+)HOME([ \t]|$)/\1WAKEUP\2/' "$kl" > "$f.tmp" &&
            mv "$f.tmp" "$f" && chown system:system "$f" && chmod 644 "$f" &&
            restorecon -R /data/system/devices
        log "mapa criado: $f (Home do controle -> WAKEUP); vale ao reconectar o controle"
    done < $MAP
}

# ---------- NetherSX2 (PS2): mapeamento para qualquer controle ----------
# O NetherSX2 grava cada botão preso ao descritor do controle ("<descritor>/Button96"), então um
# controle diferente (ou o mesmo em outro modo) fica sem mapeamento no PS2. Com o NetherSX2
# fechado, regrava o Pad1 com o 1º controle conectado e o Pad2 com o 2º (ou desliga o Pad2),
# usando os eixos que cada controle realmente tem. Botões = keycodes do Android, iguais em todos
# os controles. O "Analog" fica sem botão: o Home/PS é o liga/desliga do console.
# Backup das preferências antes da 1ª alteração: /data/adb/s20fe/backup/nethersx2-prefs.xml
NETHER_PREFS=/data/data/$NETHER_PKG/shared_prefs/${NETHER_PKG}_preferences.xml
NETHER_KEYS="Up Down Left Right Cross Circle Square Triangle L1 R1 L2 R2 L3 R3 Start Select Analog LUp LDown LLeft LRight RUp RDown RLeft RRight SmallMotor LargeMotor Type"

# "nº do jogador, descritor, caminho, arquivo.kl" de cada controle, na ordem de jogador do Android
# (ControllerNum). O Android junta as interfaces do mesmo controle (mesmo SysfsRootPath) num só
# dispositivo, e é esse que os apps veem: o descritor dele é o da interface que abriu primeiro e
# deu nome ao dispositivo (no GameSir T3s, a "Consumer Control"), não o da interface dos botões.
# Os eixos (caminho e .kl) vêm da interface JOYSTICK.
real_pads() {
    dumpsys input | awk '
        function flushdev(   n, a, i, d, j) {
            if (!indev) return; indev = 0
            if (src !~ /GAMEPAD/ || src !~ /JOYSTICK/) return
            n = split(ids, a, " "); d = ""; j = ""
            for (i = 1; i <= n; i++) {
                if (d == "" && name[a[i]] == dn) d = desc[a[i]]
                if (j == "" && joy[a[i]]) j = a[i]
            }
            if (d == "") d = desc[a[1]]
            if (j != "" && d != "") print num, d, path[j], kl[j]
        }
        /^  Devices:/ { ev = 1; next }
        ev && /^  [^ ]/ { ev = 0 }
        ev && /^    -?[0-9]+: / { cur = $1 + 0; nm = $0; sub(/^ +-?[0-9]+: /, "", nm); name[cur] = nm; next }
        ev && /Classes:/ { joy[cur] = ($0 ~ /JOYSTICK/) }
        ev && /^ +Path:/ { path[cur] = $2 }
        ev && /^ +Descriptor:/ { desc[cur] = $2 }
        ev && /KeyLayoutFile:/ { kl[cur] = $2 }
        indev && /^  [^ ]/ && !/^  Device -?[0-9]+: / { flushdev() }
        /^  Device -?[0-9]+: / {
            flushdev(); dn = $0; sub(/^  Device -?[0-9]+: /, "", dn)
            ids = src = ""; num = 0; indev = 1; next
        }
        indev && /EventHub Devices:/ { ids = $0; sub(/.*\[ */, "", ids); sub(/ *\].*/, "", ids) }
        indev && /^    Sources:/ { src = $0 }
        indev && /^    ControllerNum:/ { num = $2 }
        END { flushdev() }' | sort -n
}

# linhas "chave valor" do Pad $1 para o controle $2 (descritor), $3 (caminho), $4 (.kl)
pad_binds() {
    { getevent -p "$3" 2>/dev/null; echo "@kl"; cat "$4"; } | awk -v n="$1" -v d="$2" '
        function hex(s) { s = tolower(s); sub(/^0x/, "", s); sub(/^0+/, "", s); return s }
        /^@kl$/ { kl = 1; next }
        !kl && /\([0-9a-f]+\):/ { abs = ($0 ~ /ABS \(0003\):/) }
        !kl && abs { for (i = 1; i < NF; i++) if ($i ~ /^[0-9a-f][0-9a-f][0-9a-f][0-9a-f]$/ && $(i + 1) == ":") has[hex($i)] = 1 }
        kl && $1 == "axis" && $3 !~ /^(split|invert)$/ { if (hex($2) in has) ax[$3] = 1 }
        function b(k, v) { print "Pad" n "/" k, d "/" v }
        END {
            b("Cross", "Button96"); b("Circle", "Button97"); b("Square", "Button99"); b("Triangle", "Button100")
            b("L1", "Button102"); b("R1", "Button103"); b("L3", "Button106"); b("R3", "Button107")
            b("Start", "Button108"); b("Select", "Button109")
            b("LUp", "-Axis1"); b("LDown", "+Axis1"); b("LLeft", "-Axis0"); b("LRight", "+Axis0")
            if (ax["Z"] && ax["RZ"]) { rx = 11; ry = 14 } else if (ax["RX"] && ax["RY"]) { rx = 12; ry = 13 }
            if (rx) { b("RUp", "-Axis" ry); b("RDown", "+Axis" ry); b("RLeft", "-Axis" rx); b("RRight", "+Axis" rx) }
            # gatilhos analógicos: o Android repete LTRIGGER/RTRIGGER em BRAKE (23)/GAS (22), que é o
            # que o próprio NetherSX2 escolhe ao mapear
            if (ax["LTRIGGER"] && ax["RTRIGGER"]) { b("L2", "+Axis23"); b("R2", "+Axis22") }
            else { b("L2", "Button104"); b("R2", "Button105") }
            if (ax["HAT_X"] && ax["HAT_Y"]) { b("Up", "-Axis16"); b("Down", "+Axis16"); b("Left", "-Axis15"); b("Right", "+Axis15") }
            else { b("Up", "Button19"); b("Down", "Button20"); b("Left", "Button21"); b("Right", "Button22") }
            b("SmallMotor", "Vibrator0"); b("LargeMotor", "Vibrator1")
            print "Pad" n "/Type", "DualShock2"
        }'
}

nether_bind() {
    [ -f $NETHER_PREFS ] || return 0
    pidof $NETHER_PKG >/dev/null && return 1        # aberto: ele sobrescreveria; tenta depois
    real_pads | head -2 > $UI.pads
    [ -s $UI.pads ] || return 0                     # nenhum controle: mantém o que está
    sig=$(cut -d' ' -f2 $UI.pads | tr '\n' ' ')
    [ "$sig" = "$(cat $MAP.nether 2>/dev/null)" ] && grep -q "${sig%% *}/Button96" $NETHER_PREFS && return 0
    mkdir -p /data/adb/s20fe/backup
    [ -f /data/adb/s20fe/backup/nethersx2-prefs.xml ] || cp -p $NETHER_PREFS /data/adb/s20fe/backup/nethersx2-prefs.xml
    : > $UI.binds; n=0
    while read -r id desc path kl; do
        n=$((n + 1)); pad_binds $n "$desc" "$path" "$kl" >> $UI.binds
    done < $UI.pads
    [ $n -lt 2 ] && echo "Pad2/Type None" >> $UI.binds
    awk -v keys="$NETHER_KEYS" -v binds="$UI.binds" '
        BEGIN {
            nk = split(keys, k, " "); for (i = 1; i <= nk; i++) { managed["Pad1/" k[i]] = 1; managed["Pad2/" k[i]] = 1 }
            while ((getline l < binds) > 0) { sp = index(l, " "); new[substr(l, 1, sp - 1)] = substr(l, sp + 1) }
        }
        match($0, /<string name="[^"]*"/) { name = substr($0, RSTART + 14, RLENGTH - 15); if (name in managed) next }
        /<\/map>/ { for (kk in new) print "    <string name=\"" kk "\">" new[kk] "</string>" }
        { print }' $NETHER_PREFS > $UI.prefs &&
        grep -q '</map>' $UI.prefs && cat $UI.prefs > $NETHER_PREFS     # cat: mantém dono e contexto
    rm -f $UI.prefs $UI.binds $UI.pads
    echo "$sig" > $MAP.nether
    log "NetherSX2: Pad1..Pad$n mapeados para os controles $sig"
}

if [ "$1" = action ]; then action "$2"; exit; fi

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
log "iniciado"
first=1
while true; do
    build_map_settled
    fix_home_layout
    nether_bind
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
                grp[dev] = f[3]                 # interfaces do mesmo controle contam juntas
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
                    else if (k[3] == "BUTTON_MODE" || k[3] == "HOME" || k[3] == "WAKEUP") role = "P"
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
            r = roles[dev SUBSEP $3]; g = grp[dev]
            down[g, r] = ($4 != "00000000")        # 1 = apertou, 2 = repetição, 0 = soltou
            if (r == "P") { if ($4 == "00000001") system("sh " self " action power"); next }
            both = down[g, "S"] && down[g, "T"]
            if (both && !fired[g]) {
                fired[g] = 1
                a = (down[g, "L"] && down[g, "R"]) ? "menu" : "close"
                system("sh " self " action " a)
            } else if (!both) fired[g] = 0
        }
    '
    sleep 2
done
