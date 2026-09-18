#!/usr/bin/env bash
# Muestra el estado de los últimos deploys a Azure SWA para el repo actual.
# Uso: ./scripts/04-deploy-status.sh [--limit N] [--logs <run-id>] [--open <run-id>]
set -euo pipefail

LIMIT=5
LOGS_RUN=""
OPEN_RUN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit) LIMIT="$2"; shift 2 ;;
    --logs)  LOGS_RUN="$2"; shift 2 ;;
    --open)  OPEN_RUN="$2"; shift 2 ;;
    *) echo "Uso: $0 [--limit N] [--logs <run-id>] [--open <run-id>]"; exit 1 ;;
  esac
done

# ── verificar gh ──────────────────────────────────────────────────────────────
if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI no encontrado. Instalar: https://cli.github.com" >&2
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "Error: no hay sesión de gh activa. Ejecutar: gh auth login" >&2
  exit 1
fi

# ── detectar workflow de Azure SWA ────────────────────────────────────────────
WORKFLOW_FILE=$(find .github/workflows -name "azure-static-web-apps-*.yml" 2>/dev/null | head -1)

if [ -z "$WORKFLOW_FILE" ]; then
  echo "Error: no se encontró ningún archivo azure-static-web-apps-*.yml en .github/workflows/" >&2
  echo "¿El repo ya está conectado a Azure SWA?" >&2
  exit 1
fi

WORKFLOW_NAME=$(basename "$WORKFLOW_FILE")

# ── abrir run en browser ──────────────────────────────────────────────────────
if [ -n "$OPEN_RUN" ]; then
  gh run view "$OPEN_RUN" --web
  exit 0
fi

# ── mostrar logs de un run ────────────────────────────────────────────────────
if [ -n "$LOGS_RUN" ]; then
  gh run view "$LOGS_RUN" --log-failed
  exit 0
fi

# ── listar últimos runs ───────────────────────────────────────────────────────
echo "Workflow: $WORKFLOW_NAME"
echo ""
gh run list --workflow "$WORKFLOW_NAME" --limit "$LIMIT"

echo ""
echo "Comandos útiles:"
echo "  $0 --logs <run-id>   # ver logs de pasos fallidos"
echo "  $0 --open <run-id>   # abrir en browser"
echo "  gh run rerun <run-id> --failed   # re-ejecutar pasos fallidos"
