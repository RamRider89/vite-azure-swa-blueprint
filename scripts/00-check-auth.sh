#!/usr/bin/env bash
# Verifica que gh y az estén autenticados y que las variables de entorno estén definidas.
# Uso: ./scripts/00-check-auth.sh
set -euo pipefail

PASS=0
FAIL=0
WARN=0

ok()   { echo "  ✓ $*"; ((PASS++)) || true; }
fail() { echo "  ✗ $*"; ((FAIL++)) || true; }
warn() { echo "  ⚠ $*"; ((WARN++)) || true; }
sep()  { echo ""; echo "── $* ──────────────────────────────────────────"; }

# ── GitHub CLI ────────────────────────────────────────────────────────────────
sep "GitHub CLI (gh)"

if ! command -v gh &>/dev/null; then
  fail "gh no está instalado  →  https://cli.github.com"
else
  ok "gh instalado: $(gh --version | head -1)"

  if gh auth status &>/dev/null 2>&1; then
    GH_USER=$(gh api /user --jq '.login' 2>/dev/null || echo "desconocido")
    ok "sesión activa: $GH_USER"
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
    ok "suscripción:   $AZ_SUB ($AZ_ID)"
    SWA_COUNT=$(az staticwebapp list --query 'length(@)' -o tsv 2>/dev/null || echo "?")
    ok "Static Web Apps: $SWA_COUNT"
  else
    fail "sin sesión activa"
    echo ""
    echo "  Para iniciar sesión (cuenta personal live.com / outlook.com):"
    echo "    1. source ~/.zshrc"
    echo "    2. az login --use-device-code"
    echo "    3. Abrir https://login.microsoft.com/device e ingresar el código"
    echo "    4. Seleccionar suscripción cuando aparezca la lista"
    echo ""
    echo "  Ver docs/00-auth.md para más detalles y troubleshooting."
  fi
fi

# ── Variables de entorno ──────────────────────────────────────────────────────
sep "Variables de entorno (docs/05-env-vars.md)"

check_var() {
  local var="$1"
  local val="${!var:-}"
  if [ -n "$val" ]; then
    # Mostrar solo los primeros 8 caracteres para IDs, ocultar tokens
    if [[ "$var" == *TOKEN* ]] || [[ "$var" == *SECRET* ]]; then
      ok "$var = ${val:0:12}..."
    else
      ok "$var = $val"
    fi
  else
    warn "$var no definida  →  agregar a ~/.zshrc"
  fi
}

check_var AZURE_SUBSCRIPTION_ID
check_var AZURE_TENANT_ID
check_var AZURE_RESOURCE_GROUP
check_var AZURE_LOCATION
check_var GITHUB_TOKEN

# ── Resumen ───────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────"
if [ "$FAIL" -gt 0 ]; then
  echo "✗ $FAIL error(es) — resolver antes de continuar."
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo "⚠ $PASS checks OK · $WARN variable(s) sin definir (ver docs/05-env-vars.md)"
else
  echo "✓ Todo en orden ($PASS checks). Listo para usar 01-create-repo.sh."
fi
