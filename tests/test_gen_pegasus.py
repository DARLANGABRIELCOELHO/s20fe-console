import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "gen_pegasus",
    Path(__file__).resolve().parents[1] / "tools" / "gen-pegasus.py",
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def test_nether_bootpath_uses_raw_path():
    rules = {"NETHERSX2": ["xyz.aethersx2.android/.EmulationActivity"]}
    installed = {"xyz.aethersx2.android"}
    cmd = mod.translate(
        "%EMULATOR_NETHERSX2% %ACTIVITY_CLEAR_TASK% %ACTIVITY_CLEAR_TOP% %ACTION%=android.intent.action.MAIN %EXTRA_bootPath%=%ROMSAF%",
        rules,
        installed,
        "/storage/emulated/0/Games/ps2/Metal Gear Solid 2.iso",
    )
    assert "--es bootPath '{file.path}'" in cmd
    expanded = cmd.replace("{file.path}", "/storage/emulated/0/Games/ps2/Metal Gear Solid 2.iso")
    assert mod.shlex.split(expanded)[-1] == "/storage/emulated/0/Games/ps2/Metal Gear Solid 2.iso"


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


if __name__ == "__main__":
    test_nether_bootpath_uses_raw_path()
    test_data_uses_saf_uri()
    print("PS2 launch path checks passed")
