# Deployment — Vite + Azure Static Web Apps

Guía paso a paso para conectar este blueprint a Azure Static Web Apps y tener un deploy funcional.

---

## Pre-requisitos

| Herramienta | Verificar | Instalar |
|---|---|---|
| Node 22 | `node --version` | `nvm install 22` |
| gh CLI | `gh auth status` | [cli.github.com](https://cli.github.com) |
| az CLI | `az account show` | [docs.microsoft.com/cli/azure/install](https://docs.microsoft.com/cli/azure/install-azure-cli) |
| Cuenta Azure | Suscripción activa | [portal.azure.com](https://portal.azure.com) |

```bash
gh auth login   # autenticar GitHub CLI
az login        # autenticar Azure CLI
```

---

## Opción A — Automatizado (recomendado)

```bash
./scripts/01-create-repo.sh \
  --name mi-app \
  --rg rg-mi-app \
  --location eastus2
```

El script hace todo lo de la Opción B en un solo comando. Ver [scripts.md](04-scripts.md) para flags disponibles.

---

## Opción B — Manual paso a paso

### 1. Crear el repo en GitHub

```bash
gh repo create mi-app --public --source . --remote origin --push
```

### 2. Crear el resource group en Azure

```bash
az group create --name rg-mi-app --location eastus2
```

### 3. Crear el recurso Static Web App

```bash
az staticwebapp create \
  --name mi-app \
  --resource-group rg-mi-app \
  --source https://github.com/<owner>/mi-app \
  --location eastus2 \
  --branch main \
  --app-location "/" \
  --output-location "build" \
  --login-with-github
```

Al completar, Azure hace tres cosas automáticamente:
1. Crea el recurso con URL `https://<adjective>-<noun>-<hex>.azurestaticapps.net`
2. Inyecta el secret `AZURE_STATIC_WEB_APPS_API_TOKEN_<SUFFIX>` en el repo de GitHub
3. Genera el archivo `.github/workflows/azure-static-web-apps-<adjective>-<noun>-<hex>.yml` en el repo

### 4. Reemplazar el workflow template

El repo tiene un archivo template:
```
.github/workflows/azure-static-web-apps-REPLACE-NAME.yml
```

Azure generó el archivo real con el nombre correcto. Reemplazar el template:

```bash
# Verificar que Azure generó el workflow
git pull

# El archivo generado por Azure tendrá nombre como:
# azure-static-web-apps-purple-pebble-07a0da800.yml

# Eliminar el template
git rm .github/workflows/azure-static-web-apps-REPLACE-NAME.yml

# El workflow de Azure ya contiene los pasos básicos.
# Agregar los pasos de Node/test/build (marcados en el template con # ADD)
```

> **Crítico:** El nombre del workflow (`azure-static-web-apps-<adjective>-<noun>-<hex>.yml`) **no puede cambiarse después**. Azure SWA OIDC verifica el nombre exacto del archivo para autorizar el deploy.

### 5. Verificar el nombre del secret

```bash
gh api /repos/<owner>/mi-app/actions/secrets --jq '.secrets[].name'
# → AZURE_STATIC_WEB_APPS_API_TOKEN_PURPLE_PEBBLE_07A0DA800
```

El secret tiene el sufijo del recurso Azure en mayúsculas. Asegurarse de que el workflow use el nombre exacto.

### 6. Hacer push y verificar el deploy

```bash
git add .github/workflows/
git commit -m "ci: configurar workflow Azure SWA"
git push

# Monitorear el deploy
./scripts/04-deploy-status.sh
```

El primer deploy puede tardar 2-5 minutos.

---

## Verificar deploy exitoso

```bash
# Ver últimos runs
./scripts/04-deploy-status.sh

# Ver URL de producción
az staticwebapp show \
  --name mi-app \
  --resource-group rg-mi-app \
  --query "defaultHostname" \
  --output tsv
```

---

## Comportamiento del pipeline

| Evento | Resultado |
|---|---|
| `push` a `main` | Build + deploy a producción |
| PR abierto/actualizado contra `main` | Build + deploy a entorno staging (URL temporal) |
| PR cerrado | Limpieza del entorno staging |

Los tests (`npm run test:run`) bloquean el deploy si fallan.

---

## Rotar el deployment token

Si el token expira o se revoca:

```bash
# 1. Regenerar en Azure
az staticwebapp secrets reset-api-key \
  --name mi-app \
  --resource-group rg-mi-app

# 2. Obtener el nuevo token
NUEVO_TOKEN=$(az staticwebapp secrets list \
  --name mi-app \
  --resource-group rg-mi-app \
  --query "properties.apiKey" \
  --output tsv)

# 3. Actualizar el secret en GitHub
gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN_<SUFFIX> \
  --repo <owner>/mi-app \
  --body "$NUEVO_TOKEN"
```

---

## Troubleshooting

### `Could not determine the Static Web App from the GitHub OIDC workflow reference`

El workflow fue renombrado.  
**Fix:** Restaurar el nombre original `azure-static-web-apps-<adjective>-<noun>-<hex>.yml`.

### `No matching Static Web App was found or the api key was invalid`

Nombre del secret incorrecto o faltan los pasos OIDC.  
**Fix:** Verificar nombre real con `gh api /repos/.../actions/secrets` y que el workflow tenga `permissions: id-token: write`.

### `The app build failed to produce artifact folder: 'build'`

Vite está outputeando a `dist/`.  
**Fix:** Confirmar que `vite.config.ts` tiene `build: { outDir: 'build' }` y el workflow tiene `output_location: "build"`.

### `SyntaxError: Identifier 'core' has already been declared`

En el paso `actions/github-script`, `core` es una variable interna reservada.  
**Fix:** Usar cualquier otro nombre, ej: `coredemo`.

### Re-trigger un deploy sin cambios en el código

```bash
git commit --allow-empty -m "ci: re-trigger deploy"
git push
```
