#!/system/bin/sh
# s20fe: perfis de jogador (roda como root pelo Magisk, service.d).
# O tema do Pegasus guarda a lista de perfis e o escolhido no api.memory, que o Pegasus grava na
# hora em theme_settings/s20fe-console.json ("perfis": [{id, nome, cor}], "perfil": "p1").
# Quando o perfil escolhido muda, este serviço troca as pastas de saves dos emuladores:
#   pasta ativa  <pasta>            = saves do perfil ativo
#   outros perfis <pasta>.perfil-<id> (ao lado, no mesmo disco: renomear é instantâneo e mantém
#                                      dono e contexto SELinux)
# Nada é apagado nem copiado. Cada passo vai antes para o diário (Games/perfis/diario.txt) e o
# dono atual de cada pasta fica em Games/perfis/estado.txt, então uma troca interrompida (ou uma
# pasta que só aparece depois, como o cartão SD ou o 1º uso do Dolphin) é acertada depois.
# Só troca com os emuladores fechados (fecha sozinho NetherSX2 sem jogo e RetroArch sem núcleo).
# Também: ao ligar o console depois do "desligar" do controle (controller-hotkeys.sh), reabre o
# Pegasus, que sempre abre na escolha de perfil.
# Log: /data/local/tmp/s20fe-perfis.log

MEM=/data/media/0/Android/data/org.pegasus_frontend.android/files/pegasus-frontend/theme_settings/s20fe-console.json
DIR=/data/media/0/Games/perfis
ESTADO=$DIR/estado.txt; ATIVO=$DIR/ativo.txt; DIARIO=$DIR/diario.txt
JQ=/data/adb/s20fe/bin/jq
LOG=/data/local/tmp/s20fe-perfis.log
OFF_FLAG=/data/local/tmp/s20fe-desligado          # criado pelo "desligar" do controller-hotkeys.sh
HOME_PKG=org.pegasus_frontend.android
EMUS="xyz.aethersx2.android org.ppsspp.ppsspp com.retroarch org.dolphinemu.dolphinemu dev.legacy.eden_emulator"

log() { echo "$(date '+%F %T') $*" >> $LOG; }
diario() { echo "$(date '+%F %T') | $*" >> $DIARIO; }

