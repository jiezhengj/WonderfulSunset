#!/bin/bash

# Simple test runner for Wonderful Sunset app

echo "Testing Wonderful Sunset app compilation..."

# Check if the main app files compile
echo "Checking main app files..."
for file in \
    WonderfulSunset/Sources/Models/*.swift \
    WonderfulSunset/Sources/Services/*.swift \
    WonderfulSunset/Sources/Utils/*.swift \
    WonderfulSunset/Sources/Views/*.swift \
    WonderfulSunset/Sources/WonderfulSunsetApp.swift
do
    echo "  Checking $file..."
    swiftc -c "$file" 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ $file failed to compile!"
        exit 1
    fi
done

echo "✅ Main app files compile successfully!"

# Check if test files compile
echo "Checking test files..."
for file in \
    WonderfulSunset/Tests/*.swift
do
    echo "  Checking $file..."
    swiftc -c "$file" 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ $file failed to compile!"
        exit 1
    fi
done

echo "✅ Test files compile successfully!"

echo "🎉 All files compile successfully!"