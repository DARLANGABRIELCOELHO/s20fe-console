#!/system/bin/sh
# s20fe: assistente de desempenho (roda como root pelo Magisk, service.d).
#
# Mede (a cada 0,5 s, durante o jogo; velocidade = média do último segundo; roda só nos núcleos 0-3):
#   - FPS real da camada do jogo (SurfaceFlinger TimeStats)
#   - velocidade estimada = FPS / FPS base do jogo (60 ou 50, aprendido por jogo)
#   - uso de CPU dos threads da emulação (no PS2: "CPU Thread" = EE, "GS Back", "MTVU", "GS")
#   - clocks e temperaturas
# Só considera "lento" quando o FPS está baixo E o thread mais pesado da emulação está
# trabalhando (em menus/carregamento o FPS cai, mas a emulação está a 100% com os threads parados).
#
# Ações:
#   - Imediatas, a cada 0,5 s: < 85% sobe um degrau por vez; < 75% aplica todos de uma vez:
#       1) thread mais pesado no núcleo principal (2,84 GHz), demais nos núcleos 4-6 (reaplicado
#          todo segundo, porque o ARMSX2 refaz as afinidades)
#       + piso da GPU em 625 MHz (a GPU ociosa fica em 400 MHz; teste A/B no Guitar Hero III:
#         ganho de só ~5%, dentro da variação entre cenas — ajuda pouco, mas é imediato)
#       2) núcleos grandes travados na frequência máxima
#       3) GPU fixa em 670 MHz se estiver abaixo de 80 °C
#       4) prioridade máxima (nice -10) para os threads da emulação
#       5) fecha apps em segundo plano
#     Com a velocidade ≥ 90% por 5 s, tudo volta ao normal (não vale esquentar sem ganho).
#   - CALAMIDADE (< 65% por 3 s, só PS2): espera o próximo autosave do ARMSX2 (a cada 1 min),
#     fecha o emulador, aplica 3 ajustes de uma vez e reabre o jogo, que carrega o autosave
#     (perda de poucos segundos). Uma vez por sessão; desfeito na sessão seguinte se piorar.
#   - Na próxima abertura do jogo (só PS2/ARMSX2 por enquanto; 2 de uma vez se a sessão ficou < 75%):
#     configurações do jogo, escolhido pelo gargalo medido; se a velocidade média piorar,
#     desfaz sozinho e marca o ajuste como ruim para aquele jogo.
# O controle térmico do Android (thermal-engine) continua sempre ativo; o assistente também
# baixa um nível da GPU acima de 88 °C.
#
# Arquivos: /storage/emulated/0/Games/.perf/  (sessões, resumo.txt, ajustes.txt, estado por jogo)
# Log: /data/local/tmp/s20fe-perfd.log

