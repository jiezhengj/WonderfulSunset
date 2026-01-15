#!/bin/bash

# Test compilation of Wonderful Sunset app files
echo "Testing Wonderful Sunset app compilation..."

# Create a temporary build directory
BUILD_DIR="./build"
mkdir -p "$BUILD_DIR"

# Function to compile files in a directory
compile_files() {
    local directory="$1"
    local description="$2"
    
    echo "Compiling $description files..."
    
    for file in "$directory"/*.swift; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            echo "  Compiling $filename..."
            
            swiftc -c "$file" -o "$BUILD_DIR/${filename%.swift}.o" 2>&1
            if [ $? -ne 0 ]; then
                echo "❌ Failed to compile $filename!"
                return 1
            fi
        fi
    done
    
    echo "✅ $description files compiled successfully!"
    return 0
}

# Compile files in order of dependency
compile_files "WonderfulSunset/Sources/Services" "service" && \
compile_files "WonderfulSunset/Sources/Models" "model" && \
compile_files "WonderfulSunset/Sources/Utils" "utility" && \
compile_files "WonderfulSunset/Sources/Views" "view" && \
compile_files "WonderfulSunset/Sources" "main app"

if [ $? -eq 0 ]; then
    echo "🎉 All files compiled successfully!"
else
    echo "❌ Some files failed to compile!"
    exit 1
fi

# Clean up
rm -rf "$BUILD_DIR"
