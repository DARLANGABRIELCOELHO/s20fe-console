#!/system/bin/sh
# s20fe: assistente de desempenho (roda como root pelo Magisk, service.d).
#
# Mede (a cada 0,5 s, durante o jogo; velocidade = média do último segundo; roda só nos núcleos 0-3):
#   - FPS real da camada do jogo (SurfaceFlinger TimeStats)
#   - velocidade estimada = FPS / FPS base do jogo (60 NTSC, 50 PAL; aprendido por jogo)
#     NetherSX2: só funciona com EmuCore/GS/SkipDuplicateFrames=false (desligado em 2026-10-19):
#     com ele ligado, um jogo de 30 quadros a 100% aparece como 30 FPS no SurfaceFlinger (= "50%")
#   - uso de CPU dos threads da emulação (NetherSX2: "CPU Thread" = EE, "MTVU" = VU1,
#     "Thread-2" = auxiliares do GS)
#   - clocks e temperaturas
# Só considera "lento" quando o FPS está baixo E o thread mais pesado da emulação está
# trabalhando (em menus/carregamento o FPS cai, mas a emulação está a 100% com os threads parados).
#
# Ações:
#   - Imediatas, a cada 0,5 s: < 85% sobe um degrau por vez; < 75% aplica todos de uma vez:
#       1) thread mais pesado no núcleo principal (2,84 GHz), demais nos núcleos 4-6
#       + piso da GPU em 625 MHz (a GPU ociosa fica em 400 MHz; teste A/B no Guitar Hero III:
#         ganho de só ~5%, dentro da variação entre cenas — ajuda pouco, mas é imediato)
#       2) núcleos grandes travados na frequência máxima
#       3) GPU fixa em 670 MHz se estiver abaixo de 80 °C
#       4) prioridade máxima (nice -10) para os threads da emulação
#       5) fecha apps em segundo plano
#     Com a velocidade ≥ 90% por 5 s, tudo volta ao normal (não vale esquentar sem ganho).
#   - Na próxima abertura do jogo (PS2/NetherSX2; 2 de uma vez se a sessão ficou < 75%):
#     configurações do jogo em gamesettings/<CRC>.ini, escolhidas pelo gargalo medido; se a
#     velocidade média piorar, desfaz sozinho e marca o ajuste como ruim para aquele jogo.
#   - CALAMIDADE (< 65% por 3 s, só PS2, uma vez por sessão): sai pelo menu do NetherSX2 (grava o
#     .resume.p2s, via controller-hotkeys.sh), aplica 3 ajustes de uma vez e reabre o jogo com o
#     mesmo comando do Pegasus, que carrega o estado (perda de ~1 s de jogo).
#   - NetherSX2 aberto em segundo plano sem jogo rodando (saiu pelo menu dele): fecha o processo,
#     porque ele não abre um 2º jogo no mesmo processo (tela preta).
# O controle térmico do Android (thermal-engine) continua sempre ativo; o assistente também
# baixa um nível da GPU acima de 88 °C.
#
# Arquivos: /storage/emulated/0/Games/.perf/  (sessões, resumo.txt, ajustes.txt, estado por jogo)
# Log: /data/local/tmp/s20fe-perfd.log

