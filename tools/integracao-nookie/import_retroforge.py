#!/usr/bin/env python3
"""Converte exportações ES-DE do RetroForge para a entrada do gen-pegasus.py.

Uso:
  python tools/integracao-nookie/import_retroforge.py <pasta-exportada>
  python tools/integracao-nookie/import_retroforge.py <pasta-de-um-sistema> --system snes

O programa não copia jogos nem altera a exportação de origem. Metadados e mídias convertidos
vão para ~/s20fe-build/nookieai/out, que pode ser passado a tools/gen-pegasus.py com --media.
"""

import argparse
import hashlib
import re
import shutil
import sys
import xml.etree.ElementTree as ET
from pathlib import Path, PurePosixPath


DEFAULT_OUTPUT = Path.home() / "s20fe-build/nookieai/out"
ASSET_FIELDS = {
    "image": ("box_front", "boxFront"),
    "thumbnail": ("box_front", "boxFront"),
    "marquee": ("marquee", "marquee"),
    "logo": ("logo", "logo"),
    "screenshot": ("screenshot", "screenshot"),
    "fanart": ("background", "background"),
    "video": ("video", "video"),
}


def element_text(parent, name):
    for child in parent:
        if child.tag.rsplit("}", 1)[-1] == name:
            value = " ".join("".join(child.itertext()).split())
            if value:
                return value
    return ""


def safe_system_name(name):
    if not re.fullmatch(r"[A-Za-z0-9_-]+", name):
        raise ValueError(f"nome de sistema inválido: {name!r}")
    return name


def find_gamelists(source):
    if source.is_file():
        if source.name.lower() != "gamelist.xml":
            raise ValueError("o arquivo de entrada precisa se chamar gamelist.xml")
        return [source]
    direct = source / "gamelist.xml"
    if direct.is_file():
        return [direct]
    return sorted(source.rglob("gamelist.xml"))


def asset_source(base, raw_path):
    normalized = raw_path.replace("\\", "/")
    candidate = Path(normalized)
    if not candidate.is_absolute():
        candidate = base / candidate
    try:
        resolved = candidate.resolve(strict=True)
        resolved.relative_to(base.resolve())
    except (OSError, ValueError):
        return None
    return resolved if resolved.is_file() else None


def copy_asset(base, raw_path, output_dir, system, filename, source_tag):
    source = asset_source(base, raw_path)
    if source is None:
        print(f"AVISO {system}/{filename}: mídia ausente ou fora da exportação: {raw_path}",
              file=sys.stderr)
        return None

    safe_stem = re.sub(r"[^A-Za-z0-9._-]+", "_", Path(filename).stem).strip("._") or "jogo"
    digest = hashlib.sha256(filename.encode("utf-8")).hexdigest()[:10]
    suffix = source.suffix.lower() or ".bin"
    relative = PurePosixPath("media", "retroforge", source_tag, f"{safe_stem}-{digest}{suffix}")
    destination = output_dir / Path(*relative.parts)
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    return relative.as_posix()


def release_date(raw):
    match = re.match(r"^(\d{4})(\d{2})?(\d{2})?", raw.strip())
    if not match:
        return ""
    year, month, day = match.groups()
    if month and day:
        return f"{year}-{month}-{day}"
    if month:
        return f"{year}-{month}"
    return year


def rating_percent(raw):
    try:
        value = float(raw.strip())
    except ValueError:
        return ""
    if not 0 <= value <= 1:
        return ""
    return f"{round(value * 100)}%"


def game_block(game, base, output_dir, system):
    raw_game_path = element_text(game, "path")
    filename = raw_game_path.replace("\\", "/").rsplit("/", 1)[-1]
    if not filename:
        return None

    title = element_text(game, "name") or Path(filename).stem
    lines = [f"game: {title}", f"file: {filename}"]
    fields = (
        ("developer", "developer"),
        ("publisher", "publisher"),
        ("genre", "genre"),
        ("players", "players"),
    )
    for source, target in fields:
        value = element_text(game, source)
        if value:
            lines.append(f"{target}: {value}")

    description = element_text(game, "desc")
    if description:
        lines.append(f"description: {description}")

    date = release_date(element_text(game, "releasedate"))
    if date:
        lines.append(f"release: {date}")

    rating = rating_percent(element_text(game, "rating"))
    if rating:
        lines.append(f"rating: {rating}")

    # Se o export tiver image e thumbnail, use image como capa principal.
    image_tags = ["image", "thumbnail"]
    for source_tag, (target, asset_dir) in ASSET_FIELDS.items():
        if source_tag in image_tags:
            continue
        raw_asset = element_text(game, source_tag)
        if raw_asset:
            copied = copy_asset(base, raw_asset, output_dir, system, filename, asset_dir)
            if copied:
                lines.append(f"assets.{target}: {copied}")

    for cover_tag in image_tags:
        raw_asset = element_text(game, cover_tag)
        if raw_asset:
            copied = copy_asset(base, raw_asset, output_dir, system, filename, "boxFront")
            if copied:
                lines.append(f"assets.box_front: {copied}")
                break

    return "\n".join(lines)


def convert(gamelist, system, output_root):
    system = safe_system_name(system)
    try:
        root = ET.parse(gamelist).getroot()
    except (ET.ParseError, OSError) as exc:
        raise ValueError(f"não foi possível ler {gamelist}: {exc}") from exc

    output_dir = output_root / system
    blocks = []
    for game in root:
        if game.tag.rsplit("}", 1)[-1] != "game":
            continue
        block = game_block(game, gamelist.parent, output_dir, system)
        if block:
            blocks.append(block)

    if not blocks:
        print(f"-- {system}: nenhum jogo com caminho em {gamelist}")
        return 0

    output_dir.mkdir(parents=True, exist_ok=True)
    metadata = output_dir / "metadata.pegasus.txt"
    metadata.write_text("\n\n".join(blocks) + "\n", encoding="utf-8", newline="\n")
    print(f"OK {system}: {len(blocks)} jogos -> {metadata}")
    return len(blocks)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="exportação ES-DE ou arquivo gamelist.xml")
    parser.add_argument("--system", help="código ES-DE de destino, como snes ou psx")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT,
                        help=f"pasta de saída (padrão: {DEFAULT_OUTPUT})")
    args = parser.parse_args()

    source = args.input.expanduser().resolve()
    if not source.exists():
        parser.error(f"entrada não encontrada: {source}")
    gamelists = find_gamelists(source)
    if not gamelists:
        parser.error(f"nenhum gamelist.xml encontrado em: {source}")
    if args.system and len(gamelists) != 1:
        parser.error("--system só pode ser usado quando a entrada contém um único gamelist.xml")

    output_root = args.output.expanduser()
    targets = [args.system or gamelist.parent.name for gamelist in gamelists]
    try:
        for target in targets:
            safe_system_name(target)
        if len(set(targets)) != len(targets):
            parser.error("há mais de um gamelist.xml com o mesmo nome de pasta; importe cada um separadamente")
        total = sum(convert(gamelist, target, output_root) for gamelist, target in zip(gamelists, targets))
    except ValueError as exc:
        parser.error(str(exc))
    print(f"Concluído: {total} jogos convertidos. Passe --media '{output_root}' ao gen-pegasus.py.")


if __name__ == "__main__":
    main()
