import importlib

PACKAGES = [
    "foamlib",
    "multicollections",
    "CoolProp.CoolProp",
]

def main():
    for pkg in PACKAGES:
        importlib.import_module(pkg)
        print(f"OK: {pkg}")

if __name__ == "__main__":
    main()
