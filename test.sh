if [ ! -f "build/main" ]; then
    echo "[x] No built binary found in build directory as \"main\""
    exit 1
fi

if [ ! -f "tests.txt" ]; then
    echo "[x] There is not \"tests.txt\" to run tests"
    exit 1
fi

for line in $(cat "tests.txt"); do
    list1=$(echo "$line" | cut -d'|' -f1)
    list2=$(echo "$line" | cut -d'|' -f2)
    expected=$(echo "$line" | cut -d'|' -f3)

    result=$(./build/main "$list1" "$list2")
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
        echo "[x] CRASH: $line (exit code: $exit_code)"
    elif [ "$result" = "$expected" ]; then
        echo "[+] PASS: $line"
    else
        echo "[x] FAIL: $line (got: $result)"
    fi
done