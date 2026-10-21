#!/usr/bin/env python3
"""Inspeciona a arquitetura ELF de um AppImage ou de uma pasta extraída, sem executá-lo."""

import argparse
import struct
from pathlib import Path


MACHINES = {
    3: "x86 (i386)",
    40: "ARM (32-bit)",
    62: "x86-64",
    183: "ARM64 (AArch64)",
    243: "RISC-V",
}


def elf_description(path):
    try:
        with path.open("rb") as stream:
            header = stream.read(20)
    except OSError as exc:
        return None, f"não foi possível ler: {exc}"

    if len(header) < 20 or header[:4] != b"\x7fELF":
        return None, None

    elf_class = {1: "ELF32", 2: "ELF64"}.get(header[4], f"classe {header[4]}")
    byte_order = {1: "<", 2: ">"}.get(header[5])
    if byte_order is None:
        return None, f"ELF com codificação de byte desconhecida ({header[5]})"

    machine = struct.unpack(f"{byte_order}H", header[18:20])[0]
    architecture = MACHINES.get(machine, f"e_machine {machine}")
    return f"{elf_class}, {architecture}", None


def inspect_path(path):
    if path.is_file():
        description, error = elf_description(path)
        if error:
            print(f"ERRO {path}: {error}")
            return 1
        if description is None:
            print(f"ERRO {path}: o arquivo não começa com um cabeçalho ELF")
            return 1
        print(f"{path}: {description}")
        return 0

    if not path.is_dir():
        print(f"ERRO: caminho não encontrado: {path}")
        return 1

    found = 0
    architectures = {}
    for candidate in sorted(path.rglob("*")):
        if not candidate.is_file():
            continue
        description, error = elf_description(candidate)
        if error:
            print(f"AVISO {candidate}: {error}")
        elif description:
            print(f"{candidate.relative_to(path)}: {description}")
            architectures[description] = architectures.get(description, 0) + 1
            found += 1

    if not found:
        print(f"Nenhum ELF encontrado em {path}")
        return 1

    summary = ", ".join(f"{arch}: {count}" for arch, count in sorted(architectures.items()))
    print(f"Total: {found} ELF(s) — {summary}")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", type=Path, help="AppImage Linux ou pasta AppDir já extraída")
    args = parser.parse_args()
    return inspect_path(args.path.expanduser())


if __name__ == "__main__":
    raise SystemExit(main())
