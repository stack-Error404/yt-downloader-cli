#!/bin/bash

# Test the render_error404_header function with clean output
echo 'Testing current img2txt behavior...'

# Simulate what happens now:
img2txt --width=72 --height=12 --format=ansi docs/assets/error404-terminal.png 2>/dev/null | head -5

echo ""
echo "Testing with strip-ansi:"
if command -v strip-ansi >/dev/null 2>&1; then
    img2txt --width=72 --height=12 --format=ansi docs/assets/error404-terminal.png | strip-ansi | head -5
else
    # Alternative approach for clean output using sed
    echo "No strip-ansi, using alternative"
fi

echo ""
echo "Testing with direct hexdump:"
hexdump -C <(img2txt --width=72 --height=12 --format=ansi docs/assets/error404-terminal.png | head -1) 2>/dev/null | head -3
