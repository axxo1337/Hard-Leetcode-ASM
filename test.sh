if [ ! -f "build/main" ]; then
    echo "[x] No built binary found in build directory as \"main\""
    exit 1
fi