OBSERVE=" xyz.aethersx2.android "        # só mede, sem ações (estudo comparativo do NetherSX2)
EMUS="com.armsx2 xyz.aethersx2.android org.ppsspp.ppsspp com.retroarch dev.legacy.eden_emulator com.droiddeck.launcher"
GPU_MAX=625000000; GPU_BOOST=670000000; GPU_FLOOR=525000000
HOT=88; COOL=78; BOOST_OK=80          # °C
SLOW=85                                # % de velocidade: abaixo disto, uma ação por vez, na hora
VSLOW=75                               # abaixo disto: todas as ações de uma vez (e 2 ajustes por abertura)
CALAM=65                               # "calamidade": reinicia o jogo com 3 ajustes (carrega o autosave)
PS2DIR=/storage/emulated/0/Games/ps2
BUSY=45                                # % de CPU do thread mais pesado para considerar "em jogo"
CPU4_MIN_GAME=1670400; CPU7_MIN_GAME=1862400
K=/sys/class/kgsl/kgsl-3d0; T=/sys/class/thermal; C=/sys/devices/system/cpu/cpufreq
OUT=/storage/emulated/0/Games/.perf; LOG=/data/local/tmp/s20fe-perfd.log
JQ=/data/adb/s20fe/bin/jq
ARMS_RECENT=/storage/emulated/0/Games/ps2/recent_games.json
LEVELS="670000000 625000000 587000000 525000000"
DEF_MINPL=6                            # piso padrão da GPU (nível 6 = 400 MHz)
# Escada de ajustes do ARMSX2 por gargalo: "chave=valor-json" (um por vez, na ordem)
# gargalo gráfico com a GPU ociosa = esperas (driver/sincronização), não falta de potência:
# testa primeiro OpenGL no lugar de Vulkan e afinidade 0 (é o que o NetherSX2 usa e roda bem no
# Adreno 650), depois o driver do sistema no lugar do Turnip, o modo do GS Back e o upscaler.
# (hardwareDownloadMode NÃO entra: o valor 0 é o mais preciso e mais lento.)
# Últimos recursos: blending mínimo e pular 1 quadro (mantém a velocidade e o áudio; menos fluido).
GFX_STEPS='lsfgEnabled=false renderer="opengl" affinityMode=0 customDriverId="" gsBackThreadMode=0 upscaler=0 upscaleFloat=1 accurateBlendingUnit=0 frameSkip=1'
CPU_STEPS='affinityMode=0 eeCycleSkip=1 eeCycleRate=-1 affinityMode=5 eeCycleSkip=2 eeCycleRate=-2'

log() { echo "$(date '+%F %T') $*" >> $LOG; }
ajuste() { echo "$(date '+%F %T') | $*" >> $OUT/ajustes.txt; log "ajuste: $*"; }
top_pkg() { dumpsys activity activities | grep -m1 topResumedActivity | sed -E 's/.* u0 ([^/]+)\/.*/\1/'; }
game_uri() { dumpsys activity activities | grep -m1 -A6 "Hist  *#0:" | grep -oE 'dat=[^ ]+' | head -1 | sed 's/^dat=//'; }
urldec() { sed 's/%20/ /g; s/%28/(/g; s/%29/)/g; s/%27/'"'"'/g; s/%2C/,/g; s/%26/\&/g; s/%5B/[/g; s/%5D/]/g'; }
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
EMU_THREADS="CPU Thread|GS Back|MTVU|GS"
emu_tids() { awk -v re="^($EMU_THREADS)\$" '{ n=$3; for (i=4;i<=NF;i++) n=n" "$i; if (n ~ re) print $1 }' $TICKS_FILE; }
# afinidade: thread mais pesado no núcleo 7, os outros threads da emulação nos núcleos 4-6
pin_heaviest() {
    for tid in $(emu_tids); do
        if [ "$tid" = "$1" ]; then taskset -p 80 $tid >/dev/null 2>&1; else taskset -p 70 $tid >/dev/null 2>&1; fi
    done
    [ -n "$1" ] && taskset -p 80 $1 >/dev/null 2>&1
}
boost_prio() { for tid in $(emu_tids); do renice -n -10 -p $tid >/dev/null 2>&1; done; }

