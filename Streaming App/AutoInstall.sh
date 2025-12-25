#!/bin/sh
DIR=$(cd "$(dirname "${BASH_SOURCE}")" && pwd)
python3 -B "${DIR}/CreateSteamShortcut.py"
