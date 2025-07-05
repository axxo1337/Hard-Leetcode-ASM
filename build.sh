#!/bin/bash

mkdir -p build

if ! command -v nasm >/dev/null 2>&1; then
    echo "[x] NASM is required to build this"
    exit 1
fi

if ! command -v ld >/dev/null 2>&1; then
    echo "[x] The GNU linker (ld) is required to build this"
    exit 1
fi

if nasm -felf64 main.s -o build/main.o; then
    if ld build/main.o -o build/main; then
        echo "[+] Build complete! You can find the output as build/main"
        chmod +x build/main
    else 
        echo "[x] Failed to link program"
        rm build/main.o
        exit 1
    fi
else
    echo "[x] Failed to assemble program"
    exit 1
fi
