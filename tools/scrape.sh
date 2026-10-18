#!/bin/bash
# Busca capas, vídeos e dados dos jogos do console com o Skyscraper (ScreenScraper) e gera a
# saída para o tools/gen-pegasus.py. Os jogos não são copiados: o Skyscraper identifica pelo
# nome do arquivo (cria no PC arquivos vazios com os mesmos nomes).
#
# Uso: tools/scrape.sh [sistema ...]     (padrão: todas as pastas Games/<sistema> do aparelho)
# Depois: tools/gen-pegasus.py
# Credenciais do ScreenScraper: ~/.skyscraper/config.ini, seção [screenscraper], userCreds="usuario:senha"
set -euo pipefail
SERIAL=${SERIAL:-RX8T10JEJXY}
W=${W:-$HOME/s20fe-build/skyscraper}
A="adb -s $SERIAL"
[ "$($A shell getprop ro.product.model | tr -d '\r')" = SM-G780G ] || { echo "aparelho inesperado"; exit 1; }

roots="/storage/emulated/0/Games"
for uuid in $($A shell sm list-volumes public | awk '$2=="mounted"{print $3}' | tr -d '\r'); do
  roots="$roots /storage/$uuid/Games"
done

declare -A dirs
for r in $roots; do
  for s in $($A shell "ls -1 '$r' 2>/dev/null" | tr -d '\r'); do
    [ "$s" = bios ] && continue
    dirs[$s]="${dirs[$s]:-} $r/$s"
  done
done
systems=("$@")
[ ${#systems[@]} -gt 0 ] || systems=("${!dirs[@]}")

for s in "${systems[@]}"; do
  [ -n "${dirs[$s]:-}" ] || { echo "-- $s: pasta não encontrada no aparelho"; continue; }
  echo "===== $s"
  rm -rf "$W/roms/$s" && mkdir -p "$W/roms/$s"
  for d in ${dirs[$s]}; do
    $A shell "ls -1 '$d'" | tr -d '\r' | grep -v '^metadata\.pegasus\.txt$' | while IFS= read -r f; do
      [ "$f" = media ] || [ "$f" = PSP ] && continue
      : > "$W/roms/$s/$f"
    done
  done
  Skyscraper -p "$s" -s screenscraper -i "$W/roms/$s" --flags unattend,onlymissing,videos 2>&1 \
    | grep -E "^#[0-9]+/|Search match|Successfully|Skipped games" || true
  rm -rf "$W/out/$s" && mkdir -p "$W/out/$s"
  Skyscraper -p "$s" -f pegasus -i "$W/roms/$s" -g "$W/out/$s" -o "$W/out/$s/media" --flags unattend,videos 2>&1 \
    | grep -E "Successfully|Skipped games" || true
done
