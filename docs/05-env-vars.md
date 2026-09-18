# Variables de entorno

Convención del proyecto: IDs, tokens y valores que varían por entorno o por persona van en variables de entorno del sistema — nunca en el código ni en el repo.

---

## Estado actual en `~/.zshrc`

### Variables del blueprint (Azure SWA + GitHub)

| Variable | Estado | Uso |
|---|---|---|
| `AZURE_SUBSCRIPTION_ID` | ✓ definida | `az login`, `az account set`, `01-create-repo.sh` |
| `AZURE_TENANT_ID` | ✓ definida | `az login --tenant` — Default Directory (carlossduarteslivecom.onmicrosoft.com) |
| `AZURE_RESOURCE_GROUP` | ✓ definida | `01-create-repo.sh` (default de `--rg`) |
| `AZURE_LOCATION` | ✓ definida | `01-create-repo.sh` (default de `--location`) |
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | ✓ definida | Token de deploy de la SWA activa (regina-countdown) |
| `GITHUB_TOKEN` | ✓ definida | `gh` CLI (lo lee automáticamente) |

### Otras variables Azure en el entorno

| Variable | Uso |
|---|---|
| `AZURE_USER` | Usuario Azure DevOps (carlos.duarte2) |
| `TOKEN_AZURE` | PAT de Azure DevOps (también como `GRADLE_DEV_PASSWORD`) |

---

## Cómo están definidas en `~/.zshrc`

```bash
# azure
export AZURE_USER=carlos.duarte2
export TOKEN_AZURE=<azure-devops-pat>

# github
export GITHUB_TOKEN=<fine-grained-pat>

# azure static web apps
export AZURE_STATIC_WEB_APPS_API_TOKEN=<deployment-token-regina-countdown>

# azure subscription
export AZURE_SUBSCRIPTION_ID=1870859a-02b5-451f-8e1a-74b8cb5e1255
export AZURE_TENANT_ID=bc31de7d-3859-4df0-9fc0-091b2c8810d4
export AZURE_RESOURCE_GROUP=RecursosTEST
export AZURE_LOCATION=eastasia
```

Aplicar cambios sin reiniciar la terminal:

```bash
source ~/.zshrc
```

---

## Uso en los scripts

Los scripts leen las variables como defaults. Los flags CLI siempre tienen precedencia:

```bash
# Usa AZURE_RESOURCE_GROUP y AZURE_LOCATION del entorno
./scripts/01-create-repo.sh --name mi-app

# Sobreescribe solo la región
./scripts/01-create-repo.sh --name mi-app --location eastus2
```

`az` también reconoce `AZURE_SUBSCRIPTION_ID` de forma nativa — actúa como suscripción default en todos los comandos `az` sin necesidad de pasar `--subscription`.

---

## Login con la variable ya definida

```bash
az login --use-device-code --subscription "$AZURE_SUBSCRIPTION_ID"
```

---

## Qué NO poner en el repo

| Tipo | Dónde va en cambio |
|---|---|
| Subscription IDs, tenant IDs | `~/.zshrc` |
| Fine-grained PATs (`GITHUB_TOKEN`) | `~/.zshrc` |
| Deployment tokens (`AZURE_STATIC_WEB_APPS_API_TOKEN_*`) | `~/.zshrc` (local) + GitHub Secrets (CI) |
| Azure DevOps PATs (`TOKEN_AZURE`) | `~/.zshrc` |

**Regla:** si el valor cambia entre personas o entornos, va en env var. Si es sensible, nunca hardcodeado en código ni en commits.

---

## Agregar una nueva variable

```bash
# 1. Editar ~/.zshrc
#    Agregar: export MI_VAR=valor

# 2. Aplicar en la sesión actual
source ~/.zshrc

# 3. Verificar
echo "$MI_VAR"
```

---

## Verificar estado completo

```bash
./scripts/00-check-auth.sh
```
