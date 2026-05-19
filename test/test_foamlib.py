import foamlib

def main():
    # Basic import check
    assert foamlib is not None

    # Check that expected API exists (adjust if needed)
    assert hasattr(foamlib, "__version__") or hasattr(foamlib, "__file__")

    print("foamlib import OK")

if __name__ == "__main__":
    main()
