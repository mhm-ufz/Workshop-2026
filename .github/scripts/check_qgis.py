"""Executed inside the real QGIS application by its --code option."""

import functools
import json
import os
from pathlib import Path
import traceback

result = {"ok": False}
try:
    print("QGIS --code check reached", flush=True)
    from qgis import utils
    from qgis.core import Qgis, QgsApplication, QgsRasterLayer
    from qgis.PyQt.QtCore import QT_VERSION_STR, QTimer

    if not QT_VERSION_STR.startswith("6."):
        raise RuntimeError(f"Expected Qt 6, got {QT_VERSION_STR}")
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
    result = {"ok": True, "qgis": Qgis.QGIS_VERSION, "qt": QT_VERSION_STR}
except Exception:
    result["error"] = traceback.format_exc()
    print(result["error"], flush=True)
finally:
    Path(os.environ["WORKSHOP_CI_REPORT"]).write_text(json.dumps(result))
    if not result["ok"]:
        # An import failure must fail CI, rather than open QGIS's error dialog.
        os._exit(1)
    # Exit after the Qt event loop starts.
    QTimer.singleShot(0, functools.partial(QgsApplication.exit, 0))