# ---------- ajuste por jogo (ARMSX2) ----------
arms_serial() { $JQ -r --arg u "$1" 'map(select(.uri == $u)) | .[0].serial // empty' $ARMS_RECENT 2>/dev/null; }
# As configurações do ARMSX2 ficam nas SharedPreferences (ConfigStore.kt): config.global e
# config.game.<serial>, JSON dentro do XML (com &quot; etc.). O armsx2-settings.json é só backup.
ARMS_PREFS=/data/data/com.armsx2/shared_prefs/ARMSX2.xml
xml_unesc() { sed 's/&quot;/"/g; s/&lt;/</g; s/&gt;/>/g; s/&apos;/'"'"'/g; s/&amp;/\&/g'; }
xml_esc() { sed 's/&/\&amp;/g; s/"/\&quot;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
pref_json() {  # $1 = nome da chave (config.global / config.game.X); devolve o JSON ou {}
    v=$(grep -o "<string name=\"$1\">[^<]*" $ARMS_PREFS | sed 's/^[^>]*>//' | xml_unesc)
    [ -n "$v" ] && echo "$v" || echo '{}'
}
arms_get() {   # valor do jogo; se o jogo não define, o global (false conta como valor)
    g=$(pref_json "config.game.$1" | $JQ -c --arg k "$2" 'if has($k) then .[$k] else "@ausente" end')
    [ "$g" != '"@ausente"' ] && { echo "$g"; return; }
    pref_json config.global | $JQ -c --arg k "$2" 'if has($k) then .[$k] else null end'
}
arms_set() {  # serial chave valor-json; só com o ARMSX2 fechado (senão ele sobrescreve)
    pidof com.armsx2 >/dev/null && return 1
    new=$(pref_json "config.game.$1" | $JQ -c --arg k "$2" --argjson v "$3" 'if $v == null then del(.[$k]) else .[$k] = $v end') || return 1
    esc=$(echo "$new" | xml_esc)
    awk -v key="config.game.$1" -v val="$esc" '
        index($0, "<string name=\"" key "\">") { print "    <string name=\"" key "\">" val "</string>"; done=1; next }
        /<\/map>/ && !done { print "    <string name=\"" key "\">" val "</string>" }
        { print }' $ARMS_PREFS > $ARMS_PREFS.s20fe.tmp || return 1
    grep -q "config.game.$1" $ARMS_PREFS.s20fe.tmp && cat $ARMS_PREFS.s20fe.tmp > $ARMS_PREFS
    rm -f $ARMS_PREFS.s20fe.tmp
}
state_get() { [ -f "$OUT/estado-$1.txt" ] && grep -m1 "^$2=" "$OUT/estado-$1.txt" | cut -d= -f2-; }
state_set() {
    f="$OUT/estado-$1.txt"; touch "$f"; grep -v "^$2=" "$f" > "$f.tmp"; echo "$2=$3" >> "$f.tmp"; mv "$f.tmp" "$f"
}
# com o ARMSX2 fechado: avalia o último ajuste e aplica o(s) próximo(s), se houver pendência.
# Velocidade < 75% na última sessão: 2 ajustes de uma vez (desfeitos juntos se piorar).
# ultimo_ajuste / valor_anterior guardam listas separadas por ";".
arms_tune() {
    s=$1; pend=$(state_get $s pendente); [ -n "$pend" ] || return
    speed=$(state_get $s ultima_vel); base=$(state_get $s vel_antes_ajuste)
    last=$(state_get $s ultimo_ajuste); prev=$(state_get $s valor_anterior)
    if [ -n "$last" ] && [ -n "$base" ] && [ "$(state_get $s avaliado)" = 0 ]; then
        if [ "$speed" -lt $((base - 2)) ]; then
            i=1; for st in $(echo "$last" | tr ';' ' '); do
                k=${st%%=*}; pv=$(echo "$prev" | cut -d';' -f$i); arms_set $s "$k" "$pv"; i=$((i + 1))
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
    arms_apply $s $pend $n "$speed" || { state_set $s pendente nenhum; ajuste "$s: sem mais ajustes para tentar no gargalo $pend"; }
}
# aplica até $3 ajustes ainda não tentados da escada do gargalo $2; guarda para avaliar/desfazer
arms_apply() {
    s=$1; case "$2" in gfx) steps=$GFX_STEPS;; *) steps=$CPU_STEPS;; esac
    tried="$(state_get $s tentados) $(state_get $s ruins)"
    applied=""; prevs=""; count=0
    for st in $steps; do
        [ $count -ge $3 ] && break
        case " $tried " in *" $st "*) continue;; esac
        k=${st%%=*}; v=${st#*=}
        cur=$(arms_get $s "$k")
        state_set $s tentados "$(state_get $s tentados) $st"
        [ "$cur" = "$v" ] && continue
        if arms_set $s "$k" "$v"; then
            applied="${applied:+$applied;}$st"; prevs="${prevs:+$prevs;}$cur"; count=$((count + 1))
        fi
    done
    [ $count -gt 0 ] || return 1
    state_set $s ultimo_ajuste "$applied"; state_set $s valor_anterior "$prevs"
    state_set $s vel_antes_ajuste "$4"; state_set $s avaliado 0; state_set $s pendente nenhum
    ajuste "$s: velocidade $4% (gargalo $2) -> aplicado $applied (antes: $prevs)"
    return 0
}

