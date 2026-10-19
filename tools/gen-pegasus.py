#!/usr/bin/env python3
"""Gera os metadata.pegasus.txt do console a partir das listas do ES-DE para Android.

Fluxo:
  1. lê tools/esde/es_systems.xml e es_find_rules.xml (ES-DE, licença MIT);
  2. pergunta ao aparelho (adb) quais apps estão instalados e quais pastas de jogos existem
     em <armazenamento>/Games/<sistema>, no interno e no cartão SD;
  3. para cada sistema com jogos, escolhe o primeiro comando do ES-DE cujo emulador está
     instalado (ou o preferido em --emu), traduz para "am start" e grava o metadata.pegasus.txt
     na pasta do sistema; atualiza o game_dirs.txt do Pegasus.
  4. Emuladores que recebem o jogo num extra com URI (NetherSX2 bootPath, Dolphin AutoStartFile):
     grava um launch: por jogo com a URI SAF da pasta do sistema, que precisa estar liberada no
     emulador (o gerador confere em 'dumpsys activity permissions' e avisa). Eles não abrem
     {file.path} (scoped storage) nem a URI do provider do Pegasus.
     NetherSX2: com o serial e o CRC do jogo (lidos do gamelist.cache do NetherSX2), grava também
     x-nethersx2-serial/-crc/-state e, se o <serial> (<CRC>).resume.p2s já existe, põe
     --es saveStatePath no launch: (o jogo abre onde parou). Sem o arquivo o NetherSX2 recusa o
     extra; o scripts/controller-hotkeys.sh inclui o extra quando o 1º estado é gravado.
  5. Capas e dados: da saída do Skyscraper no PC (--media); se ela não existe neste PC, reaproveita
     os blocos game: do metadata.pegasus.txt que já está no aparelho.

Uso:
  tools/gen-pegasus.py [-s SERIAL] [--emu ps2=NETHERSX2 --emu psp="PPSSPP (Standalone)"] [--dry-run]
"""

import argparse
import re
import shlex
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import quote, unquote

ESDE = Path(__file__).resolve().parent / "esde"
INTERNAL = "/storage/emulated/0"
GAMES = "Games"
PEGASUS_DIR = f"{INTERNAL}/pegasus-frontend"
EXTERNALDATA = INTERNAL
INTERNALDATA = "/data/data"
# Preferências do console (sobrescritas por --emu)
DEFAULT_PREFS = {"ps2": "NETHERSX2", "psp": "PPSSPP (Standalone)"}
NETHER_PKG = "xyz.aethersx2.android"
NETHER_DATA = f"/data/data/{NETHER_PKG}"
NETHER_STATES = f"{INTERNAL}/Android/data/{NETHER_PKG}/files/sstates"

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
    return subprocess.run(cmd, check=True, capture_output=True, text=True,
                          encoding="utf-8").stdout


def adb_su_bytes(serial, command):
    """Saída binária de um comando root no aparelho (vazia se falhar)."""
    cmd = ["adb"] + (["-s", serial] if serial else []) + ["exec-out", f"su -c {shlex.quote(command)}"]
    return subprocess.run(cmd, capture_output=True).stdout


def parse_nether_gamelist(data):
    """gamelist.cache do NetherSX2 -> {URI SAF decodificada: (serial, CRC em hex)}.

    Formato (NetherSX2 2.2n): "GLCE" + u32 versão; por jogo: caminho, serial e título (u32
    tamanho + texto), u8 tipo, u8 região, u64 tamanho, u64 mtime, u32 CRC, u8 compatibilidade.
    """
    games = {}
    if data[:4] != b"GLCE":
        return games
    off = 8

    def text():
        nonlocal off
        n, = struct.unpack_from("<I", data, off)
        off += 4
        value = data[off:off + n].decode("utf-8")
        off += n
        return value

    tail = struct.Struct("<BBQQIB")
    try:
        while off < len(data):
            path, serial, _title = text(), text(), text()
            *_, crc, _compat = tail.unpack_from(data, off)
            off += tail.size
            games[unquote(path)] = (serial, f"{crc:08X}")
    except (struct.error, UnicodeDecodeError):
        pass  # formato inesperado: fica com o que já leu
    return games


def parse_saf_grants(dump):
    """Saída de 'dumpsys activity permissions' -> {pacote: {URI tree decodificada}} das permissões
    SAF persistentes (as que o app ganha ao escolher uma pasta no seletor do Android)."""
    found, uri, pkg = {}, None, None
    for line in dump.splitlines():
        line = line.strip()
        if line.startswith("UriPermission{"):
            uri = line.split()[1]
        elif "targetPkg=" in line:
            pkg = line.split("targetPkg=", 1)[1].split()[0]
        elif "persisted=" in line and "persisted=0x0" not in line and uri and "/tree/" in uri:
            found.setdefault(pkg, set()).add(unquote(uri))
    return found


def nether_state_path(serial, crc):
    return f"{NETHER_STATES}/{serial} ({crc}).resume.p2s"


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


def add_game_launches(extra, games, launch_for_file, fields_for_file=lambda filename: []):
    """Põe launch: (e os campos extras de fields_for_file) em cada bloco game: dos jogos da pasta;
    cria um bloco mínimo para os jogos sem bloco. Campos x-nethersx2-* antigos são trocados."""
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
            if line.startswith(("launch: ", "x-nethersx2-")):
                continue
            updated.append(line)
            if line.startswith("file: "):
                updated.append(f"launch: {launch_for_file(filename)}")
                updated.extend(fields_for_file(filename))
        output.append("\n".join(updated).rstrip())

    for filename in sorted(set(games) - present):
        output.append("\n".join([f"game: {Path(filename).stem}", f"file: {filename}",
                                 f"launch: {launch_for_file(filename)}",
                                 *fields_for_file(filename)]))
    return "\n\n" + "\n\n".join(output) + "\n" if output else ""


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


