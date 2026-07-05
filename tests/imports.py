import importlib

PACKAGES = [
    "foamlib",
    "cadquery",
    "OCP",
    "pyfluids",
    "multicollections",
    "CoolProp.CoolProp",
    "build123d",
    "ocp_vscode"
]

def main():
    for pkg in PACKAGES:
        importlib.import_module(pkg)
        print(f"OK: {pkg}")

if __name__ == "__main__":
    main()
