import sys
from pathlib import Path
import os
import stat
import subprocess

try:
    import foamlib
    from foamlib import FoamCase
    print("foamlib module import: OK")
except ImportError as e:
    print(f"Error: foamlib is not accessible in this environment. {e}")
    sys.exit(1)

def run_test():
    foam_tutorials = os.environ.get("FOAM_TUTORIALS")
    if not foam_tutorials:
        print("Error: OpenFOAM environment variables are missing.")
        print("Ensure your devshell is properly sourcing 'openfoam-init'.")
        sys.exit(1)
        
    src_cavity_path = Path(foam_tutorials) / "incompressibleFluid" / "cavity"
    if not src_cavity_path.exists():
        print(f"Error: Could not locate the cavity tutorial at {src_cavity_path}")
        sys.exit(1)

    test_run_dir = Path("./tests/sandbox_cavity")

    # 1. Force cleanup any old directory remnants cleanly
    if test_run_dir.exists():
        subprocess.run(["chmod", "-R", "+w", str(test_run_dir)], capture_output=True)
        subprocess.run(["rm", "-rf", str(test_run_dir)], check=True)

    try:
        # 2. Duplicate the tutorial natively via shell to ensure a clean baseline file copy
        print(f"Staging template files via system copy to: {test_run_dir}")
        subprocess.run(["cp", "-r", str(src_cavity_path), str(test_run_dir)], check=True)
        
        # 3. IMMEDIATELY blast user write permissions across the entire tree before foamlib touches it
        subprocess.run(["chmod", "-R", "+w", str(test_run_dir)], check=True)
        
        # 4. Now hand over the cleanly prepared, writeable directory to FoamCase safely
        case = FoamCase(test_run_dir)
        print(f"Successfully loaded writeable case. Real name: {case.name}")
        
        # 5. Inspect dictionary parameters
        stop_at = case.control_dict.get("stopAt", "Unknown")
        print(f"Current controlDict 'stopAt' setting: {stop_at}")
        
        # 6. Run mesh generator
        print("Running OpenFOAM 'blockMesh'...")
        case.block_mesh()
        print("Mesh generated successfully!")

        # 7. Run the solver
        print("Executing physics solver...")
        case.run()
        print("Solver finished computing time steps.")
        
        # 8. Verify data execution
        time_dirs = [t.name for t in case if t.name not in ["0", "constant", "system", "log.blockMesh", "log.incompressibleFluid"]]
        # Filter out purely numeric directories to confirm simulation intervals were saved
        numeric_time_dirs = [t for t in time_dirs if t.replace('.', '', 1).isdigit()]
        
        if numeric_time_dirs:
            print(f"Detected generated simulation states: {numeric_time_dirs}")
            print("foamlib functionality test: PASSED")
            
            # Clean up on success
            subprocess.run(["rm", "-rf", str(test_run_dir)], check=True)
            sys.exit(0)
        else:
            print("Error: The simulation executed but no output time directories were generated.")
            sys.exit(1)

    except Exception as e:
        print(f"foamlib execution failed: {e}")
        # Leave sandbox folder intact on failure for manual troubleshooting
        sys.exit(1)

if __name__ == "__main__":
    run_test()