# há ajuste ainda não tentado na escada do gargalo atual?
cal_has_steps() {
    case "$bname" in "GS Back"|GS) st_list=$GFX_STEPS;; *) st_list=$CPU_STEPS;; esac
    tried="$(state_get $SERIAL tentados) $(state_get $SERIAL ruins)"
    for st in $st_list; do case " $tried " in *" $st "*) ;; *) return 0;; esac; done
    return 1
}
# calamidade: espera o próximo autosave, fecha o ARMSX2, aplica 3 ajustes e reabre o jogo
calamity_restart() {
    case "$bname" in "GS Back"|GS) g=gfx;; *) g=cpu;; esac
    v=$(awk -F, -v busy=$BUSY 'NR>1 && $7>=busy { n++; t+=$5 } END { if (n) printf "%d", t/n }' "$SESSION")
    # o ARMSX2 quer o caminho puro e decodificado no extra "path" (como os atalhos dele);
    # um file:// com %20 falha com "Requested filename ... does not exist"
    case "$URI" in
        content://org.pegasus_frontend.android.files/ext/*) path="/storage/emulated/0/${URI#content://org.pegasus_frontend.android.files/ext/}" ;;
        file://*) path="${URI#file://}" ;;
        *) path="$URI" ;;
    esac
    path=$(echo "$path" | urldec)
    am force-stop com.armsx2; sleep 1
    if arms_apply $SERIAL $g 3 "${v:-$vel}"; then
        am start --user 0 -n com.armsx2/.MainActivity -a android.intent.action.VIEW --activity-clear-top --es path "$path" >/dev/null 2>&1
        ajuste "$SERIAL: CALAMIDADE (${vel}% por 3 s) -> jogo reiniciado com $(state_get $SERIAL ultimo_ajuste), carregando o autosave"
    else
        am start --user 0 -n com.armsx2/.MainActivity -a android.intent.action.VIEW --activity-clear-top --es path "$path" >/dev/null 2>&1
        ajuste "$SERIAL: CALAMIDADE (${vel}% por 3 s) mas não há mais ajustes na escada $g; jogo reaberto"
    fi
}

