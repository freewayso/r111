#!/bin/bash
# Sol2 Demo - Bash Launch Script

echo "========================================"
echo "Sol2 Demo - Launch Script"
echo "========================================"
echo ""

CONFIG=${1:-Debug}
EXE_PATH="build_vs2022/$CONFIG/sol2_demo.exe"

# Check if executable exists
if [ ! -f "$EXE_PATH" ]; then
    echo "Error: $EXE_PATH not found"
    echo ""
    echo "Please compile first:"
    echo "  cmake --build build_vs2022 --config $CONFIG"
    echo ""
    exit 1
fi

# Check scripts
if [ ! -f "build_vs2022/$CONFIG/scripts/demo.lua" ]; then
    echo "Warning: Scripts not found, copying..."
    mkdir -p "build_vs2022/$CONFIG"
    cp -r scripts "build_vs2022/$CONFIG/"
    echo "Scripts copied"
fi

# Check DLL
if [ ! -f "build_vs2022/$CONFIG/lua54.dll" ] && [ -f "lua/lib/lua54.dll" ]; then
    echo "Warning: lua54.dll not found, copying..."
    cp lua/lib/lua54.dll "build_vs2022/$CONFIG/"
    echo "DLL copied"
fi

echo "Starting program ($CONFIG mode)..."
echo "Working directory: build_vs2022/$CONFIG/"
echo ""
echo "Controls:"
echo "  - Press 'R' to reload script"
echo "  - Press 'A' to toggle auto-reload"
echo "  - Press 'Q' to quit"
echo ""
echo "========================================"
echo ""

# Run from correct directory
cd "build_vs2022/$CONFIG"
./sol2_demo.exe

# Return to original directory
cd ../..

