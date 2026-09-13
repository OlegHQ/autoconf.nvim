#!/usr/bin/env python3
"""Tiny stdio LSP server used only by the isolated Autoconf host test."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def read_message():
    headers = {}
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            return None
        if line in (b"\r\n", b"\n"):
            break
        key, value = line.decode("ascii").split(":", 1)
        headers[key.lower()] = value.strip()
    length = int(headers["content-length"])
    return json.loads(sys.stdin.buffer.read(length))


def send(message):
    payload = json.dumps(message, separators=(",", ":")).encode("utf-8")
    sys.stdout.buffer.write(f"Content-Length: {len(payload)}\r\n\r\n".encode("ascii") + payload)
    sys.stdout.buffer.flush()


capture = Path(sys.argv[1])
while message := read_message():
    method = message.get("method")
    request_id = message.get("id")
    if method == "initialize":
        item = (
            message.get("params", {})
            .get("capabilities", {})
            .get("textDocument", {})
            .get("completion", {})
            .get("completionItem", {})
        )
        capture.write_text(json.dumps({"snippetSupport": item.get("snippetSupport")}))
        send({
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {"capabilities": {"textDocumentSync": 1}},
        })
    elif method == "shutdown":
        send({"jsonrpc": "2.0", "id": request_id, "result": None})
    elif request_id is not None:
        send({"jsonrpc": "2.0", "id": request_id, "result": None})