NETHER=xyz.aethersx2.android
EMUS="$NETHER org.ppsspp.ppsspp com.retroarch dev.legacy.eden_emulator com.droiddeck.launcher"
GPU_MAX=625000000; GPU_BOOST=670000000; GPU_FLOOR=525000000
HOT=88; COOL=78; BOOST_OK=80          # °C
SLOW=85                                # % de velocidade: abaixo disto, uma ação por vez, na hora
VSLOW=75                               # abaixo disto: todas as ações de uma vez (e 2 ajustes por abertura)
CALAM=65                               # "calamidade": reinicia o jogo com 3 ajustes (carrega o estado)
BUSY=45                                # % de CPU do thread mais pesado para considerar "em jogo"
CPU4_MIN_GAME=1670400; CPU7_MIN_GAME=1862400
K=/sys/class/kgsl/kgsl-3d0; T=/sys/class/thermal; C=/sys/devices/system/cpu/cpufreq
OUT=/storage/emulated/0/Games/.perf; LOG=/data/local/tmp/s20fe-perfd.log
GAME_DIRS=/storage/emulated/0/pegasus-frontend/game_dirs.txt
HOTKEYS=$(dirname "$0")/controller-hotkeys.sh
# caminho "de baixo" (ext4) da pasta do NetherSX2: dá para acertar dono e contexto dos arquivos
NETHER_GS=/data/media/0/Android/data/$NETHER/files/gamesettings
LEVELS="670000000 625000000 587000000 525000000"
DEF_MINPL=6                            # piso padrão da GPU (nível 6 = 400 MHz)
# Escadas de ajustes do NetherSX2 por gargalo: "seção:chave=valor" do INI do jogo (um por vez,
# na ordem). EE Cycle Rate negativo = menos ciclos do EE (mais rápido; pode deixar o jogo lento
# por dentro); EE Cycle Skip pula ciclos; blending mínimo alivia o GS. Valores do PCSX2.
CPU_STEPS='EmuCore/Speedhacks:EECycleSkip=1 EmuCore/Speedhacks:EECycleRate=-1 EmuCore/GS:accurate_blending_unit=0 EmuCore/Speedhacks:EECycleSkip=2 EmuCore/Speedhacks:EECycleRate=-2'
GFX_STEPS='EmuCore/GS:accurate_blending_unit=0 EmuCore/Speedhacks:EECycleSkip=1 EmuCore/Speedhacks:EECycleRate=-1 EmuCore/Speedhacks:EECycleSkip=2 EmuCore/Speedhacks:EECycleRate=-2'

