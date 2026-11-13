"""Executed inside the real QGIS application by its --code option."""

import json
import os
from pathlib import Path
import traceback


def check_qgis():
    # Keep QGIS objects local: providers must be destroyed before QGIS tears
    # down its registries, rather than during Python interpreter finalization.
    print("QGIS --code check reached", flush=True)
    from qgis import utils
    from qgis.core import Qgis, QgsRasterLayer
    from qgis.PyQt.QtCore import QT_VERSION_STR, QSettings

    if not QT_VERSION_STR.startswith("6."):
        raise RuntimeError(f"Expected Qt 6, got {QT_VERSION_STR}")
    settings = QSettings()
    settings_file = Path(settings.fileName()).resolve()
    if settings_file != Path(os.environ["WORKSHOP_CI_SETTINGS"]).resolve():
        raise RuntimeError(f"QGIS is reading a different settings file: {settings_file}")
    if not settings.value("PythonPlugins/mhm_qgis", False, type=bool):
        raise RuntimeError(f"mHM plugin is not enabled in QGIS's settings: {settings_file}")
    if "mhm_qgis" not in utils.active_plugins:
        raise RuntimeError(f"mHM plugin did not load; active plugins: {utils.active_plugins}")

    from mhm_qgis.dependency_bootstrap import last_bootstrap_result

    bootstrap = last_bootstrap_result()
    if bootstrap is None or not bootstrap.ok:
        raise RuntimeError(f"The plugin's dependency check failed: {bootstrap}")

    # Import ncv's GUI code alongside QGIS to detect Qt/backend conflicts.
    from ncv.app import ncv
    from osgeo import gdal_array

    raster = QgsRasterLayer(str(Path("test_domain/input/morph/dem.asc").resolve()), "DEM")
    if not raster.isValid():
        raise RuntimeError("QGIS could not open the test-domain DEM")
    return {
        "ok": True,
        "qgis": Qgis.QGIS_VERSION,
        "qt": QT_VERSION_STR,
        "settings": str(settings_file),
    }


result = {"ok": False}
try:
    result = check_qgis()
except Exception:
    result["error"] = traceback.format_exc()
    print(result["error"], flush=True)
finally:
    Path(os.environ["WORKSHOP_CI_REPORT"]).write_text(json.dumps(result))
    if not result["ok"]:
        # An import failure must fail CI, rather than open QGIS's error dialog.
        os._exit(1)
    from qgis import utils
    from qgis.PyQt.QtCore import QTimer

    # Use the same shutdown path as closing QGIS, including project cleanup.
    QTimer.singleShot(0, utils.iface.mainWindow().close)
