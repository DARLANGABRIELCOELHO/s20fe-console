#!/usr/bin/env bash
# Testa, pelo adb, o lançamento de um jogo de PS2 no NetherSX2 com o mesmo comando que o
# tools/gen-pegasus.py grava no metadata do Pegasus.
#
# O NetherSX2 não lê caminho bruto ({file.path}: bloqueado pelo scoped storage do Android 16)
# nem a URI do provider do Pegasus. Ele abre uma URI SAF dentro da pasta para a qual já tem
# permissão persistente (Games/ps2): content://com.android.externalstorage.documents/tree/...
#
# Uso: tools/launch-ps2-test.sh <jogo.iso | /storage/.../jogo.iso> [--serial SERIAL] [--logcat]
#   Só o nome do arquivo: procura em /storage/emulated/0/Games/ps2.
set -u

PKG=xyz.aethersx2.android
INTERNAL=/storage/emulated/0

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

SERIAL=RX8T10JEJXY
LOGCAT=0
TARGET=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --serial) SERIAL="$2"; shift 2 ;;
    --logcat) LOGCAT=1; shift ;;
    -h|--help) usage ;;
    *)
      [ -z "$TARGET" ] || { echo "Erro: argumento extra: $1" >&2; usage; }
      TARGET="$1"; shift ;;
  esac
done
[ -n "$TARGET" ] || usage
ADB=(adb -s "$SERIAL")

case "$TARGET" in
  /storage/*) ROM_PATH="$TARGET" ;;
  */*) echo "Erro: use o nome do arquivo ou um caminho /storage/... do aparelho" >&2; exit 1 ;;
  *) ROM_PATH="$INTERNAL/Games/ps2/$TARGET" ;;
esac

# mesma lógica de android_document_uri() do gen-pegasus.py
urlencode() {
  local s="$1" out="" c i
  for ((i = 0; i < ${#s}; i++)); do
    c="${s:i:1}"
    case "$c" in
      [A-Za-z0-9._~-]) out+="$c" ;;
      *) out+=$(printf '%s' "$c" | od -An -tx1 | tr -d ' \n' | sed 's/../%\U&/g') ;;
    esac
  done
  printf '%s' "$out"
}
DIR="${ROM_PATH%/*}"
FILE="${ROM_PATH##*/}"
case "$DIR" in
  "$INTERNAL"/*) VOLUME=primary; REL="${DIR#"$INTERNAL"/}" ;;
  /storage/*/*) REST="${DIR#/storage/}"; VOLUME="${REST%%/*}"; REL="${REST#*/}" ;;
  *) echo "Erro: caminho fora de /storage: $ROM_PATH" >&2; exit 1 ;;
esac
TREE="$VOLUME:$REL"
URI="content://com.android.externalstorage.documents/tree/$(urlencode "$TREE")/document/$(urlencode "$TREE/$FILE")"

[ "$("${ADB[@]}" shell getprop ro.product.model | tr -d '\r')" = SM-G780G ] || { echo "Erro: aparelho inesperado" >&2; exit 1; }
"${ADB[@]}" shell pm list packages "$PKG" | grep -qx "package:$PKG" || { echo "Erro: NetherSX2 ($PKG) não instalado" >&2; exit 2; }
"${ADB[@]}" shell "ls '$ROM_PATH'" >/dev/null 2>&1 || { echo "Erro: arquivo não encontrado: $ROM_PATH" >&2; exit 1; }

CMD=(am start --user 0 -n "$PKG/.EmulationActivity" --activity-clear-task --activity-clear-top
     -a android.intent.action.MAIN --es bootPath "'$URI'")
echo "[cmd] ${CMD[*]}"
"${ADB[@]}" logcat -c
"${ADB[@]}" shell "${CMD[@]}"
if [ "$LOGCAT" -eq 1 ]; then
  sleep 5
  echo "[logcat]"
  "${ADB[@]}" logcat -d | grep -iE 'aethersx2|bootPath|SecurityException|FileNotFound|fatal' | tail -n 80 || true
fi
