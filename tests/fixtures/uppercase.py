#!/usr/bin/env python3
"""Minimal stdin-to-stdout formatter used by the installed Conform integration test."""

from __future__ import annotations

import sys
from pathlib import Path

data = sys.stdin.read()
if len(sys.argv) > 1:
    with Path(sys.argv[1]).open("a", encoding="utf-8") as output:
        output.write("called\n")
sys.stdout.write(data.upper())