def device_games(text, games):
    """Blocos game: do metadata.pegasus.txt que já está no aparelho (capas em media/, caminhos já
    relativos), para quando a saída do Skyscraper não está neste PC. Só os jogos que existem."""
    blocks, cur = [], []
    for line in text.splitlines():
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
        fname = next((l.partition(": ")[2] for l in b if l.startswith("file: ")), None)
        if fname in present:
            out.append("\n".join(l for l in b if not l.startswith("launch: ")).rstrip())
    return ("\n\n" + "\n\n".join(out) + "\n") if out else ""


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
            # AutoStartFile (Dolphin) fica com a URI SAF: com targetSdk 36 ele não lê caminho bruto
            if extra in ("rom", "ROM") and "%ROMSAF%" in val:
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
    ap.add_argument("--show", action="store_true", help="com --dry-run: mostra o metadata gerado")
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

    nether_cache = {}

    def nether_info():
        """(jogos do gamelist.cache, estados .resume.p2s existentes)."""
        if not nether_cache:
            games = parse_nether_gamelist(adb_su_bytes(
                args.serial, f"cat {NETHER_DATA}/cache/gamelist.cache"))
            # find, não ls: o ls do Android escapa os espaços ("SLUS-21376\ (5C891FF1)...")
            states = {l.rsplit("/", 1)[-1] for l in adb_su_bytes(
                args.serial, f"find {NETHER_STATES} -maxdepth 1 -type f")
                .decode("utf-8", "replace").splitlines()}
            nether_cache.update(games=games, states=states)
        return nether_cache["games"], nether_cache["states"]

    grants = {}

    def saf_grants():
        """{pacote: pastas SAF (URIs tree decodificadas) com permissão persistente}."""
        if not grants:
            grants.update(parse_saf_grants(adb(args.serial, "shell", "dumpsys", "activity", "permissions")))
        return grants

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
            if media_dir is None:   # sem a saída do Skyscraper neste PC: usa o que está no aparelho
                current = adb(args.serial, "shell", f"cat '{path}/metadata.pegasus.txt' 2>/dev/null")
                extra = device_games(current, games)
            scraped = extra.count("\ngame: ") + extra.startswith("game: ")
            if re.search(r"--es \S+ '\{file\.uri\}'", launch):
                # extra com URI: o {file.uri} do Pegasus é do provider dele (outros apps não abrem);
                # vai uma URI SAF por jogo, dentro da pasta liberada no emulador
                pkg = launch.split(" -n ", 1)[1].split("/", 1)[0]
                tree_id = unquote(android_document_uri(path, "x").split("/document/")[0])
                if tree_id not in saf_grants().get(pkg, set()):
                    print(f"   AVISO: {pkg} não tem permissão (SAF) para {path}; adicione a pasta "
                          f"na lista de jogos do emulador, senão os jogos daqui não abrem")
                is_nether = pkg == NETHER_PKG
                nether_games, states = nether_info() if is_nether else ({}, set())

                def game_launch(filename):
                    uri = android_document_uri(path, filename)
                    cmd = launch.replace("'{file.uri}'", shlex.quote(uri))
                    serial, crc = nether_games.get(unquote(uri), (None, None))
                    state = nether_state_path(serial, crc) if serial else None
                    if state and state.rsplit("/", 1)[1] in states:
                        cmd += f" --es saveStatePath {shlex.quote(state)}"
                    return cmd

                def nether_fields(filename):
                    if not is_nether:
                        return []
                    serial, crc = nether_games.get(
                        unquote(android_document_uri(path, filename)), (None, None))
                    if not serial:
                        print(f"   AVISO: {filename} não está no gamelist.cache do NetherSX2 (abra a "
                              f"lista de jogos dele uma vez); sem serial/CRC, não retoma o estado")
                        return []
                    return [f"x-nethersx2-serial: {serial}", f"x-nethersx2-crc: {crc}",
                            f"x-nethersx2-state: {nether_state_path(serial, crc)}"]

                extra = add_game_launches(extra, games, game_launch, nether_fields)
            meta += extra
            print(f"OK {path}: {len(games)} jogos ({scraped} com capa/dados) -> {label}\n   {launch}")
            dirs.append(path)
            if args.dry_run and args.show:
                print(meta)
            if not args.dry_run:
                with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False,
                                                 encoding="utf-8", newline="\n") as tmp:
                    tmp.write(meta)
                adb(args.serial, "push", tmp.name, f"{path}/metadata.pegasus.txt")
                Path(tmp.name).unlink()
                if extra and media_dir and media_dir.is_dir():
                    adb(args.serial, "shell", f"mkdir -p '{path}/media'")
                    for sub in sorted(p for p in media_dir.iterdir() if p.is_dir()):
                        adb(args.serial, "push", "--sync", str(sub), f"{path}/media/")

    if not args.dry_run and dirs:
        with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False,
                                         encoding="utf-8", newline="\n") as tmp:
            tmp.write("\n".join(dirs) + "\n")
        adb(args.serial, "shell", f"mkdir -p '{PEGASUS_DIR}'")
        adb(args.serial, "push", tmp.name, f"{PEGASUS_DIR}/game_dirs.txt")
        Path(tmp.name).unlink()
        print(f"game_dirs.txt: {len(dirs)} pastas")


if __name__ == "__main__":
    main()
