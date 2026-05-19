import multicollections

def main():
    # Basic import check
    assert multicollections is not None

    # Check expected class exists (based on foamlib error: MultiDict)
    assert hasattr(multicollections, "MultiDict"), "MultiDict missing"

    print("multicollections import OK")

if __name__ == "__main__":
    main()
