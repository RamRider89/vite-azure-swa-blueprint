#!/usr/bin/env bash
# Verifica que gh y az estén autenticados con las cuentas correctas.
# Uso: ./scripts/00-check-auth.sh
set -euo pipefail

PASS=0
FAIL=0

ok()   { echo "  ✓ $*"; ((PASS++)) || true; }
fail() { echo "  ✗ $*"; ((FAIL++)) || true; }
sep()  { echo ""; echo "── $* ──────────────────────────────────────────"; }

# ── GitHub CLI ────────────────────────────────────────────────────────────────
sep "GitHub CLI (gh)"

if ! command -v gh &>/dev/null; then
  fail "gh no está instalado  →  https://cli.github.com"
else
  ok "gh instalado: $(gh --version | head -1)"

  if gh auth status &>/dev/null 2>&1; then
    GH_USER=$(gh api /user --jq '.login' 2>/dev/null || echo "desconocido")
    GH_PLAN=$(gh api /user --jq '.plan.name' 2>/dev/null || echo "")
    ok "sesión activa: $GH_USER${GH_PLAN:+ ($GH_PLAN)}"

    # scopes mínimos requeridos por create-repo.sh
    SCOPES=$(gh auth status 2>&1 | grep -i "token scopes" || true)
    if [ -n "$SCOPES" ]; then
      ok "scopes: $SCOPES"
    fi
  else
    fail "sin sesión activa  →  ejecutar: gh auth login"
  fi
fi

# ── Azure CLI ─────────────────────────────────────────────────────────────────
sep "Azure CLI (az)"

if ! command -v az &>/dev/null; then
  fail "az no está instalado  →  https://docs.microsoft.com/cli/azure/install-azure-cli"
else
  ok "az instalado: $(az version --query '"azure-cli"' -o tsv 2>/dev/null)"

  if az account show &>/dev/null 2>&1; then
    AZ_USER=$(az account show --query 'user.name' -o tsv 2>/dev/null)
    AZ_SUB=$(az account show --query 'name' -o tsv 2>/dev/null)
    AZ_ID=$(az account show --query 'id' -o tsv 2>/dev/null)
    ok "sesión activa: $AZ_USER"
    ok "suscripción:   $AZ_SUB"
    ok "id:            $AZ_ID"

    # verificar que tiene acceso a Static Web Apps
    SWA_COUNT=$(az staticwebapp list --query 'length(@)' -o tsv 2>/dev/null || echo "?")
    ok "Static Web Apps en la suscripción: $SWA_COUNT"
  else
    fail "sin sesión activa  →  ejecutar: az login"
  fi
fi

# ── Resumen ───────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────"
if [ "$FAIL" -eq 0 ]; then
  echo "✓ Todo en orden ($PASS checks). Listo para usar 01-create-repo.sh."
else
  echo "✗ $FAIL problema(s) encontrado(s). Resolver antes de continuar."
  exit 1
fi
