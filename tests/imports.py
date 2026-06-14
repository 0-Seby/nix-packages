import importlib

PACKAGES = [
    "foamlib",
    "cadquery",
    "OCP",
    "pyfluids",
    "multicollections",
    "CoolProp.CoolProp",
]

def main():
    for pkg in PACKAGES:
        importlib.import_module(pkg)
        print(f"OK: {pkg}")

if __name__ == "__main__":
    main()
