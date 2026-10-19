#!/usr/bin/env bash
set -u

usage() {
  echo "Uso: $0 [/caminho/para/jogo.iso] [--serial SERIAL] [--logcat]"
  echo
  echo "Testa o comando de lançamento do PS2 no NetherSX2/AetherSX2 usando o formato esperado pelo projeto."
  echo "Se o arquivo estiver fora do Android, o script converte para file:///storage/emulated/0/..."
  exit 1
}

SERIAL=""
LOGCAT=0
TARGET=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --serial)
      SERIAL="$2"
      shift 2
      ;;
    --logcat)
      LOGCAT=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      if [ -z "$TARGET" ]; then
        TARGET="$1"
      else
        echo "Erro: argumento extra: $1" >&2
        usage
      fi
      shift
      ;;
  esac
done

if [ -z "$TARGET" ]; then
  usage
fi

if [ -n "$SERIAL" ]; then
  ADB=(adb -s "$SERIAL")
else
  ADB=(adb)
fi

# Normaliza caminho do jogo para o aparelho.
case "$TARGET" in
  file://*)
    ROM_PATH="${TARGET#file://}"
    ;;
  /storage/*|/data/*)
    ROM_PATH="$TARGET"
    ;;
  *)
    if [ -f "$TARGET" ]; then
      # local do PC: deixa em caminho linux e tenta o equivalente em /storage/emulated/0
      BASE="$(basename "$TARGET")"
      ROM_PATH="/storage/emulated/0/$BASE"
    else
      ROM_PATH="/storage/emulated/0/Games/ps2/$TARGET"
    fi
    ;;
esac

# Tenta primeiro o NetherSX2/AetherSX2 e cai para ARMSX2 se não estiver instalado.
for PKG in xyz.aethersx2.android com.armsx2; do
  case "$PKG" in
    xyz.aethersx2.android)
      ACTIVITY="/.EmulationActivity"
      CMD=("${ADB[@]}" shell am start --user 0 -n "$PKG$ACTIVITY" --activity-clear-task --activity-clear-top -a android.intent.action.MAIN --es bootPath "'$ROM_PATH'")
      ;;
    com.armsx2)
      ACTIVITY="/.MainActivity"
      CMD=("${ADB[@]}" shell am start --user 0 -n "$PKG$ACTIVITY" -a android.intent.action.VIEW --activity-clear-top --es path "'$ROM_PATH'")
      ;;
  esac

  if "${ADB[@]}" shell pm list packages | grep -Fq "$PKG"; then
    echo "[launch] $PKG"
    echo "[cmd] ${CMD[*]}"
    "${CMD[@]}"
    echo
    if [ "$LOGCAT" -eq 1 ]; then
      echo "[logcat]"
      "${ADB[@]}" logcat -d | grep -iE 'aethersx2|nether|ps2|emulation|bootPath|error|fatal' | tail -n 80 || true
    fi
    exit 0
  fi
done

echo "Erro: nenhum emulador PS2 encontrado no aparelho (NetherSX2 ou ARMSX2)." >&2
exit 2
