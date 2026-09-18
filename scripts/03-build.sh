#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

if [ -f "$REPO_ROOT/.nvmrc" ]; then
  nvm use
fi

cd "$REPO_ROOT"

echo "→ lint"
npm run lint

echo "→ test"
npm run test:run

echo "→ build"
npm run build

echo ""
echo "✓ build/  listo para deploy"
du -sh "$REPO_ROOT/build"
