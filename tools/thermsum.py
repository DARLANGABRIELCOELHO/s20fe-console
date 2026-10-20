#!/usr/bin/env python3
"""Resumo de um teste de resfriamento gravado pelo scripts/thermlog.sh.

Uso: python tools/thermsum.py <termico-*.csv> [--sala 26] [--obs "texto"]

Considera "em carga" as amostras com a GPU acima de 50% de uso (o 3DMark Stress fica perto de
100%; menus e telas de resultado ficam abaixo). Compara com a meta do case
(hardware/README.md, seção 3): GPU abaixo de 80 °C no teto (670 MHz) por 30 min e bateria
abaixo de 40 °C. Imprime também a linha pronta para a tabela da seção 7.
"""
import argparse
import csv
import sys

CARGA = 50          # % de uso da GPU para contar como "em carga"
META_GPU = 80.0
META_BAT = 40.0
PERFD_BAIXA = 88.0  # o perfd baixa um nível da GPU a partir daqui (só com emulador)


def num(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


def ler(caminho):
    meta, dados = {}, []
    with open(caminho, encoding="utf-8", newline="") as f:
        for l in f:
            if l.startswith("#"):   # "# rotulo=... inicio=2026-10-20 05:02:54 ..."
                for kv in l[1:].split():
                    if "=" in kv:
                        k, v = kv.split("=", 1)
                        meta[k] = v
                if "inicio=" in l:
                    meta["inicio"] = l.split("inicio=")[1].split(" minutos=")[0].strip()
            else:
                dados.append(l)
    return meta, list(csv.DictReader(dados))


def fmt_tempo(s):
    return f"{int(s // 60)} min {int(s % 60):02d} s"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv")
    ap.add_argument("--sala", help="temperatura da sala em °C")
    ap.add_argument("--obs", default="")
    a = ap.parse_args()

    meta, linhas = ler(a.csv)
    if not linhas:
        sys.exit("CSV sem amostras")
    for r in linhas:
        r["_t"] = num(r["seg"])
        r["_gpu"] = max(filter(None, [num(r["t_gpu0"]), num(r["t_gpu1"])]), default=None)
        r["_cpu"] = max(filter(None, [num(r["t_cpu0"]), num(r["t_cpu1"])]), default=None)
    carga = [r for r in linhas if (num(r["gpu_busy"]) or 0) >= CARGA]
    if len(carga) < 2:
        sys.exit(f"Só {len(carga)} amostra(s) com a GPU acima de {CARGA}%: o teste de estresse rodou?")

    # duração de cada amostra = intervalo até a próxima (a última herda o anterior)
    def duracoes(rs):
        d = [rs[i + 1]["_t"] - rs[i]["_t"] for i in range(len(rs) - 1)]
        return d + [d[-1] if d else 2]
    passo = dict(zip(map(id, linhas), duracoes(linhas)))
    dur = lambda rs: sum(min(passo[id(r)], 10) for r in rs)  # buracos > 10 s não contam

    teto = max(num(r["gpu_max"]) for r in carga)
    t_carga = dur(carga)
    no_teto = dur([r for r in carga if num(r["gpu_mhz"]) >= teto])
    gpus = [r["_gpu"] for r in carga if r["_gpu"] is not None]
    cpus = [r["_cpu"] for r in carga if r["_cpu"] is not None]
    bats = [num(r["t_bat"]) for r in carga]
    peles = [num(r["t_pele"]) for r in carga if num(r["t_pele"]) is not None]
    usbs = [num(r["t_usb"]) for r in carga if num(r["t_usb"]) is not None]
    gpu_med = sum(gpus) / len(gpus)
    acima_meta = dur([r for r in carga if (r["_gpu"] or 0) >= META_GPU])
    acima_perfd = dur([r for r in carga if (r["_gpu"] or 0) >= PERFD_BAIXA])
    chegou_80 = next((r["_t"] - carga[0]["_t"] for r in carga if (r["_gpu"] or 0) >= META_GPU), None)
    ma = [num(r["bat_ma"]) for r in carga]
    ma_med = sum(ma) / len(ma)
    clocks = [num(r["gpu_mhz"]) for r in carga]
    clock_med = sum(clocks) / len(clocks)
    tv = any(r["tv"] == "connected" for r in carga)

    print(f"Teste: {meta.get('rotulo', '?')}  início {meta.get('inicio', '?')}  "
          f"teto da GPU {teto:.0f} MHz  sala {a.sala or '?'} °C  TV {'ligada' if tv else 'desligada'}")
    print(f"Em carga: {fmt_tempo(t_carga)} ({len(carga)} amostras de {len(linhas)})")
    print(f"GPU: clock médio {clock_med:.0f} MHz, {100 * no_teto / t_carga:.0f}% do tempo no teto; "
          f"temperatura média {gpu_med:.1f} °C, pico {max(gpus):.1f} °C")
    print(f"     acima de {META_GPU:.0f} °C: {fmt_tempo(acima_meta)}"
          + (f" (chegou em {fmt_tempo(chegou_80)})" if chegou_80 is not None else "")
          + f"; acima de {PERFD_BAIXA:.0f} °C: {fmt_tempo(acima_perfd)}")
    print(f"CPU pico {max(cpus):.1f} °C   pele pico {max(peles, default=float('nan')):.1f} °C   "
          f"USB pico {max(usbs, default=float('nan')):.1f} °C")
    print(f"Bateria: {bats[0]:.1f} → pico {max(bats):.1f} °C; carga {carga[0]['bat_pct']}% → "
          f"{carga[-1]['bat_pct']}%; corrente média {ma_med:+.0f} mA "
          f"({'carregando' if ma_med > 0 else 'DESCARREGANDO'})")

    ok_tempo = t_carga >= 30 * 60
    ok_gpu = max(gpus) < META_GPU
    ok_bat = max(bats) < META_BAT
    print("Meta do case (670 MHz, 30 min, GPU < 80 °C, bateria < 40 °C): "
          + ("ATINGIDA" if ok_tempo and ok_gpu and ok_bat and teto >= 670 else "não atingida")
          + f"  [tempo {'ok' if ok_tempo else 'curto'}, GPU {'ok' if ok_gpu else 'quente'}, "
          f"bateria {'ok' if ok_bat else 'quente'}, teto {'ok' if teto >= 670 else f'{teto:.0f}'}]")

    data = meta.get("inicio", "?").split()[0]
    print("\nLinha para a tabela (hardware/README.md, seção 7; preencher a estabilidade do 3DMark):")
    print(f"| {data} | {meta.get('rotulo', '?')}, {teto:.0f} MHz | {a.sala or '?'} °C "
          f"| {gpu_med:.0f}/{max(gpus):.0f} °C | {max(bats):.1f} °C | ? "
          f"| {fmt_tempo(t_carga)} em carga, {100 * no_teto / t_carga:.0f}% no teto, "
          f"{ma_med:+.0f} mA{'; ' + a.obs if a.obs else ''} |")


if __name__ == "__main__":
    main()