log() { echo "$(date '+%F %T') $*" >> $LOG; }
ajuste() { echo "$(date '+%F %T') | $*" >> $OUT/ajustes.txt; log "ajuste: $*"; }
top_pkg() { dumpsys activity activities | grep -m1 topResumedActivity | sed -E 's/.* u0 ([^/]+)\/.*/\1/'; }
game_uri() { dumpsys activity activities | grep -m1 -A6 "Hist  *#0:" | grep -oE 'dat=[^ ]+' | head -1 | sed 's/^dat=//'; }
urldec() { sed 's/%20/ /g; s/%28/(/g; s/%29/)/g; s/%27/'"'"'/g; s/%2C/,/g; s/%26/\&/g; s/%5B/[/g; s/%5D/]/g; s/%2F/\//g; s/%3A/:/g'; }
temp() { echo $(( $(cat $T/$1/temp) / 1000 )); }
next_level() {
    prev=""; for l in $LEVELS; do
        if [ "$2" = down ] && [ "$prev" = "$1" ]; then echo $l; return; fi
        if [ "$2" = up ] && [ "$l" = "$1" ]; then echo ${prev:-$1}; return; fi
        prev=$l
    done; echo $1
}
fps_now() {
    dumpsys SurfaceFlinger --timestats -dump | awk -v p="$1" '
        /layerName =/ { hit = (index($0, "SurfaceView[" p "/") > 0) }
        hit && /averageFPS =/ { print int($3 + 0.5); exit }'
    dumpsys SurfaceFlinger --timestats -clear >/dev/null
}
# tempo de CPU (ticks) por thread do emulador: "tid ticks nome" — um cat só (~34 ms; o laço
# antigo, um processo por thread, levava ~900 ms)
thread_ticks() {
    cat /proc/$1/task/*/stat 2>/dev/null | awk '{ i=index($0, ") "); o=index($0, "(")
        n=substr($0, o+1, i-o-1); split(substr($0, i+2), f, " "); print $1, f[12]+f[13], n }'
}
# compara com a foto anterior (intervalo real pelo /proc/uptime): "pct tid nome" do mais ocupado
busiest() {
    now=$(cut -d' ' -f1 /proc/uptime)
    { echo "@uptime $now"; thread_ticks $PID; } > $TICKS_FILE.new
    awk 'NR==FNR { if ($1=="@uptime") t0=$2; else a[$1]=$2; next }
        $1=="@uptime" { t1=$2; next }
        ($1 in a) { d=$2-a[$1]; n=$3; for (i=4;i<=NF;i++) n=n" "$i
            if (d > m) { m=d; nm=n; tid=$1 } }
        END { dt=t1-t0; printf "%d %s %s\n", (dt>0 ? m/dt : 0), tid, nm }' $TICKS_FILE $TICKS_FILE.new
    mv $TICKS_FILE.new $TICKS_FILE
}
EMU_THREADS="CPU Thread|GS Back|MTVU|GS|Thread-2"
emu_tids() { awk -v re="^($EMU_THREADS)\$" '{ n=$3; for (i=4;i<=NF;i++) n=n" "$i; if (n ~ re) print $1 }' $TICKS_FILE; }
# afinidade: thread mais pesado no núcleo 7, os outros threads da emulação nos núcleos 4-6
pin_heaviest() {
    for tid in $(emu_tids); do
        if [ "$tid" = "$1" ]; then taskset -p 80 $tid >/dev/null 2>&1; else taskset -p 70 $tid >/dev/null 2>&1; fi
    done
    [ -n "$1" ] && taskset -p 80 $1 >/dev/null 2>&1
}
boost_prio() { for tid in $(emu_tids); do renice -n -10 -p $tid >/dev/null 2>&1; done; }

# ---------- NetherSX2: qual jogo está rodando ----------
# A URI do jogo vem do log do próprio NetherSX2 ("Starting emulation thread (<uri>)..."), e o
# serial/CRC vêm do bloco desse jogo no metadata do Pegasus (x-nethersx2-*, tools/gen-pegasus.py).
# Saída: "serial crc" e, numa 2ª linha, o comando launch: do jogo.
nether_game() {
    uri=$(logcat -d --pid=$1 -s EmulationThread:I 2>/dev/null |
          sed -n 's/.*Starting emulation thread (\(.*\))\.\.\..*/\1/p' | tail -1)
    [ -n "$uri" ] || return
    echo "$uri" > $TICKS_FILE.u
    while IFS= read -r dir; do
        awk -v u="bootPath $uri " '
            /^game:/ { if (hit) exit; s = c = l = "" }
            /^launch: / { l = substr($0, 9); if (index($0 " ", u)) hit = 1 }
            /^x-nethersx2-serial: / { s = substr($0, 21) }
            /^x-nethersx2-crc: / { c = substr($0, 18) }
            END { if (hit && c != "") { print s, c; print l } }' "$dir/metadata.pegasus.txt" 2>/dev/null
    done < $GAME_DIRS | head -2
}
# NetherSX2 parado em segundo plano sem jogo (saiu pelo menu dele): fecha (ver cabeçalho).
# Só depois de 3 checagens seguidas (~9 s): logo depois de o Pegasus abrir um jogo, o processo
# já existe sem o "CPU Thread" e às vezes ainda não está na frente.
NETHER_IDLE=0
nether_idle_close() {
    p=$(pidof $NETHER | cut -d' ' -f1)
    if [ -z "$p" ] || grep -qx "CPU Thread" /proc/$p/task/*/comm 2>/dev/null; then
        NETHER_IDLE=0; return      # fechado, ou com jogo pausado (não mexe)
    fi
    NETHER_IDLE=$((NETHER_IDLE + 1)); [ $NETHER_IDLE -ge 3 ] || return
    am force-stop $NETHER; NETHER_IDLE=0; log "NetherSX2 sem jogo em segundo plano: fechado"
}

# ---------- ajuste por jogo (NetherSX2: gamesettings/<CRC>.ini) ----------
ini_get() {   # crc seção chave -> valor no INI do jogo, ou @ausente (vale o global)
    f="$NETHER_GS/$1.ini"; [ -f "$f" ] || { echo @ausente; return; }
    awk -v s="[$2]" -v k="$3" '
        /^\[/ { in_s = ($0 == s); next }
        in_s { kk = $0; sub(/[ \t]*=.*/, "", kk)
               if (kk == k) { v = substr($0, index($0, "=") + 1); gsub(/^[ \t]+|[ \t\r]+$/, "", v); print v; found = 1; exit } }
        END { if (!found) print "@ausente" }' "$f"
}
ini_set() {   # crc seção chave valor (@ausente apaga); só com o NetherSX2 fechado
    pidof $NETHER >/dev/null && return 1
    f="$NETHER_GS/$1.ini"; tmp=/data/local/tmp/s20fe-ini.tmp
    if [ ! -f "$f" ]; then   # arquivo novo: dono e contexto iguais aos da pasta (senão o app não lê)
        : > "$f" || return 1
        chown "$(stat -c %u:%g "$NETHER_GS")" "$f"; chcon "$(ls -dZ "$NETHER_GS" | cut -d' ' -f1)" "$f"
    fi
    awk -v s="[$2]" -v k="$3" -v v="$4" '
        function put() { if (!done && v != "@ausente") print k " = " v; done = 1 }
        /^\[/ { if (in_s) put(); in_s = ($0 == s); if (in_s) seen = 1; print; next }
        in_s { kk = $0; sub(/[ \t]*=.*/, "", kk); if (kk == k) { put(); next } }
        { print }
        END { if (in_s) put(); else if (!seen && v != "@ausente") { print s; print k " = " v } }' "$f" > $tmp &&
        cat $tmp > "$f"    # cat, não mv: mantém dono e contexto SELinux
    rm -f $tmp
}
step_get() { k=${1%%=*}; ini_get "$2" "${k%%:*}" "${k#*:}"; }
step_set() { k=${1%%=*}; ini_set "$2" "${k%%:*}" "${k#*:}" "$3"; }
state_get() { [ -f "$OUT/estado-$1.txt" ] && grep -m1 "^$2=" "$OUT/estado-$1.txt" | cut -d= -f2-; }
state_set() {
    f="$OUT/estado-$1.txt"; touch "$f"; grep -v "^$2=" "$f" > "$f.tmp"; echo "$2=$3" >> "$f.tmp"; mv "$f.tmp" "$f"
}
# com o NetherSX2 fechado: avalia o último ajuste e aplica o(s) próximo(s), se houver pendência.
# Velocidade < 75% na última sessão: 2 ajustes de uma vez (desfeitos juntos se piorar).
# ultimo_ajuste / valor_anterior guardam listas separadas por ";". $1 = CRC do jogo.
game_tune() {
    s=$1; pend=$(state_get $s pendente); [ -n "$pend" ] || return
    speed=$(state_get $s ultima_vel); base=$(state_get $s vel_antes_ajuste)
    last=$(state_get $s ultimo_ajuste); prev=$(state_get $s valor_anterior)
    if [ -n "$last" ] && [ -n "$base" ] && [ "$(state_get $s avaliado)" = 0 ]; then
        if [ "$speed" -lt $((base - 2)) ]; then
            i=1; for st in $(echo "$last" | tr ';' ' '); do
                pv=$(echo "$prev" | cut -d';' -f$i); step_set "$st" $s "$pv"; i=$((i + 1))
            done
            ajuste "$s: '$last' piorou ($base% -> $speed%), desfeito (volta: $prev)"
            state_set $s ruins "$(state_get $s ruins) $(echo "$last" | tr ';' ' ')"
        else
            ajuste "$s: '$last' mantido ($base% -> $speed%)"
        fi
        state_set $s avaliado 1
    fi
    [ "$pend" = nenhum ] && return
    n=1; [ -n "$speed" ] && [ "$speed" -lt $VSLOW ] && n=2
    tune_apply $s $pend $n "$speed" || { state_set $s pendente nenhum; ajuste "$s: sem mais ajustes para tentar no gargalo $pend"; }
}
# aplica até $3 ajustes ainda não tentados da escada do gargalo $2; guarda para avaliar/desfazer
tune_apply() {
    s=$1; case "$2" in gfx) steps=$GFX_STEPS;; *) steps=$CPU_STEPS;; esac
    tried="$(state_get $s tentados) $(state_get $s ruins)"
    applied=""; prevs=""; count=0
    for st in $steps; do
        [ $count -ge $3 ] && break
        case " $tried " in *" $st "*) continue;; esac
        v=${st#*=}; cur=$(step_get "$st" $s)
        state_set $s tentados "$(state_get $s tentados) $st"
        [ "$cur" = "$v" ] && continue
        if step_set "$st" $s "$v"; then
            applied="${applied:+$applied;}$st"; prevs="${prevs:+$prevs;}$cur"; count=$((count + 1))
        fi
    done
    [ $count -gt 0 ] || return 1
    state_set $s ultimo_ajuste "$applied"; state_set $s valor_anterior "$prevs"
    state_set $s vel_antes_ajuste "$4"; state_set $s avaliado 0; state_set $s pendente nenhum
    ajuste "$s ($GAME): velocidade $4% (gargalo $2) -> aplicado $applied (antes: $prevs)"
    return 0
}
gargalo() { case "$1" in "CPU Thread"|MTVU) echo cpu;; *) echo gfx;; esac; }
# há ajuste ainda não tentado na escada do gargalo atual?
cal_has_steps() {
    case "$(gargalo "$bname")" in gfx) st_list=$GFX_STEPS;; *) st_list=$CPU_STEPS;; esac
    tried="$(state_get $CRC tentados) $(state_get $CRC ruins)"
    for st in $st_list; do case " $tried " in *" $st "*) ;; *) return 0;; esac; done
    return 1
}
# calamidade: sai salvando pelo menu, aplica 3 ajustes e reabre o jogo (carrega o .resume.p2s)
calamity_restart() {
    g=$(gargalo "$bname")
    v=$(awk -F, -v busy=$BUSY 'NR>1 && $7>=busy { n++; t+=$5 } END { if (n) printf "%d", t/n }' "$SESSION")
    sh "$HOTKEYS" action nether-exit
    if [ $? = 1 ]; then ajuste "$CRC: CALAMIDADE (${vel}%) mas não consegui salvar e sair; nada feito"; return; fi
    if tune_apply $CRC $g 3 "${v:-$vel}"; then
        what="jogo reiniciado com $(state_get $CRC ultimo_ajuste)"
    else
        what="não há mais ajustes na escada $g; jogo reaberto sem mudanças"
    fi
    # o comando do Pegasus, relido do metadata (o hotkeys acabou de pôr o saveStatePath se o
    # estado era novo)
    launch=$(nether_game_launch)
    if [ -n "$launch" ]; then sh -c "$launch" >/dev/null 2>&1; else what="$what; comando do jogo não encontrado, não reabri"; fi
    ajuste "$CRC ($GAME): CALAMIDADE (${vel}% por 3 s) -> $what"
}
nether_game_launch() {
    while IFS= read -r dir; do
        awk -v c="x-nethersx2-crc: $CRC" '
            /^game:/ { if (hit) exit; l = "" }
            /^launch: / { l = substr($0, 9) }
            $0 == c { hit = 1 }
            END { if (hit) print l }' "$dir/metadata.pegasus.txt" 2>/dev/null
    done < $GAME_DIRS | head -1
}

