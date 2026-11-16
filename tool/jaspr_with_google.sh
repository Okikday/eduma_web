#!/bin/sh
set -eu

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <jaspr command and arguments>" >&2
  exit 2
fi

if [ ! -f .env ]; then
  echo "Missing .env; copy it from the Flutter source workspace first." >&2
  exit 1
fi

client_id="$(python3 -c '
from pathlib import Path
import sys

values = []
for raw_line in Path(".env").read_text().splitlines():
    line = raw_line.strip()
    if line.startswith("export "):
        line = line[7:].lstrip()
    key, separator, value = line.partition("=")
    if separator and key.strip() == "WEB_CLIENT_ID":
        value = value.strip()
        if value[:1] in ("\"", "\047"):
            quote = value[0]
            end = value.find(quote, 1)
            if end < 0:
                raise SystemExit("WEB_CLIENT_ID has an unterminated quoted value.")
            value = value[1:end]
        else:
            value = value.split("#", 1)[0].strip()
        values.append(value)

if len(values) != 1 or not values[0]:
    raise SystemExit("Expected exactly one non-empty WEB_CLIENT_ID in .env.")
sys.stdout.write(values[0])
')"

exec jaspr "$@" "--dart-define=EDUMA_GOOGLE_WEB_CLIENT_ID=$client_id"
