#!/usr/bin/env python3
"""Gera os metadata.pegasus.txt do console a partir das listas do ES-DE para Android.

Fluxo:
  1. lê tools/esde/es_systems.xml e es_find_rules.xml (ES-DE, licença MIT);
  2. pergunta ao aparelho (adb) quais apps estão instalados e quais pastas de jogos existem
     em <armazenamento>/Games/<sistema>, no interno e no cartão SD;
  3. para cada sistema com jogos, escolhe o primeiro comando do ES-DE cujo emulador está
     instalado (ou o preferido em --emu), traduz para "am start" e grava o metadata.pegasus.txt
     na pasta do sistema; atualiza o game_dirs.txt do Pegasus.
  4. NetherSX2 (bootPath): grava um launch: por jogo com a URI SAF da pasta do sistema, para a
     qual ele já tem permissão (ele não abre {file.path} nem a URI do provider do Pegasus).

Uso:
  tools/gen-pegasus.py [-s SERIAL] [--emu ps2=NETHERSX2 --emu psp="PPSSPP (Standalone)"] [--dry-run]
"""

import argparse
import shlex
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import quote

ESDE = Path(__file__).resolve().parent / "esde"
INTERNAL = "/storage/emulated/0"
GAMES = "Games"
PEGASUS_DIR = f"{INTERNAL}/pegasus-frontend"
EXTERNALDATA = INTERNAL
INTERNALDATA = "/data/data"
# Preferências do console (sobrescritas por --emu)
DEFAULT_PREFS = {"ps2": "NETHERSX2", "psp": "PPSSPP (Standalone)"}

# Tipos de extra do ES-DE -> opção do am
EXTRA_TYPES = {
    "EXTRA": "--es",
    "EXTRABOOL": "--ez",
    "EXTRAINTEGER": "--ei",
    "EXTRALONG": "--el",
    "EXTRASTRINGARRAY": "--esa",
}
FLAGS = {
    "%ACTIVITY_CLEAR_TASK%": "--activity-clear-task",
    "%ACTIVITY_CLEAR_TOP%": "--activity-clear-top",
    "%ACTIVITY_NO_HISTORY%": "--activity-no-history",
}


class Unsupported(Exception):
    pass


def adb(serial, *args):
    cmd = ["adb"] + (["-s", serial] if serial else []) + list(args)
    return subprocess.run(cmd, check=True, capture_output=True, text=True).stdout


def load_find_rules():
    rules = {}
    for emu in ET.parse(ESDE / "es_find_rules.xml").getroot().iter("emulator"):
        entries = [e.text.strip() for r in emu.iter("rule") if r.get("type") == "androidpackage"
                   for e in r.iter("entry") if e.text]
        if entries:
            rules[emu.get("name")] = entries
    return rules


def load_systems():
    systems = []
    for s in ET.parse(ESDE / "es_systems.xml").getroot().iter("system"):
        exts = sorted({e.lstrip(".").lower() for e in (s.findtext("extension") or "").split()})
        cmds = [(c.get("label") or "", c.text.strip()) for c in s.iter("command") if c.text]
        systems.append({"name": s.findtext("name"), "fullname": s.findtext("fullname"),
                        "exts": exts, "cmds": cmds})
    return systems


def resolve_emulator(name, rules, installed):
    for entry in rules.get(name, []):
        pkg = entry.split("/", 1)[0]
        if pkg in installed:
            return entry
    return None


def value(v, pkg, rompath):
    """Traduz o valor de um parâmetro do ES-DE para variáveis do Pegasus.

    `%ROMSAF%` representa uma URI que o app pode abrir via Storage Access Framework;
    `%ROMRAW%` e `%ROM%` representam caminhos brutos do sistema de arquivos.
    """
    if "%INJECT%" in v or "%FILEINJECT%" in v or "%BASENAME%" in v:
        raise Unsupported(v)
    v = (v.replace("%ROMSAF%", "{file.uri}")
          .replace("%ROMPROVIDER%", "{file.uri}")
          .replace("%ROMRAW%", "{file.path}").replace("%ROM%", "{file.path}")
          .replace("%GAMEDIRRAW%", "{file.dir}").replace("%ROMPATHRAW%", rompath)
          .replace("%EXTERNALDATA%", EXTERNALDATA).replace("%INTERNALDATA%", INTERNALDATA)
          .replace("%ANDROIDPACKAGE%", pkg))
    if "%" in v:
        raise Unsupported(v)
    return v


def android_document_uri(root, filename):
    """Build a document URI inside the SAF tree the emulator has permission to read."""
    if root.startswith(f"{INTERNAL}/"):
        volume_id, storage_root = "primary", INTERNAL
    else:
        parts = Path(root).parts
        volume_id, storage_root = parts[2], f"/storage/{parts[2]}"
    tree_id = f"{volume_id}:{Path(root).relative_to(storage_root).as_posix()}"
    document_id = f"{tree_id}/{filename}"
    return ("content://com.android.externalstorage.documents/tree/"
            f"{quote(tree_id, safe='')}/document/{quote(document_id, safe='')}")


