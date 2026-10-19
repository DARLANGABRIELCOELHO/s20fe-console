import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "gen_pegasus",
    Path(__file__).resolve().parents[1] / "tools" / "gen-pegasus.py",
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def test_nether_bootpath_uses_daijisho_saf_uri():
    rules = {"NETHERSX2": ["xyz.aethersx2.android/.EmulationActivity"]}
    installed = {"xyz.aethersx2.android"}
    cmd = mod.translate(
        "%EMULATOR_NETHERSX2% %ACTIVITY_CLEAR_TASK% %ACTIVITY_CLEAR_TOP% %ACTION%=android.intent.action.MAIN %EXTRA_bootPath%=%ROMSAF%",
        rules,
        installed,
        "/storage/emulated/0/Games/ps2/Metal Gear Solid 2.iso",
    )
    assert "--es bootPath '{file.uri}'" in cmd
    uri = mod.android_document_uri(
        "/storage/emulated/0/Games/ps2", "Metal Gear Solid 2.iso"
    )
    assert uri == (
        "content://com.android.externalstorage.documents/tree/primary%3AGames%2Fps2/"
        "document/primary%3AGames%2Fps2%2FMetal%20Gear%20Solid%202.iso"
    )
    extra = mod.add_game_launches(
        "", ["Metal Gear Solid 2.iso"], lambda filename: f"am start --es bootPath {uri}"
    )
    assert "game: Metal Gear Solid 2\nfile: Metal Gear Solid 2.iso" in extra
    assert f"launch: am start --es bootPath {uri}" in extra


def test_data_uses_saf_uri():
    rules = {"ARMSX2": ["com.armsx2/.MainActivity"]}
    installed = {"com.armsx2"}
    cmd = mod.translate(
        "%EMULATOR_ARMSX2% %ACTION%=android.intent.action.VIEW %DATA%=%ROMSAF%",
        rules,
        installed,
        "/storage/emulated/0/Games/ps2/Black.iso",
    )
    assert "-d '{file.uri}'" in cmd


def _glc_entry(path, serial, title, crc):
    import struct
    out = b""
    for text in (path, serial, title):
        raw = text.encode()
        out += struct.pack("<I", len(raw)) + raw
    return out + struct.pack("<BBQQIB", 0, 6, 1197004999, 1792421499000, crc, 5)


def test_parse_nether_gamelist():
    # o NetherSX2 grava a URI sem codificar os parênteses; a chave é a URI decodificada
    path = ("content://com.android.externalstorage.documents/tree/primary%3AGames%2Fps2/"
            "document/primary%3AGames%2Fps2%2FBlack%20(USA).chd")
    data = b"GLCE" + b"\x20\0\0\0" + _glc_entry(path, "SLUS-21376", "Black", 0x5C891FF1)
    games = mod.parse_nether_gamelist(data + b"\x01\x02")   # lixo no fim é ignorado
    ours = mod.android_document_uri("/storage/emulated/0/Games/ps2", "Black (USA).chd")
    assert games[mod.unquote(ours)] == ("SLUS-21376", "5C891FF1")
    assert mod.parse_nether_gamelist(b"outro formato") == {}


def test_nether_fields_replace_old_ones():
    old = ("game: Black\nfile: Black (USA).chd\nlaunch: velho\nx-nethersx2-crc: VELHO\n"
           "assets.boxFront: media/covers/Black.png")
    extra = mod.add_game_launches(
        old, ["Black (USA).chd"], lambda f: "am start novo",
        lambda f: ["x-nethersx2-crc: 5C891FF1"])
    assert extra.strip().splitlines() == ["game: Black", "file: Black (USA).chd", "launch: am start novo",
                                  "x-nethersx2-crc: 5C891FF1",
                                  "assets.boxFront: media/covers/Black.png"]


def test_device_games_keeps_existing_blocks():
    current = ("collection: PS2\nlaunch: am start x\n\ngame: Black\nfile: Black (USA).chd\n"
               "launch: am start y\nassets.boxFront: media/covers/Black.png\n\n"
               "game: Apagado\nfile: Apagado.iso\n")
    extra = mod.device_games(current, ["Black (USA).chd"])
    assert "assets.boxFront: media/covers/Black.png" in extra
    assert "launch:" not in extra and "Apagado" not in extra


if __name__ == "__main__":
    test_nether_bootpath_uses_daijisho_saf_uri()
    test_data_uses_saf_uri()
    test_parse_nether_gamelist()
    test_nether_fields_replace_old_ones()
    test_device_games_keeps_existing_blocks()
    print("gen-pegasus checks passed")
