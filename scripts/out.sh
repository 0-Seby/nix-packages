#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash coreutils file findutils

# Default values
INCLUDE_HIDDEN=false
TARGET_PATH=""
EXCLUDE_EXTS=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --include-hidden) INCLUDE_HIDDEN=true ;;
        --exclude) shift; EXCLUDE_EXTS="$1" ;;
        *) TARGET_PATH="$1" ;;
    esac
    shift
done

# Validation
if [[ -z "$TARGET_PATH" ]]; then
    echo "Usage: $0 [--include-hidden] [--exclude hxx,tmp,log] <directory_or_file_path>"
    exit 1
fi

if [[ ! -e "$TARGET_PATH" ]]; then
    echo "Error: Path '$TARGET_PATH' does not exist."
    exit 1
fi

# Determine output filename
if [[ -d "$TARGET_PATH" ]]; then
    DIR_NAME=$(basename "$(realpath "$TARGET_PATH")")
    OUT_FILE="${DIR_NAME}_out.txt"
else
    OUT_FILE="$(basename "$TARGET_PATH")_out.txt"
fi

# Build find command
FIND_CMD=(find -P "$TARGET_PATH" -type f ! -name "$OUT_FILE")

# Handle hidden files
if [[ "$INCLUDE_HIDDEN" == false ]]; then
    FIND_CMD+=( -not -path '*/.*' )
fi

# Handle exclusions (comma-separated to find patterns)
if [[ -n "$EXCLUDE_EXTS" ]]; then
    IFS=',' read -ra ADDR <<< "$EXCLUDE_EXTS"
    for ext in "${ADDR[@]}"; do
        FIND_CMD+=( -not -name "*.$ext" )
    done
fi

# Execute concatenation
"${FIND_CMD[@]}" -exec sh -c '
    for f; do
        if [[ "$(file -b --mime-type "$f")" == text/* ]]; then
            echo "=== $f ===" >> "'"$OUT_FILE"'"
            cat "$f" >> "'"$OUT_FILE"'"
            echo -e "\n" >> "'"$OUT_FILE"'"
        fi
    done
' _ {} +

echo "Done. Content saved to: $OUT_FILE"
