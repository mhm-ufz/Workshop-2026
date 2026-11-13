"""Exercise the installed workshop, then check that updating preserves user files."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

from PyQt6.QtCore import QSettings
import xarray as xr


PROFILE = Path("qgis-profiles/profiles/workshop")
PLUGIN = PROFILE / "python/plugins/mhm_qgis"
INI = PROFILE / "QGIS/QGIS4.ini"
OUTPUT = Path("test_domain/output_b1/mRM_Fluxes_States.nc")
STATE = Path(".ci-update-state.json")
OBSOLETE = PLUGIN / "obsolete-ci-file.txt"
HELPER = Path("tools/start_qgis.py")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def profile_settings():
    return QSettings(str(INI.resolve()), QSettings.Format.IniFormat)


def check_update():
    state = json.loads(STATE.read_text())
    for filename, expected in state["files"].items():
        if digest(Path(filename)) != expected:
            raise RuntimeError(f"Update changed a user file: {filename}")
    if profile_settings().value("WorkshopCI/preserved") != "yes":
        raise RuntimeError("Update lost the custom QGIS profile setting")
    if OBSOLETE.exists():
        raise RuntimeError("Update did not replace the old plugin")
    if digest(HELPER) != state["helper"]:
        raise RuntimeError("Update did not refresh the tools folder")
    print("Update preserved user files and settings, and refreshed tools/plugin", flush=True)


def check_installation():
    if not (PLUGIN / "metadata.txt").is_file():
        raise RuntimeError("The mHM QGIS plugin was not installed")
    if profile_settings().value("PythonPlugins/mhm_qgis", type=bool) is not True:
        raise RuntimeError("The mHM QGIS plugin was not enabled")
    if not Path("test_domain/NOTICE.md").is_file():
        raise RuntimeError("The test-domain notice was not copied")

    # Test the public task and its default domain, not just an import of mhm.
    subprocess.run(["pixi", "run", "test-mhm"], check=True, timeout=300)
    with xr.open_dataset(OUTPUT) as dataset:
        if not dataset.data_vars or not all(size > 0 for size in dataset.sizes.values()):
            raise RuntimeError("The test run produced an empty mRM output")
        dataset.load()  # Also exercise the installed NetCDF libraries.
    print(f"mHM produced readable output: {OUTPUT}", flush=True)

    # Run the actual qgis task (including the Windows launcher and DLL loading).
    # The in-app script reports success only after checking the enabled plugin.
    report = Path(".ci-qgis-result.json").resolve()
    report.unlink(missing_ok=True)
    script = Path(__file__).with_name("check_qgis.py").resolve()
    subprocess.run(
        ["pixi", "run", "qgis", "--nologo", "--code", str(script)],
        env={**os.environ, "WORKSHOP_CI_REPORT": str(report)},
        check=True,
        timeout=180,
    )
    result = json.loads(report.read_text())
    if not result["ok"]:
        raise RuntimeError(result["error"])
    print(f"QGIS, mHM plugin, GDAL and ncv imports passed: {result}", flush=True)


def prepare_update():
    namelist = Path("test_domain/mhm.nml")
    with namelist.open("a") as handle:
        handle.write("\n! Local edit that the update must preserve.\n")
    user_file = Path("test_domain/workshop-ci-user-file.txt")
    user_file.write_text("Keep local workshop files.\n")
    settings = profile_settings()
    settings.setValue("WorkshopCI/preserved", "yes")
    settings.sync()
    STATE.write_text(json.dumps({
        "files": {str(path): digest(path) for path in (namelist, OUTPUT, user_file)},
        "helper": digest(HELPER),
    }))
    OBSOLETE.write_text("The plugin should be replaced during update.\n")
    HELPER.write_text("# The update must restore the bundled helper.\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--prepare-update", action="store_true")
    mode.add_argument("--after-update", action="store_true")
    args = parser.parse_args()
    if args.after_update:
        check_update()
    check_installation()
    if args.prepare_update:
        prepare_update()


if __name__ == "__main__":
    main()