game_start() {
    PKG=$1; PID=$(pidof $PKG | cut -d' ' -f1); TICKS_FILE=/data/local/tmp/s20fe-ticks
    SERIAL=""; CRC=""; URI=""
    if [ "$PKG" = $NETHER ]; then
        sleep 1    # o log "Starting emulation thread" sai logo depois da tela abrir
        nether_game $PID > $TICKS_FILE.g; { read SERIAL CRC; } < $TICKS_FILE.g
        URI=$(cat $TICKS_FILE.u 2>/dev/null); rm -f $TICKS_FILE.g $TICKS_FILE.u
    else
        URI=$(game_uri)
    fi
    GAME=$(echo "${URI##*/}" | urldec | sed 's#.*/##' | tr , ";")
    [ -n "$GAME" ] || GAME="$PKG"
    SESSION="$OUT/sessao-$(date +%Y%m%d-%H%M%S).csv"
    echo "hora,emulador,jogo,fps,velocidade,thread_mais_pesado,uso_thread,gpu_mhz,gpu_busy,t_gpu,t_cpu,t_bat,acao" > "$SESSION"
    dumpsys SurfaceFlinger --timestats -enable -clear >/dev/null
    echo $CPU4_MIN_GAME > $C/policy4/scaling_min_freq; echo $CPU7_MIN_GAME > $C/policy7/scaling_min_freq
    echo $GPU_MAX > $K/max_gpuclk
    { echo "@uptime $(cut -d' ' -f1 /proc/uptime)"; thread_ticks $PID; } > $TICKS_FILE
    BASE=""; [ -n "$CRC" ] && BASE=$(state_get $CRC fps_base)
    if [ -z "$BASE" ]; then case "$SERIAL" in SLES*|SCES*) BASE=50;; *) BASE=60;; esac; fi
    LEVEL=0; OK=0; MAXFPS=0; FLOOR=$DEF_MINPL; PREV=""; CALN=0; CAL_DONE=0
    log "jogo: $PKG | $GAME | serial=$SERIAL crc=$CRC base=$BASE"
}
game_stop() {
    echo $DEF_MINPL > $K/min_pwrlevel
    echo $(cat $C/policy4/cpuinfo_min_freq) > $C/policy4/scaling_min_freq
    echo $(cat $C/policy7/cpuinfo_min_freq) > $C/policy7/scaling_min_freq
    echo $GPU_MAX > $K/max_gpuclk
    dumpsys SurfaceFlinger --timestats -disable >/dev/null
    # resumo só das amostras "em jogo" (thread mais pesado trabalhando)
    res=$(awk -F, -v busy=$BUSY 'NR>1 && $7>=busy && $5!="" { n++; v+=$5; if (min=="" || $5+0<min) min=$5+0; if ($5<85) low++
            g[$6]++; if ($10>tg) tg=$10; if ($12>tb) tb=$12 }
        END { if (!n) { print "0"; exit }
            for (k in g) if (g[k]>gm) { gm=g[k]; gk=k }
            printf "%d %d %d %d %d %s\n", v/n, min, 100*low/n, tg, tb, gk }' "$SESSION")
    echo "$res" > $TICKS_FILE.r; read vel pior abaixo tg tb garg < $TICKS_FILE.r
    if [ -n "$vel" ] && [ "$vel" != 0 ] && [ -n "$tb" ]; then
        echo "$(date '+%Y-%m-%d %H:%M') | $PKG | $GAME | velocidade média ${vel}% (pior ${pior}%, ${abaixo}% do tempo abaixo de 85%) | thread mais pesado: $garg | máx GPU ${tg}°C bateria ${tb}°C" >> $OUT/resumo.txt
        if [ -n "$CRC" ]; then
            state_set $CRC ultima_vel $vel
            [ "$MAXFPS" -ge 55 ] && state_set $CRC fps_base 60
            if [ "$vel" -lt 95 ]; then
                state_set $CRC pendente $(gargalo "$garg")
            elif [ "$(state_get $CRC avaliado)" = 0 ]; then
                state_set $CRC pendente nenhum   # só avaliar o último ajuste
            fi
        fi
    fi
    log "fim: $PKG | $GAME | $res"
    LASTCRC=$CRC; PKG=""
}