def add_game_launches(extra, games, launch_for_file):
    blocks, current = [], []
    for line in extra.splitlines():
        if line.startswith("game:"):
            if current:
                blocks.append(current)
            current = [line]
        elif current:
            current.append(line)
    if current:
        blocks.append(current)

    present, output = set(), []
    for block in blocks:
        filename = next((line.partition(": ")[2] for line in block
                         if line.startswith("file: ")), None)
        if filename not in games:
            output.append("\n".join(block).rstrip())
            continue
        present.add(filename)
        updated = []
        for line in block:
            if line.startswith("launch: "):
                continue
            updated.append(line)
            if line.startswith("file: "):
                updated.append(f"launch: {launch_for_file(filename)}")
        output.append("\n".join(updated).rstrip())

    for filename in sorted(set(games) - present):
        output.append(f"game: {Path(filename).stem}\nfile: {filename}\n"
                      f"launch: {launch_for_file(filename)}")
    return "\n\n".join(output) + "\n" if output else ""


def scraped_games(media_root, system, games):
    """Blocos 'game:' do Skyscraper (saída -f pegasus em <media_root>/<sistema>/), com caminhos
    reescritos para relativos à pasta do sistema no aparelho. Só os jogos que existem lá."""
    meta = media_root / system / "metadata.pegasus.txt"
    if not meta.is_file():
        return "", None
    media = (media_root / system / "media").as_posix()
    blocks, cur = [], []
    for line in meta.read_text(encoding="utf-8").splitlines():
        if line.startswith("game:"):
            if cur:
                blocks.append(cur)
            cur = [line]
        elif cur:
            cur.append(line)
    if cur:
        blocks.append(cur)
    present, out = set(games), []
    for b in blocks:
        fname = None
        lines = []
        for line in b:
            key, sep, val = line.partition(": ")
            if key == "file" and sep:
                fname = val.rsplit("/", 1)[-1]
                line = f"file: {fname}"
            elif key.startswith("assets.") and sep and val.startswith(media + "/"):
                line = f"{key}: media/{val[len(media) + 1:]}"
            lines.append(line)
        if fname in present:
            out.append("\n".join(lines).rstrip())
    return ("\n\n" + "\n\n".join(out) + "\n") if out else "", media_root / system / "media"


class MissingCore(Exception):
    pass


