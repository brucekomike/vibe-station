#!/bin/bash
# the docs build chain on the legacy station: macports python312, a shared
# ~/.venv, this repo's docs/requirements.txt. run from the repo root.
set -euo pipefail

hash python3.12 2>/dev/null || {
  echo "sudo port install python312 py312-virtualenv first (bootstrap-ports.sh)" >&2
  exit 1
}

test -d ~/.venv || python3.12 -m venv --system-site-packages ~/.venv
~/.venv/bin/pip install -r docs/requirements.txt

# prove the chain: build this station and check the new section took
~/.venv/bin/sphinx-build --version
make -C docs html