game_start() {
    PKG=$1; PID=$(pidof $PKG | cut -d' ' -f1); URI=$(game_uri); GAME=$(echo "${URI##*/}" | urldec | tr , ";")
    [ -n "$GAME" ] || GAME="$PKG"
    SERIAL=""
    [ "$PKG" = com.armsx2 ] && SERIAL=$(arms_serial "$(echo "$URI" | sed 's#^content://org.pegasus_frontend.android.files/ext/#file:///storage/emulated/0/#')")
    SESSION="$OUT/sessao-$(date +%Y%m%d-%H%M%S).csv"; TICKS_FILE=/data/local/tmp/s20fe-ticks
    echo "hora,emulador,jogo,fps,velocidade,thread_mais_pesado,uso_thread,gpu_mhz,gpu_busy,t_gpu,t_cpu,t_bat,acao" > "$SESSION"
    dumpsys SurfaceFlinger --timestats -enable -clear >/dev/null
    echo $CPU4_MIN_GAME > $C/policy4/scaling_min_freq; echo $CPU7_MIN_GAME > $C/policy7/scaling_min_freq
    echo $GPU_MAX > $K/max_gpuclk
    { echo "@uptime $(cut -d' ' -f1 /proc/uptime)"; thread_ticks $PID; } > $TICKS_FILE
    BASE=""; [ -n "$SERIAL" ] && BASE=$(state_get $SERIAL fps_base); [ -n "$BASE" ] || BASE=60
    LEVEL=0; OK=0; MAXFPS=0; FLOOR=$DEF_MINPL; PREV=""; CALN=0; CAL_WAIT=0; CAL_DONE=0
    log "jogo: $PKG | $GAME | serial=$SERIAL base=$BASE"
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
        if [ -n "$SERIAL" ]; then
            state_set $SERIAL ultima_vel $vel
            [ "$MAXFPS" -ge 55 ] && state_set $SERIAL fps_base 60
            if [ "$vel" -lt 95 ]; then
                case "$garg" in "GS Back"|GS) state_set $SERIAL pendente gfx;; *) state_set $SERIAL pendente cpu;; esac
            elif [ "$(state_get $SERIAL avaliado)" = 0 ]; then
                state_set $SERIAL pendente nenhum   # só avaliar o último ajuste
            fi
        fi
    fi
    log "fim: $PKG | $GAME | $res"
    LASTSERIAL=$SERIAL; PKG=""
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
PKG=""; LASTSERIAL=""
while true; do
    cur=$(top_pkg)
    # fim de sessão: outro app na frente, ou o emulador foi fechado e reaberto (processo novo)
    if [ -n "$PKG" ] && { [ "$cur" != "$PKG" ] || [ "$(pidof $PKG | cut -d' ' -f1)" != "$PID" ]; }; then game_stop; fi
    # ajustes do ARMSX2 só com ele fechado (senão ele sobrescreve o JSON)
    if [ -z "$PKG" ] && [ -n "$LASTSERIAL" ] && ! pidof com.armsx2 >/dev/null; then
        arms_tune $LASTSERIAL; LASTSERIAL=""
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
        case "$OBSERVE" in *" $PKG "*) obs=1;; *) obs=0;; esac
        if [ $obs = 0 ] && [ $vel -lt $SLOW ] && [ "$bpct" -ge $BUSY ]; then
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
        # calamidade (só PS2/ARMSX2, uma vez por sessão): < 65% por 3 s
        if [ "$PKG" = com.armsx2 ] && [ -n "$SERIAL" ] && [ $CAL_DONE = 0 ]; then
            if [ $vel -lt $CALAM ] && [ "$bpct" -ge $BUSY ]; then CALN=$((CALN + 1)); else CALN=0; fi
            AS=$(ls "$PS2DIR/sstates/$SERIAL "*.autosave.p2s 2>/dev/null | head -1)
            if [ $CAL_WAIT = 0 ] && [ $CALN -ge 6 ]; then
                CAL_WAIT=1; CAL_MT=$(stat -c %Y "$AS" 2>/dev/null || echo 0); CAL_T0=$(date +%s)
                acao="$acao CALAMIDADE ${vel}%: esperando o próximo autosave para reiniciar com ajustes"
                log "calamidade: $GAME | ${vel}%; aguardando autosave"
            elif [ $CAL_WAIT = 1 ]; then
                if [ "$(stat -c %Y "$AS" 2>/dev/null || echo 0)" != "$CAL_MT" ]; then
                    CAL_DONE=1
                    if [ $vel -ge $SLOW ]; then
                        log "calamidade cancelada: $GAME | velocidade já voltou a ${vel}%"
                    elif ! cal_has_steps; then
                        log "calamidade cancelada: $GAME | não há ajustes disponíveis (não reinicia à toa)"
                    else
                        sleep 1; calamity_restart; acao="$acao CALAMIDADE: reiniciado com ajustes"
                    fi
                elif [ $(( $(date +%s) - CAL_T0 )) -gt 75 ]; then
                    CAL_WAIT=0; CAL_DONE=1; log "calamidade: autosave não apareceu em 75 s; reinício cancelado"
                fi
            fi
        fi
        echo "$(date +%T),$PKG,$GAME,$fps,$vel,$bname,$bpct,$(( $(cat $K/gpuclk)/1000000 )),$(cat $K/gpu_busy_percentage | tr -d ' %'),$tg,$tc,$tb,$acao" >> "$SESSION"
    else
        sleep 3
    fi
done
