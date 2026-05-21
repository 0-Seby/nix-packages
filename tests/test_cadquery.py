import sys

try:
    import cadquery as cq
    from cadquery.vis import show_object
    print(f"cadquery import: OK")
except ImportError as e:
    print(f"Error: cadquery is not accessible in this environment. {e}")
    sys.exit(1)


def run_test():
    try:
        # 1. Basic solid creation
        print("Creating basic solids...")
        box = cq.Workplane("XY").box(10, 20, 30)
        assert box.val() is not None, "Box creation failed"

        cylinder = cq.Workplane("XY").cylinder(40, 5)
        assert cylinder.val() is not None, "Cylinder creation failed"

        sphere = cq.Workplane("XY").sphere(8)
        assert sphere.val() is not None, "Sphere creation failed"

        # 2. Boolean operations
        print("Performing boolean operations...")
        union = (
            cq.Workplane("XY")
            .box(10, 10, 10)
            .union(cq.Workplane("XY").cylinder(15, 3))
        )
        assert union.val() is not None, "Boolean union failed"

        cut = (
            cq.Workplane("XY")
            .box(20, 20, 20)
            .cut(cq.Workplane("XY").cylinder(25, 5))
        )
        assert cut.val() is not None, "Boolean cut failed"

        # 3. Sketch-based operations (extrude, revolve)
        print("Testing sketch-based operations...")
        extruded = (
            cq.Workplane("XY")
            .rect(15, 10)
            .extrude(5)
        )
        assert extruded.val() is not None, "Extrude failed"

        revolved = (
            cq.Workplane("XZ")
            .moveTo(5, 0)
            .lineTo(5, 10)
            .lineTo(8, 10)
            .lineTo(8, 0)
            .close()
            .revolve()
        )
        assert revolved.val() is not None, "Revolve failed"

        # 4. Feature operations (fillet, chamfer, shell)
        print("Testing feature operations...")
        filleted = (
            cq.Workplane("XY")
            .box(20, 20, 20)
            .edges("|Z")
            .fillet(2)
        )
        assert filleted.val() is not None, "Fillet failed"

        chamfered = (
            cq.Workplane("XY")
            .box(20, 20, 20)
            .edges("|Z")
            .chamfer(1)
        )
        assert chamfered.val() is not None, "Chamfer failed"

        shelled = (
            cq.Workplane("XY")
            .box(20, 20, 20)
            .faces(">Z")
            .shell(-2)
        )
        assert shelled.val() is not None, "Shell failed"

        # 5. Hole operations
        print("Testing hole operations...")
        with_holes = (
            cq.Workplane("XY")
            .box(30, 30, 10)
            .faces(">Z")
            .workplane()
            .rect(15, 15, forConstruction=True)
            .vertices()
            .cboreHole(2, 3.5, 2)
        )
        assert with_holes.val() is not None, "cboreHole failed"

        # show_object(with_holes)

        # 6. Assembly
        print("Testing assembly...")
        box_part = cq.Workplane("XY").box(5, 5, 5)
        cyl_part = cq.Workplane("XY").cylinder(8, 1.5)

        assy = (
            cq.Assembly()
            .add(box_part, name="box", loc=cq.Location(cq.Vector(0, 0, 0)))
            .add(cyl_part, name="cylinder", loc=cq.Location(cq.Vector(10, 0, 0)))
        )
        assert assy is not None, "Assembly creation failed"
        assert len(assy.children) == 2, f"Expected 2 assembly children, got {len(assy.children)}"

        # 7. Export (STEP and STL to /dev/null equivalent — just verify no exception)
        print("Testing STEP export...")
        import tempfile, os
        with tempfile.NamedTemporaryFile(suffix=".step", delete=False) as f:
            step_path = f.name
        try:
            cq.exporters.export(box, step_path)
            assert os.path.getsize(step_path) > 0, "STEP export produced empty file"
        finally:
            os.unlink(step_path)

        print("Testing STL export...")
        with tempfile.NamedTemporaryFile(suffix=".stl", delete=False) as f:
            stl_path = f.name
        try:
            cq.exporters.export(box, stl_path)
            assert os.path.getsize(stl_path) > 0, "STL export produced empty file"
        finally:
            os.unlink(stl_path)

        print("cadquery functionality test: PASSED")
        sys.exit(0)

    except Exception as e:
        print(f"cadquery execution failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    run_test()
