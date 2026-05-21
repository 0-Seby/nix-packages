import sys

try:
    # 1. Test basic imports
    import OCP
    from OCP.gp import gp_Pnt, gp_Dir, gp_Ax2
    from OCP.BRepPrimAPI import BRepPrimAPI_MakeBox, BRepPrimAPI_MakeCylinder
    from OCP.BRepAlgoAPI import BRepAlgoAPI_Fuse
    
    print(f"OCP version/import: OK (Python {sys.version.split()[0]})")

    # 2. Instantiate core primitives (verifies constructor bindings)
    print("Creating geometric primitives...")
    box = BRepPrimAPI_MakeBox(10.0, 20.0, 30.0).Shape()
    
    # Create a cylinder along the Z-axis offset slightly
    axes = gp_Ax2(gp_Pnt(5.0, 5.0, 0.0), gp_Dir(0.0, 0.0, 1.0))
    cylinder = BRepPrimAPI_MakeCylinder(axes, 3.0, 40.0).Shape()

    # 3. Perform a boolean operation (verifies heavy modeling kernel linkage)
    print("Performing boolean fusion...")
    fusion = BRepAlgoAPI_Fuse(box, cylinder)
    fusion.Build()
    
    if fusion.IsDone():
        fused_shape = fusion.Shape()
        print("OCP functionality test: PASSED")
    else:
        print("OCP Error: Boolean operations failed to build.")
        sys.exit(1)

except ImportError as e:
    print(f"OCP import failed: {e}")
    sys.exit(1)
except Exception as e:
    print(f"OCP execution failed: {e}")
    sys.exit(1)
