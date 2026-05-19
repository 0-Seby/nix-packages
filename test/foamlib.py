import os
from pathlib import Path
from foamlib import FoamCase

tutorials_env = os.environ.get("FOAM_TUTORIALS")

if not tutorials_env:
    print("OpenFOAM environment is not sourced (FOAM_TUTORIALS not found).")
else:
    print("Found it!")