def translate(command, rules, installed, rompath, has_file=lambda path: True):
    """Comando do ES-DE -> linha 'am start' do Pegasus. None se o emulador não está instalado.
    MissingCore se o núcleo libretro pedido ainda não foi baixado no RetroArch."""
    tokens = shlex.split(command)
    if not tokens or not tokens[0].startswith("%EMULATOR_"):
        raise Unsupported(command)
    component = resolve_emulator(tokens[0][len("%EMULATOR_"):-1], rules, installed)
    if not component:
        return None
    pkg = component.split("/", 1)[0]
    out = ["am", "start", "--user", "0", "-n", component]
    for t in tokens[1:]:
        if t in FLAGS:
            out.append(FLAGS[t])
            continue
        key, sep, val = t.partition("=")
        if not sep:
            raise Unsupported(t)
        if key == "%ACTION%":
            out += ["-a", value(val, pkg, rompath)]
        elif key == "%CATEGORY%":
            out += ["-c", value(val, pkg, rompath)]
        elif key == "%DATA%":
            out += ["-d", value(val, pkg, rompath)]
        elif key == "%MIMETYPE%":
            out += ["-t", value(val, pkg, rompath)]
        elif key.startswith("%EXTRA") and "_" in key:
            kind, _, extra = key.strip("%").partition("_")
            if kind not in EXTRA_TYPES:
                raise Unsupported(t)
            if extra in ("AutoStartFile", "rom", "ROM") and "%ROMSAF%" in val:
                val = val.replace("%ROMSAF%", "%ROMRAW%")
            v = value(val, pkg, rompath)
            if v.endswith("_libretro_android.so") and not has_file(v):
                raise MissingCore(v.rsplit("/", 1)[-1])
            out += [EXTRA_TYPES[kind], extra, v]
        else:
            raise Unsupported(t)
    return " ".join(
        shlex.quote(a) if (" " in a or "'" in a or ";" in a) else f"'{a}'" if "{file." in a else a
        for a in out
    )


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-s", "--serial", default="RX8T10JEJXY")
    ap.add_argument("--emu", action="append", default=[], metavar="SISTEMA=EMULADOR",
                    help="emulador preferido: nome do ES-DE (ex.: NETHERSX2) ou rótulo do comando")
    ap.add_argument("--dry-run", action="store_true", help="só mostra, não grava no aparelho")
    ap.add_argument("--media", type=Path, default=Path.home() / "s20fe-build/skyscraper/out",
                    help="saída do Skyscraper (-f pegasus) por sistema: <media>/<sistema>/")
    args = ap.parse_args()
    prefs = {**DEFAULT_PREFS, **dict(p.split("=", 1) for p in args.emu)}

    model = adb(args.serial, "shell", "getprop", "ro.product.model").strip()
    if model != "SM-G780G":
        sys.exit(f"aparelho inesperado: {model!r}")
    installed = {l.split(":", 1)[1].strip() for l in adb(args.serial, "shell", "pm", "list", "packages").splitlines()
                 if l.startswith("package:")}
    roots = [f"{INTERNAL}/{GAMES}"]
    for l in adb(args.serial, "shell", "sm", "list-volumes", "public").splitlines():
        p = l.split()
        if len(p) >= 3 and p[1] == "mounted":
            roots.append(f"/storage/{p[2]}/{GAMES}")

    file_cache = {}

    def has_file(path):
        """Confere com root se o arquivo existe (núcleos ficam em /data/data/<pacote>/cores)."""
        d, name = path.rsplit("/", 1)
        if d not in file_cache:
            out = subprocess.run(["adb", "-s", args.serial, "shell", f"su -c 'ls -1 {d}' 2>/dev/null"],
                                 capture_output=True, text=True).stdout
            file_cache[d] = set(out.split())
        return name in file_cache[d]

    rules, systems = load_find_rules(), load_systems()
    by_name = {s["name"]: s for s in systems}
    dirs = []
    for root in roots:
        listing = adb(args.serial, "shell", f"ls -1 '{root}' 2>/dev/null").split()
        for name in listing:
            sysinfo = by_name.get(name)
            if not sysinfo:
                continue
            path = f"{root}/{name}"
            files = adb(args.serial, "shell", f"ls -1 '{path}' 2>/dev/null").splitlines()
            games = [f for f in files if "." in f and f.rsplit(".", 1)[-1].lower() in sysinfo["exts"]]
            if not games:
                continue
            cmds = sysinfo["cmds"]
            pref = prefs.get(name)
            if pref:
                cmds = sorted(cmds, key=lambda c: not (c[0] == pref or c[1].startswith(f"%EMULATOR_{pref}%")))
            launch = label = None
            missing = []
            for lbl, cmd in cmds:
                try:
                    launch = translate(cmd, rules, installed, root, has_file)
                except Unsupported:
                    continue
                except MissingCore as e:
                    missing.append(str(e))
                    continue
                if launch:
                    label = lbl
                    break
            if not launch:
                hint = f" (núcleos não baixados: {', '.join(missing[:3])})" if missing else ""
                print(f"-- {path}: {len(games)} jogos, nenhum emulador instalado{hint}")
                continue
            meta = (f"# Gerado por tools/gen-pegasus.py a partir do ES-DE (MIT). Não editar à mão.\n"
                    f"collection: {sysinfo['fullname']}\n"
                    f"shortname: {name}\n"
                    f"# só os jogos da pasta principal (subpastas são dados dos emuladores)\n"
                    f"files:\n" + "".join(f"  {g}\n" for g in sorted(games)) +
                    f"# emulador: {label}\n"
                    f"launch: {launch}\n")
            extra, media_dir = scraped_games(args.media, name, games)
            scraped = extra.count("\ngame: ") + extra.startswith("game: ")
            if "--es bootPath '{file.uri}'" in launch:
                extra = add_game_launches(
                    extra,
                    games,
                    lambda filename: launch.replace(
                        "'{file.uri}'", shlex.quote(android_document_uri(path, filename))
                    ),
                )
            meta += extra
            print(f"OK {path}: {len(games)} jogos ({scraped} com capa/dados) -> {label}\n   {launch}")
            dirs.append(path)
            if not args.dry_run:
                with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as tmp:
                    tmp.write(meta)
                adb(args.serial, "push", tmp.name, f"{path}/metadata.pegasus.txt")
                Path(tmp.name).unlink()
                if extra and media_dir.is_dir():
                    adb(args.serial, "shell", f"mkdir -p '{path}/media'")
                    for sub in sorted(p for p in media_dir.iterdir() if p.is_dir()):
                        adb(args.serial, "push", "--sync", str(sub), f"{path}/media/")

    if not args.dry_run and dirs:
        with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as tmp:
            tmp.write("\n".join(dirs) + "\n")
        adb(args.serial, "shell", f"mkdir -p '{PEGASUS_DIR}'")
        adb(args.serial, "push", tmp.name, f"{PEGASUS_DIR}/game_dirs.txt")
        Path(tmp.name).unlink()
        print(f"game_dirs.txt: {len(dirs)} pastas")


if __name__ == "__main__":
    main()
