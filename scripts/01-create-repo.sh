#!/usr/bin/env bash
# Crea un nuevo repo GitHub desde este blueprint y lo conecta a Azure Static Web Apps.
#
# Pre-requisitos:
#   gh auth login       (GitHub CLI autenticado)
#   az login            (Azure CLI autenticado)
#
# Variables de entorno reconocidas (ver docs/05-env-vars.md):
#   AZURE_SUBSCRIPTION_ID, AZURE_RESOURCE_GROUP, AZURE_LOCATION
#
# Uso:
#   ./scripts/01-create-repo.sh --name <repo-name> [--rg <resource-group>] [--location eastasia] [--private]
set -euo pipefail

REPO_NAME=""
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-}"
LOCATION="${AZURE_LOCATION:-eastus2}"
VISIBILITY="--public"

# ── argumentos ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)     REPO_NAME="$2";       shift 2 ;;
    --rg)       RESOURCE_GROUP="$2";  shift 2 ;;
    --location) LOCATION="$2";        shift 2 ;;
    --private)  VISIBILITY="--private"; shift ;;
    *)
      echo "Uso: $0 --name <repo-name> [--rg <resource-group>] [--location <región>] [--private]"
      exit 1
      ;;
  esac
done

if [ -z "$REPO_NAME" ]; then
  echo "Error: --name es obligatorio."
  echo "Uso: $0 --name mi-app"
  exit 1
fi

if [ -z "$RESOURCE_GROUP" ]; then
  echo "Error: --rg es obligatorio (o definir AZURE_RESOURCE_GROUP en el entorno)."
  exit 1
fi

# ── verificar dependencias ────────────────────────────────────────────────────
for cmd in gh az git; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' no está instalado." >&2
    exit 1
  fi
done

if ! gh auth status &>/dev/null; then
  echo "Error: ejecutar 'gh auth login' primero." >&2; exit 1
fi
if ! az account show &>/dev/null 2>&1; then
  echo "Error: ejecutar 'az login' primero." >&2; exit 1
fi

GH_USER=$(gh api /user --jq '.login')
AZ_SUB=$(az account show --query 'name' -o tsv)
AZ_SUB_ID=$(az account show --query 'id' -o tsv)

echo "GitHub:       $GH_USER"
echo "Azure:        $AZ_SUB ($AZ_SUB_ID)"
echo "Resource group: $RESOURCE_GROUP ($LOCATION)"
echo ""

# ── 1. crear repo GitHub ──────────────────────────────────────────────────────
echo "── [1/4] Creando repo GitHub: $GH_USER/$REPO_NAME ──"
gh repo create "$REPO_NAME" $VISIBILITY --description "Vite + Azure SWA — desde blueprint" --source . --remote origin --push
echo "✓ Repo: https://github.com/$GH_USER/$REPO_NAME"
echo ""

# ── 2. crear resource group ───────────────────────────────────────────────────
echo "── [2/4] Creando resource group: $RESOURCE_GROUP ──"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
echo "✓ Resource group: $RESOURCE_GROUP ($LOCATION)"
echo ""

# ── 3. crear Azure Static Web App ─────────────────────────────────────────────
echo "── [3/4] Creando Azure Static Web App: $REPO_NAME ──"
echo "   (Azure creará el workflow y el secret en GitHub automáticamente)"
az staticwebapp create \
  --name "$REPO_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --source "https://github.com/$GH_USER/$REPO_NAME" \
  --location "$LOCATION" \
  --branch main \
  --app-location "/" \
  --output-location "build" \
  --login-with-github \
  --output none

SWA_URL=$(az staticwebapp show \
  --name "$REPO_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "defaultHostname" \
  --output tsv)

echo "✓ URL: https://$SWA_URL"
echo ""

# ── 4. verificar secret ───────────────────────────────────────────────────────
echo "── [4/4] Verificando secret en GitHub ──"
SECRET_NAME=$(gh api "/repos/$GH_USER/$REPO_NAME/actions/secrets" --jq '.secrets[].name' | grep AZURE_STATIC_WEB_APPS || true)

if [ -n "$SECRET_NAME" ]; then
  echo "✓ Secret: $SECRET_NAME"
else
  echo "⚠ No se encontró el secret. Azure puede tardar unos segundos en crearlo."
  echo "  Verificar con: gh api /repos/$GH_USER/$REPO_NAME/actions/secrets --jq '.secrets[].name'"
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "✓ Setup completado"
echo ""
echo "Próximos pasos:"
echo "  1. Azure generó un workflow nuevo en .github/workflows/"
echo "     Reemplazar azure-static-web-apps-REPLACE-NAME.yml con ese archivo"
echo "     (el nombre del workflow NO puede cambiarse después)"
echo ""
echo "  2. Verificar el deploy:"
echo "     ./scripts/04-deploy-status.sh"
echo ""
echo "  3. URL de producción: https://$SWA_URL"
echo "══════════════════════════════════════════════════════════════"
