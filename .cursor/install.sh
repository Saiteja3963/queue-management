#!/usr/bin/env bash
set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"

cd "$(dirname "$0")/.."

pip3 install --user -r backend/requirements.txt
(cd frontend && npm ci)