# pastas de saves (as do cartão: em cada cartão montado que tiver a pasta do PSP)
pastas() {
    A=/data/media/0/Android/data
    echo $A/xyz.aethersx2.android/files/memcards
    echo $A/xyz.aethersx2.android/files/sstates
    echo /data/media/0/RetroArch/saves
    echo /data/media/0/RetroArch/states
    echo $A/org.dolphinemu.dolphinemu/files/GC
    echo $A/org.dolphinemu.dolphinemu/files/Wii
    echo $A/org.dolphinemu.dolphinemu/files/StateSaves
    echo $A/dev.legacy.eden_emulator/files/nand/user/save
    for c in /mnt/media_rw/*/Games/psp/PSP; do
        [ -d "$c" ] && { echo "$c/SAVEDATA"; echo "$c/PPSSPP_STATE"; }
    done
}

dono_get() { [ -f $ESTADO ] && grep -m1 "^$1=" $ESTADO | cut -d= -f2-; }
dono_set() { touch $ESTADO; grep -v "^$1=" $ESTADO > $ESTADO.tmp; echo "$1=$2" >> $ESTADO.tmp; mv $ESTADO.tmp $ESTADO; }

top_pkg() { dumpsys activity activities | grep -m1 topResumedActivity | sed -E 's/.* u0 ([^/]+)\/.*/\1/'; }

# 0 se dá para trocar agora: nenhum emulador aberto (os ociosos conhecidos são fechados)
emuladores_fechados() {
    top=$(top_pkg)
    for pkg in $EMUS; do
        p=$(pidof $pkg | cut -d' ' -f1); [ -n "$p" ] || continue
        [ "$pkg" = "$top" ] && return 1                                   # em uso
        case $pkg in
        xyz.aethersx2.android)
            grep -qx "CPU Thread" /proc/$p/task/*/comm 2>/dev/null && return 1 ;;   # jogo pausado
        com.retroarch)
            grep -q "_libretro_android.so" /proc/$p/maps 2>/dev/null && return 1 ;; # jogo carregado
        *) return 1 ;;                                                    # não sei se tem jogo: espera
        esac
        am force-stop $pkg; log "$pkg ocioso em segundo plano: fechado para trocar o perfil"
    done
    return 0
}

# põe a pasta $1 no perfil $2
trocar_pasta() {
    d=$1; novo=$2; velho=$(dono_get "$d")
    if [ -z "$velho" ]; then              # pasta nova (ou 1ª vez): é do perfil que estava ativo
        [ -e "$d" ] || return 0
        velho=$(cat $ATIVO 2>/dev/null); velho=${velho:-p1}; dono_set "$d" "$velho"
    fi
    [ "$velho" = "$novo" ] && return 0
    if [ -e "$d.perfil-$velho" ]; then
        log "CONFLITO: $d.perfil-$velho já existe; pasta não trocada"; return 1
    fi
    diario "$d: $velho -> $novo"
    if [ -e "$d" ]; then mv "$d" "$d.perfil-$velho" || { log "falhou: mv $d"; return 1; }; fi
    if [ -e "$d.perfil-$novo" ]; then
        mv "$d.perfil-$novo" "$d" || { log "falhou: mv $d.perfil-$novo"; return 1; }
    elif [ -e "$d.perfil-$velho" ]; then  # perfil sem saves ainda: pasta vazia igual à original
        ref="$d.perfil-$velho"
        mkdir "$d" || { log "falhou: mkdir $d"; return 1; }
        chown "$(stat -c %u:%g "$ref")" "$d" 2>/dev/null       # (no cartão exFAT não se aplica)
        chcon "$(ls -dZ "$ref" | cut -d' ' -f1)" "$d" 2>/dev/null
        chmod "$(stat -c %a "$ref")" "$d" 2>/dev/null
    fi
    dono_set "$d" "$novo"
    diario "$d: ok ($novo)"
}

# pastas que existem e ainda não têm dono registrado ficam com o perfil ativo (antes de trocar)
registrar() {
    a=$(cat $ATIVO)
    for d in $(pastas); do [ -e "$d" ] && [ -z "$(dono_get "$d")" ] && dono_set "$d" "$a"; done
}
# alguma pasta está em outro perfil que não $1?
precisa() {
    [ "$(cat $ATIVO)" != "$1" ] && return 0
    for d in $(pastas); do
        o=$(dono_get "$d"); [ -z "$o" ] && [ -e "$d" ] && o=$(cat $ATIVO)
        [ -n "$o" ] && [ "$o" != "$1" ] && return 0
    done
    return 1
}
# acerta todas as pastas para o perfil $1; devolve 1 se alguma ficou pendente
aplicar() {
    pend=0
    for d in $(pastas); do trocar_pasta "$d" "$1" || pend=1; done
    return $pend
}

pegasus_perfis() { $JQ -r '(.perfis // []) | length' $MEM 2>/dev/null; }
pegasus_perfil() { $JQ -r '.perfil // "p1"' $MEM 2>/dev/null; }

# "Sair" do menu do Pegasus: o Qt encerra, mas o processo continua vivo e o Android reabre a tela
# inicial NO MESMO PROCESSO, onde o Qt não consegue iniciar de novo (QtNative.startApplication
# parado num semáforo) -> ANR "Pegasus não está respondendo" (2026-10-19). O "Sair" aparece no log
# de eventos como wm_finish_activity ...pegasus.../.MainActivity,app-request: aí este vigia fecha o
# processo e reabre o Pegasus do zero (que abre na escolha de perfil).
vigia_sair() {
    logcat -b events -T 1 -s wm_finish_activity:I 2>/dev/null | while IFS= read -r l; do
        case "$l" in
        *"$HOME_PKG/.MainActivity,app-request"*)
            sleep 0.5; am force-stop $HOME_PKG; sleep 0.5; input keyevent KEYCODE_HOME
            log "Sair do Pegasus: processo fechado e Pegasus reaberto" ;;
        esac
    done
}
if [ "$1" = vigia ]; then vigia_sair; exit; fi

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
sh "$0" vigia </dev/null >/dev/null 2>&1 &
mkdir -p $DIR
[ -f $ATIVO ] || echo p1 > $ATIVO
log "iniciado (ativo: $(cat $ATIVO))"
last_mtime=""; pendente=0; tick=0; tela=On
while true; do
    # ligou depois do "desligar" do controle: reabre o Pegasus na escolha de perfil
    t=$(cat /sys/class/drm/card0-DSI-1/dpms 2>/dev/null)
    if [ "$t" = On ] && [ "$tela" != On ] && [ -f $OFF_FLAG ]; then
        rm -f $OFF_FLAG
        am force-stop $HOME_PKG; input keyevent KEYCODE_HOME; log "ligado: escolha de perfil"
    fi
    tela=$t

    m=$(stat -c %Y $MEM 2>/dev/null)
    tick=$((tick + 1))
    # o perfil escolhido mudou, ou há troca pendente, ou passou 30 s (pasta nova, cartão inserido)
    if [ "$m" != "$last_mtime" ] || [ $pendente = 1 ] || [ $((tick % 30)) = 0 ]; then
        last_mtime=$m
        quero=$(pegasus_perfil)
        if [ -n "$quero" ] && [ "$quero" != null ] && precisa "$quero"; then
            if emuladores_fechados; then
                registrar
                ativo=$(cat $ATIVO)
                [ "$quero" != "$ativo" ] && { echo "$quero" > $ATIVO; diario "perfil ativo: $ativo -> $quero"; }
                if aplicar "$quero"; then log "perfil $quero ativo (antes: $ativo)"; pendente=0
                else pendente=1; fi
            else
                [ $pendente = 0 ] && log "troca para $quero esperando um emulador fechar"
                pendente=1
            fi
        else
            pendente=0
        fi
    fi
    sleep 1
done