# vigia: se o laço cair por qualquer erro, reinicia em 5 s
if [ "$1" != loop ]; then
    until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
    taskset -p 0f $$ >/dev/null 2>&1
    while true; do
        sh "$0" loop
        echo "$(date '+%F %T') laço caiu (código $?), reiniciando" >> $LOG
        echo 6 > $K/min_pwrlevel; echo $GPU_MAX > $K/max_gpuclk
        sleep 5
    done
fi
taskset -p 0f $$ >/dev/null 2>&1    # o próprio assistente só nos núcleos econômicos (0-3)
mkdir -p $OUT
log "iniciado"
PKG=""; LASTCRC=""
while true; do
    cur=$(top_pkg)
    # fim de sessão: outro app na frente, ou o emulador foi fechado e reaberto (processo novo)
    if [ -n "$PKG" ] && { [ "$cur" != "$PKG" ] || [ "$(pidof $PKG | cut -d' ' -f1)" != "$PID" ]; }; then game_stop; fi
    if [ -z "$PKG" ] && [ "$cur" != $NETHER ]; then nether_idle_close; fi
    # ajustes do NetherSX2 só com ele fechado
    if [ -z "$PKG" ] && [ -n "$LASTCRC" ] && ! pidof $NETHER >/dev/null; then
        game_tune $LASTCRC; LASTCRC=""
    fi
    if [ -z "$PKG" ] && echo " $EMUS " | grep -q " $cur "; then game_start "$cur"; fi
    if [ -n "$PKG" ]; then
        sleep 0.5
        fps=$(fps_now "$PKG"); [ -n "$fps" ] || fps=0
        [ "$fps" -gt "$MAXFPS" ] && MAXFPS=$fps
        busiest > $TICKS_FILE.b; read bpct btid bname < $TICKS_FILE.b; bpct=${bpct:-0}
        vel1=$(( fps * 100 / BASE )); [ $vel1 -gt 100 ] && vel1=100
        vel=$(( (vel1 + ${PREV:-$vel1}) / 2 )); PREV=$vel1     # média do último segundo
        tg=$(temp thermal_zone15); tc=$(temp thermal_zone7); tb=$(temp thermal_zone84)
        gmax=$(cat $K/max_gpuclk); acao=""
        if [ $tg -ge $HOT ] && [ "$gmax" -gt $GPU_FLOOR ]; then
            echo $DEF_MINPL > $K/min_pwrlevel; FLOOR=$DEF_MINPL       # solta o piso antes de baixar o teto
            n=$(next_level $gmax down); echo $n > $K/max_gpuclk; acao="GPU quente: piso solto, teto $((n/1000000))"
        fi
        if [ $vel -lt $SLOW ] && [ "$bpct" -ge $BUSY ]; then
            OK=0; from=$((LEVEL + 1))
            if [ $vel -lt $VSLOW ]; then LEVEL=5; else LEVEL=$((LEVEL + 1)); fi   # <75%: tudo de uma vez
            pin_heaviest "$btid"; acao="$acao lento ${vel}%: '$bname' no núcleo principal"
            l=$from; while [ $l -le $LEVEL ] && [ $l -le 5 ]; do
                case $l in
                1) [ $tg -lt $HOT ] && { echo 1 > $K/min_pwrlevel; FLOOR=1; acao="$acao, piso da GPU 625 MHz"; } ;;
                2) cat $C/policy4/cpuinfo_max_freq > $C/policy4/scaling_min_freq
                   cat $C/policy7/cpuinfo_max_freq > $C/policy7/scaling_min_freq; acao="$acao, núcleos grandes no máximo" ;;
                3) [ $tg -lt $BOOST_OK ] && { echo $GPU_BOOST > $K/max_gpuclk; echo 0 > $K/min_pwrlevel; FLOOR=0; acao="$acao, GPU fixa em 670 MHz"; } ;;
                4) boost_prio; acao="$acao, prioridade máxima" ;;
                5) am kill-all >/dev/null 2>&1; acao="$acao, apps em segundo plano fechados" ;;
                esac
                l=$((l + 1))
            done
            [ $from -le 5 ] && log "ação imediata: $GAME | $acao"
        elif [ $LEVEL -gt 0 ] && [ $vel -ge 90 ]; then
            OK=$((OK + 1))
            if [ $OK -ge 10 ]; then   # 5 s estável: desfaz o que só gasta energia e esquenta
                echo $CPU4_MIN_GAME > $C/policy4/scaling_min_freq; echo $CPU7_MIN_GAME > $C/policy7/scaling_min_freq
                echo $DEF_MINPL > $K/min_pwrlevel; FLOOR=$DEF_MINPL; echo $GPU_MAX > $K/max_gpuclk
                log "estável: $GAME | ${vel}% por 5 s; CPU e GPU de volta ao normal"
                LEVEL=0; OK=0
            fi
        fi
        # calamidade (só PS2/NetherSX2, uma vez por sessão): < 65% por 3 s
        if [ "$PKG" = $NETHER ] && [ -n "$CRC" ] && [ $CAL_DONE = 0 ]; then
            if [ $vel -lt $CALAM ] && [ "$bpct" -ge $BUSY ]; then CALN=$((CALN + 1)); else CALN=0; fi
            if [ $CALN -ge 6 ]; then
                CAL_DONE=1
                if cal_has_steps; then
                    acao="$acao CALAMIDADE ${vel}%: salvando, ajustando e reabrindo"; calamity_restart
                else
                    log "calamidade: $GAME | ${vel}%, mas não há ajustes disponíveis (não reinicia à toa)"
                fi
            fi
        fi
        echo "$(date +%T),$PKG,$GAME,$fps,$vel,$bname,$bpct,$(( $(cat $K/gpuclk)/1000000 )),$(cat $K/gpu_busy_percentage | tr -d ' %'),$tg,$tc,$tb,$acao" >> "$SESSION"
    else
        sleep 3
    fi
done
