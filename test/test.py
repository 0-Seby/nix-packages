import os
from pathlib import Path
from foamlib import FoamCase

# 1. Locate the default global tutorials directory from your environment variables
tutorials_env = os.environ.get("FOAM_TUTORIALS")

if not tutorials_env:
    print("❌ Error: OpenFOAM environment is not sourced (FOAM_TUTORIALS not found).")
    print("Please run 'wmRefresh' or source your OpenFOAM bashrc first.")
else:
    # 2. Point directly to a standard tutorial case (e.g., pitzDaily)
    tutorial_path = Path(tutorials_env) / "incompressible/simpleFoam/pitzDaily"
    
    try:
        # 3. Read the case data read-only (Do NOT run case.clone() or case.run())
        case = FoamCase(tutorial_path)
        
        print("✅ foamlib successfully loaded the case structure!")
        print(f"Case Location: {case.path}\n")
        
        # 4. Safely inspect values in the controlDict using dictionary syntax
        print("--- Testing dictionary parsing ---")
        print(f"Application:    {case.control_dict['application']}")
        print(f"Start Time:     {case.control_dict['startTime']}")
        print(f"End Time:       {case.control_dict['endTime']}")
        print(f"Write Interval: {case.control_dict['writeInterval']}")
        
    except Exception as e:
        print(f"❌ Failed to parse OpenFOAM files: {e}")

