"""Diagnose blocked startup before QGIS loads plugins or its --code script."""

import faulthandler
import os
import sys


# Keep the descriptor alive for the embedded interpreter's lifetime. If a
# dependency dialog blocks startup, dump the Python stack and fail before the
# parent's 180-second timeout. This hook is enabled only by the CI check.
sys._workshop_ci_diagnostic = open(
    os.environ["WORKSHOP_CI_DIAGNOSTIC"], "w", buffering=1
)
sys._workshop_ci_diagnostic.write("QGIS Python startup reached; loading bindings and plugins\n")
faulthandler.enable(file=sys._workshop_ci_diagnostic)
faulthandler.dump_traceback_later(150, file=sys._workshop_ci_diagnostic, exit=True)
