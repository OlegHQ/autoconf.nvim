#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PLUGIN_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
HOST_ROOT=$(CDPATH= cd -- "$PLUGIN_ROOT/../../../../" && pwd)
NVIM_BIN=${NVIM_BIN:-$(command -v nvim)}

"$NVIM_BIN" --headless -u "$HOST_ROOT/init.lua" -i NONE -n \
    -c "lua dofile('$SCRIPT_DIR/host_integration.lua')" -c 'qa!'
