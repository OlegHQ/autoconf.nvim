#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PLUGIN_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
WORKBENCH_ROOT=$(CDPATH= cd -- "$PLUGIN_ROOT/../workbench.nvim" && pwd)
NVIM_MIN=${NVIM_MIN:-$WORKBENCH_ROOT/.test-deps/neovim-0.11.7/bin/nvim}
NVIM_CURRENT=${NVIM_CURRENT:-$(command -v nvim)}
TEST_XDG=$(mktemp -d "${TMPDIR:-/tmp}/autoconf-test.XXXXXX")
trap 'rm -rf "$TEST_XDG"' EXIT HUP INT TERM
mkdir -p "$TEST_XDG/config" "$TEST_XDG/data" "$TEST_XDG/state" "$TEST_XDG/cache"

for nvim_bin in "$NVIM_MIN" "$NVIM_CURRENT"; do
    if [ ! -x "$nvim_bin" ]; then
        printf 'required Neovim binary not found: %s\n' "$nvim_bin" >&2
        exit 1
    fi
    printf '== autoconf feature tests on %s ==\n' "$nvim_bin"
    XDG_CONFIG_HOME="$TEST_XDG/config" XDG_DATA_HOME="$TEST_XDG/data" \
    XDG_STATE_HOME="$TEST_XDG/state" XDG_CACHE_HOME="$TEST_XDG/cache" \
    "$nvim_bin" --clean --headless -i NONE -n \
        -u "$SCRIPT_DIR/minimal_init.lua" -l "$SCRIPT_DIR/run.lua"
    XDG_CONFIG_HOME="$TEST_XDG/config" XDG_DATA_HOME="$TEST_XDG/data" \
    XDG_STATE_HOME="$TEST_XDG/state" XDG_CACHE_HOME="$TEST_XDG/cache" \
    "$nvim_bin" --clean --headless -i NONE -n \
        -u "$SCRIPT_DIR/minimal_init.lua" -l "$SCRIPT_DIR/optional.lua"
done
