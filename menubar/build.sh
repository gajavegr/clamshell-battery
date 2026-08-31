#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$DIR/build"
swiftc -O "$DIR/main.swift" -o "$DIR/build/ClamshellStatusBar" -framework Cocoa
echo "built $DIR/build/ClamshellStatusBar"
