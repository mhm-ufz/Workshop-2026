"""Start QGIS from the pixi environment on Windows.

qgis.exe looks for DLLs in every folder on PATH, in no fixed order. If another
Python is on PATH (e.g. C:\\Python314 from python.org), QGIS can load its
python3xx.dll instead of the environment's, and Python support fails with
"No module named 'PyQt6'". This removes such folders from PATH for QGIS only.

Usage: python start_qgis.py [QGIS arguments ...]
"""
import os
import shutil
import subprocess
import sys

ENV_DIR = os.path.normcase(os.path.abspath(sys.prefix))


def other_python(folder):
    """True if the folder holds a Python DLL that is not from this environment."""
    path = os.path.normcase(os.path.abspath(folder))
    if path == ENV_DIR or path.startswith(ENV_DIR + os.sep):
        return False
    try:
        names = os.listdir(folder)
    except OSError:
        return False
    return any(name.lower().startswith("python3") and name.lower().endswith(".dll") for name in names)


def main():
    folders = [f for f in os.environ.get("PATH", "").split(os.pathsep) if f.strip()]
    os.environ["PATH"] = os.pathsep.join(f for f in folders if not other_python(f.strip('"')))
    qgis = shutil.which("qgis")
    if not qgis:
        sys.exit("QGIS not found in the environment")
    sys.exit(subprocess.call([qgis, *sys.argv[1:]]))


if __name__ == "__main__":
    main()
