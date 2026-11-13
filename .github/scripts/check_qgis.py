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


result = {"ok": False, "phase": "waiting_for_event_loop"}


def write_result():
    Path(os.environ["WORKSHOP_CI_REPORT"]).write_text(json.dumps(result))


def fail_check():
    result.update(ok=False, error=traceback.format_exc())
    print(result["error"], flush=True)
    write_result()
    # Fail CI rather than opening QGIS's Python error dialog.
    os._exit(1)


def record_quit():
    if result["phase"] != "closing":
        result.update(ok=False, error="QGIS quit before the smoke check completed")
    result["phase"] = "quit_signal_received"
    write_result()
    print("QGIS quit signal received", flush=True)


def check_and_close():
    try:
        from qgis import utils
        from qgis.core import QgsApplication
        from qgis.PyQt.QtCore import QThread, QTimer
        from qgis.PyQt.QtWidgets import QLabel

        # --code runs before app.exec(). Startup may process pending events in
        # the meantime, so a zero-delay timer alone does not establish readiness.
        if QThread.currentThread().loopLevel() == 0:
            QTimer.singleShot(50, check_and_close)
            return

        app = QgsApplication.instance()
        dialog = app.activeModalWidget()
        if dialog is not None:
            text = " ".join(label.text() for label in dialog.findChildren(QLabel))
            raise RuntimeError(f"QGIS is waiting for a dialog: {dialog.windowTitle()}: {text}")

        if result["phase"] == "waiting_for_event_loop":
            result.update(check_qgis(), phase="checks_passed")
            write_result()
            print("QGIS in-app checks passed; waiting for startup tasks before closing", flush=True)

        # QGIS's normal close path asks for confirmation if tasks are active.
        # Keep the event loop running until they finish instead of opening that
        # unattended prompt. The startup watchdog still bounds this wait.
        tasks = QgsApplication.taskManager().activeTasks()
        if tasks:
            descriptions = [task.description() for task in tasks]
            if result.get("pending_tasks") != descriptions:
                result["pending_tasks"] = descriptions
                write_result()
                print(f"Waiting for QGIS tasks: {descriptions}", flush=True)
            QTimer.singleShot(100, check_and_close)
            return

        result.pop("pending_tasks", None)
        result["phase"] = "closing"
        write_result()
        print("Closing QGIS from the running event loop", flush=True)
        utils.iface.mainWindow().close()
    except Exception:
        fail_check()


try:
    from qgis.core import QgsApplication
    from qgis.PyQt.QtCore import QTimer

    write_result()
    QgsApplication.instance().aboutToQuit.connect(record_quit)
    QTimer.singleShot(0, check_and_close)
except Exception:
    fail_check()
