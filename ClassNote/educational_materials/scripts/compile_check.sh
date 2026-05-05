#!/usr/bin/env bash
# compile_check.sh — Extracts every ```cpp fenced block from each week's README.md
# and tries to compile each one with g++ -std=c++17 -Wall.
#
# Exits 0 only if all snippets compile. Prints a summary at the end.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

total=0
fail=0
fail_list=()

shopt -s nullglob
for readme in "$ROOT"/week*/README.md; do
    week_name="$(basename "$(dirname "$readme")")"
    # Use awk to split the README into ```cpp ... ``` blocks.
    # We'll write each block to a separate file: $TMP/${week_name}_${idx}.cpp
    awk -v out_prefix="$TMP/${week_name}_" '
        BEGIN { idx=0; in_cpp=0 }
        /^[[:space:]]*```cpp[[:space:]]*$/ {
            in_cpp=1
            idx++
            file = sprintf("%s%02d.cpp", out_prefix, idx)
            next
        }
        /^[[:space:]]*```[[:space:]]*$/ {
            if (in_cpp) {
                in_cpp=0
                close(file)
            }
            next
        }
        in_cpp { print > file }
    ' "$readme"

    # Now compile each extracted .cpp for this week
    for cpp in "$TMP/${week_name}_"*.cpp; do
        total=$((total + 1))
        bin="${cpp%.cpp}.bin"
        if g++ -std=c++17 -Wall -Wno-unused-result -o "$bin" "$cpp" 2> "$cpp.err"; then
            echo "[OK]   $(basename "$cpp")"
        else
            fail=$((fail + 1))
            fail_list+=("$cpp")
            echo "[FAIL] $(basename "$cpp")"
            sed 's/^/       /' "$cpp.err"
        fi
    done
done

echo
echo "===================================="
echo "Total snippets: $total | Failed: $fail"
echo "===================================="

if [ "$fail" -gt 0 ]; then
    echo "Failing files retained at:"
    for f in "${fail_list[@]}"; do
        echo "  $f"
    done
    # Keep tmp on failure for inspection
    trap - EXIT
    echo "Tmp dir kept: $TMP"
    exit 1
fi

exit 0
