# Contrato de Uso — Azure CLI (`az`)

Referencia operativa para gestionar recursos de Azure desde terminal, enfocada en Static Web Apps y el flujo de deploy desde GitHub.

---

## Instalación y autenticación

```bash
# Instalar (Ubuntu/Debian)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Instalar (macOS)
brew install azure-cli

# Verificar versión
az --version

# Login interactivo (abre browser)
az login

# Login con service principal (CI/CD)
az login --service-principal \
  --username <app-id> \
  --password <secret> \
  --tenant <tenant-id>

# Ver cuenta activa
az account show

# Listar suscripciones disponibles
az account list --output table

# Cambiar suscripción activa
az account set --subscription "<nombre-o-id>"
```

---

## Resource Groups

Los recursos de Azure viven dentro de un **resource group** (contenedor lógico).

```bash
# Listar resource groups
az group list --output table

# Crear resource group
az group create \
  --name rg-mi-proyecto \
  --location eastasia

# Ver ubicaciones disponibles
az account list-locations --output table

# Eliminar resource group (y todos sus recursos)
az group delete --name rg-mi-proyecto --yes
```

### Regiones recomendadas para static sites

| Región | Código | Latencia desde MX/LATAM |
|---|---|---|
| East US 2 | `eastus2` | Baja |
| Central US | `centralus` | Muy baja |
| West US 2 | `westus2` | Baja |
| East Asia | `eastasia` | Alta (no recomendado para LATAM) |

---

## Static Web Apps

### Crear recurso

```bash
# Listar Static Web Apps en la suscripción
az staticwebapp list --output table

# Crear (conectado a GitHub)
az staticwebapp create \
  --name mi-app \
  --resource-group rg-mi-proyecto \
  --source https://github.com/<owner>/<repo> \
  --location eastus2 \
  --branch main \
  --app-location "/" \
  --output-location "build" \
  --login-with-github

# Ver detalles de un recurso
az staticwebapp show \
  --name mi-app \
  --resource-group rg-mi-proyecto

# Ver la URL de producción
az staticwebapp show \
  --name mi-app \
  --resource-group rg-mi-proyecto \
  --query "defaultHostname" \
  --output tsv
```

### Deployment token

```bash
# Obtener el deployment token activo
az staticwebapp secrets list \
  --name mi-app \
  --resource-group rg-mi-proyecto \
  --query "properties.apiKey" \
  --output tsv

# Regenerar el deployment token
az staticwebapp secrets reset-api-key \
  --name mi-app \
  --resource-group rg-mi-proyecto
```

> Después de regenerar, actualizar el secret en GitHub con `gh secret set`.

### Entornos (staging)

Azure SWA crea entornos de staging automáticamente para cada PR.

```bash
# Listar entornos activos (producción + staging de PRs)
az staticwebapp environment list \
  --name mi-app \
  --resource-group rg-mi-proyecto \
  --output table

# Ver URL de un entorno de staging
az staticwebapp environment show \
  --name mi-app \
  --resource-group rg-mi-proyecto \
  --environment-name <nombre-entorno>
```

### Eliminar recurso

```bash
az staticwebapp delete \
  --name mi-app \
  --resource-group rg-mi-proyecto \
  --yes
```

---

## Diagnóstico y logs

```bash
# Ver actividad reciente del recurso
az monitor activity-log list \
  --resource-group rg-mi-proyecto \
  --offset 24h \
  --output table

# Ver métricas básicas
az monitor metrics list \
  --resource /subscriptions/<sub-id>/resourceGroups/rg-mi-proyecto/providers/Microsoft.Web/staticSites/mi-app \
  --metric "Requests" \
  --interval PT1H
```

---

## Flujos comunes

### Setup completo desde cero

```bash
# 1. Autenticar
az login

# 2. Crear resource group
az group create --name rg-mi-proyecto --location eastus2

# 3. Crear Static Web App conectado al repo
az staticwebapp create \
  --name mi-app \
  --resource-group rg-mi-proyecto \
  --source https://github.com/<owner>/<repo> \
  --location eastus2 \
  --branch main \
  --app-location "/" \
  --output-location "build" \
  --login-with-github

# 4. Obtener la URL de producción
az staticwebapp show \
  --name mi-app \
  --resource-group rg-mi-proyecto \
  --query "defaultHostname" --output tsv

# 5. Azure habrá creado el workflow y el secret en GitHub automáticamente
# Verificar con:
gh api /repos/<owner>/<repo>/actions/secrets --jq '.secrets[].name'
```

### Rotar deployment token

```bash
# 1. Regenerar en Azure
az staticwebapp secrets reset-api-key \
  --name mi-app \
  --resource-group rg-mi-proyecto

# 2. Obtener nuevo token
NUEVO_TOKEN=$(az staticwebapp secrets list \
  --name mi-app \
  --resource-group rg-mi-proyecto \
  --query "properties.apiKey" \
  --output tsv)

# 3. Actualizar secret en GitHub
gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN_<SUFFIX> \
  --repo <owner>/<repo> \
  --body "$NUEVO_TOKEN"
```

### Verificar estado del recurso

```bash
# Ver hostname y estado
az staticwebapp show \
  --name mi-app \
  --resource-group rg-mi-proyecto \
  --query "{url:defaultHostname, state:repositoryToken}" \
  --output table

# Listar todos los entornos activos
az staticwebapp environment list \
  --name mi-app \
  --resource-group rg-mi-proyecto \
  --output table
```

---

## Convenciones de nomenclatura Azure

| Recurso | Patrón recomendado | Ejemplo |
|---|---|---|
| Resource group | `rg-<proyecto>-<env>` | `rg-mi-app-prod` |
| Static Web App | `<proyecto>` o `<proyecto>-<env>` | `mi-app` |
| Location | siempre en minúsculas sin espacios | `eastus2` |

Azure genera automáticamente el hostname de la SWA con el patrón:
```
<adjective>-<noun>-<hex>.azurestaticapps.net
```
Este nombre también aparece en el secret de GitHub y en el workflow filename — los tres están vinculados.

---

## Referencia rápida

```bash
az login                                    # autenticar
az account show                             # ver cuenta activa
az group list --output table                # listar resource groups
az staticwebapp list --output table         # listar todas las SWA
az staticwebapp show -n <app> -g <rg>       # ver detalles
az staticwebapp secrets list -n <app> -g <rg> --query "properties.apiKey" -o tsv
az staticwebapp secrets reset-api-key -n <app> -g <rg>   # rotar token
az staticwebapp environment list -n <app> -g <rg>         # ver entornos
az staticwebapp delete -n <app> -g <rg> --yes             # eliminar
```

---

## Tips

- `--output table` es más legible para humanos; `--output tsv` para scripts; `--output json` para parsear con `jq`.
- `--query` acepta sintaxis JMESPath para filtrar la respuesta JSON.
- `az interactive` activa autocompletado y documentación inline en la terminal.
- Las operaciones destructivas (`delete`, `reset-api-key`) piden confirmación con `--yes`; omitirlo en scripts automatizados.
- El free tier de Azure SWA tiene límite de 100 GB de transferencia/mes y 0.5 GB de almacenamiento.
