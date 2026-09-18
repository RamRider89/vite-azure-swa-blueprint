# Autenticación — Cuentas personales

Estado y proceso de login para operar este blueprint con cuentas personales Microsoft/GitHub.

---

## GitHub CLI (`gh`)

### Estado actual

```
Cuenta:    RamRider89
Token:     fine-grained PAT (github_pat_11A3WZ3XI...)
Protocolo: SSH
Estado:    ✓ activo
```

`gh auth status` muestra dos entradas para la misma cuenta:

| Fuente | Estado | Por qué existe |
|---|---|---|
| `GITHUB_TOKEN` (env var) | active | La variable de entorno tiene precedencia |
| `~/.config/gh/hosts.yml` | inactive | Credencial almacenada en disco |

Ambas usan la misma token — no hay conflicto.

### Renovar o cambiar la sesión

```bash
gh auth logout
gh auth login
# → GitHub.com → HTTPS → Login with a web browser
```

### Scopes mínimos requeridos por `01-create-repo.sh`

| Operación | Scope (fine-grained) |
|---|---|
| Crear repositorios | `Administration: read/write` |
| Gestionar secrets | `Secrets: read/write` |
| Leer/disparar Actions | `Actions: read/write` |

Editar en: **github.com → Settings → Developer settings → Personal access tokens → Fine-grained tokens**

---

## Azure CLI (`az`) — Cuenta personal `live.com`

### Estado actual

```
Cuenta:          carloss_duartes@live.com.mx
Tenant:          bc31de7d-3859-4df0-9fc0-091b2c8810d4 (Default Directory)
Suscripción:     Azure subscription 1
Sub ID:          1870859a-02b5-451f-8e1a-74b8cb5e1255
Resource Group:  RecursosTEST
Región default:  East Asia
Estado:          ✓ autenticado
```

SWA existente en esta suscripción:
```
Nombre:    regina-countdown
URL:       https://purple-pebble-07a0da800.5.azurestaticapps.net
Repo:      https://github.com/RamRider89/regina-countdown
```

---

## Qué tipo de cuenta Microsoft usar para Azure

### Comparativa

| Tipo | Ejemplo | Login con `az` CLI | Recomendado |
|---|---|---|---|
| **Personal legacy** (`live.com`) | `carlos@live.com.mx` | Requiere tenant AD propio + deshabilitar Security Defaults | Para cuentas existentes |
| **Outlook.com (personal)** | `dev-carlos@outlook.com` | Directo — tenant AD creado automáticamente sin fricción | ✓ Nueva cuenta personal |
| **Azure AD nativa** | `carlos@empresa.onmicrosoft.com` | Directo | ✓ Proyectos de equipo |
| **Azure AD empresarial** | `carlos@empresa.com` | Directo | ✓ Entorno corporativo |

### Recomendación para cuenta nueva

Si se crea una cuenta nueva para desarrollo Azure, usar **Outlook.com** (`@outlook.com`):
- Microsoft crea el tenant Azure AD directamente — sin complicaciones de `live.com` legacy
- Login con `az` funciona sin configuración extra
- Sin Security Defaults problemáticos en el device code flow
- Se puede usar para GitHub también (`gh auth login`)

```bash
# Con cuenta @outlook.com, el login es simplemente:
az login --use-device-code
# Sin --tenant, sin configuración de Security Defaults
```

Si se crea una nueva cuenta Outlook para este proyecto, seguir la guía de [migración](#migrar-a-cuenta-outlook) al final de este documento.

### Cuenta actual (`live.com`) — sigue funcionando

La cuenta `carloss_duartes@live.com.mx` ya está configurada y autenticada. No es necesario cambiar. El setup documentado en este archivo cubre todos los workarounds necesarios.

---

## Caso de uso: Cuenta personal Microsoft (`live.com`) en Azure

### Por qué es diferente a una cuenta corporativa

Las cuentas personales `live.com` / `hotmail.com` / `outlook.com` no son cuentas de Azure AD nativas. Cuando se crea una suscripción de Azure con una cuenta personal, Microsoft crea automáticamente un **Azure AD tenant** asociado (por ejemplo, `carlossduarteslivecom.onmicrosoft.com`). Ese tenant es el que maneja el acceso a la suscripción — no el tenant MSA genérico `9188040d`.

Azure Resource Manager (ARM) solo acepta autenticación via Azure AD. No hay endpoint `/consumers` para cuentas personales en ARM. Por esto, la autenticación pasa por el tenant específico de la suscripción.

### Diagnóstico de errores comunes

| Error | Causa | Solución |
|---|---|---|
| `AADSTS530035: Access has been blocked by security defaults` | Security Defaults habilitados en el tenant | [Deshabilitar Security Defaults](#fix-deshabilitar-security-defaults) |
| `AADSTS9002332: Application ... is not supported over the /consumers endpoint` | Intentar login con el tenant MSA genérico (`9188040d`) | Usar el tenant propio de la suscripción |
| `Failed to resolve tenant ''` | `$AZURE_TENANT_ID` vacío en la sesión de shell | `source ~/.zshrc` antes de correr `az login` |
| `AADSTS90002: Tenant 'v2.0' not found` | `--tenant ""` (string vacío) — az convierte el vacío en `v2.0` como endpoint | Az procede con discovery automático igualmente; el login puede continuar |
| `AADSTS900561: The endpoint only accepts POST requests. Received a GET request.` | Se navegó directamente a la URL del código en lugar de ir a `https://login.microsoft.com/device` | Ir manualmente a la URL y escribir el código en el formulario |
| `No subscriptions found for ...` | Security Defaults activos bloqueando el discovery | [Deshabilitar Security Defaults](#fix-deshabilitar-security-defaults) |

---

## Fix — Deshabilitar Security Defaults

Security Defaults bloquea el device code flow de Azure CLI. Necesita deshabilitarse una sola vez.

**Ruta directa en el Portal:**

```
portal.azure.com/#view/Microsoft_AAD_IAM/SecurityDefaultsPage
```

O navegando manualmente:
1. **Microsoft Entra ID** → **Overview** → pestaña **Properties**
2. Al final de la página → link **"Manage security defaults"**
3. Toggle **Security defaults**: cambiar de **Enabled** a **Disabled**
4. Seleccionar motivo → **Save**

> ⚠ No confundir con **"Access management for Azure resources"** (también en Properties) — esa opción es para RBAC de administrador global y no tiene efecto sobre el login de `az`.

> Security Defaults protege contra ataques en tenants multi-usuario. Para un tenant de desarrollo personal con un solo propietario, deshabilitarlo es aceptable.

---

## Login en WSL (flujo completo)

### Paso 1 — Asegurarse de que las vars de entorno están cargadas

```bash
source ~/.zshrc
echo "$AZURE_TENANT_ID"
# debe mostrar: bc31de7d-3859-4df0-9fc0-091b2c8810d4
```

### Paso 2 — Iniciar login por device code

```bash
az login --use-device-code
```

La terminal muestra un código como:
```
To sign in, use a web browser to open the page https://login.microsoft.com/device
and enter the code XXXXXXXX to authenticate.
```

### Paso 3 — Autenticar en el browser

1. Abrir **`https://login.microsoft.com/device`** en el browser de Windows
2. **Escribir** el código que aparece en la terminal (no pegar como URL)
3. Iniciar sesión con `carloss_duartes@live.com.mx`
4. Aprobar el acceso

> ⚠ Si el browser muestra `AADSTS900561: The endpoint only accepts POST requests` — navegaste a la URL del código directamente. Regresa a `https://login.microsoft.com/device` y escribe el código manualmente en el formulario.

### Paso 4 — Seleccionar suscripción

```
No     Subscription name     Subscription ID                       Tenant
-----  --------------------  ------------------------------------  -----------
[1] *  Azure subscription 1  1870859a-02b5-451f-8e1a-74b8cb5e1255  bc31de7d-...

Select a subscription and tenant (Type a number or Enter for no changes): 1
```

Ingresar `1` y Enter.

### Verificar login

```bash
az account show --query '{name:name, id:id, user:user.name}' --output table
az staticwebapp list --output table
```

---

## Nota sobre `--tenant "$AZURE_TENANT_ID"`

Al pasar `--tenant "$AZURE_TENANT_ID"` cuando la variable está vacía, az muestra:

```
Failed to resolve tenant ''.
AADSTS90002: Tenant 'v2.0' not found.
```

Este error es no-fatal — az procede con discovery automático y puede encontrar la suscripción igualmente. Si la variable está definida correctamente el error no ocurre. En ambos casos el login puede completarse via el formulario de device code.

Para evitar el error: siempre correr `source ~/.zshrc` antes de `az login`.

---

## Renovar sesión expirada

La sesión de az dura ~1 hora en WSL.

```bash
source ~/.zshrc
az login --use-device-code
```

Seleccionar suscripción `1870859a` cuando aparezca la lista.

---

## Fallback sin `az` CLI local

Si hay problemas con el login local, el deploy funciona sin `az`:

| Operación | Alternativa |
|---|---|
| Crear recursos | Azure Portal (browser) |
| Deploy | GitHub Actions + `AZURE_STATIC_WEB_APPS_API_TOKEN` |
| Monitoreo | `./scripts/04-deploy-status.sh` (usa `gh`, no `az`) |

---

## Verificación conjunta

```bash
./scripts/00-check-auth.sh
```

Salida esperada cuando todo está en orden:

```
── GitHub CLI (gh) ──────────────────────────────
  ✓ gh instalado: gh version 2.x.x
  ✓ sesión activa: RamRider89

── Azure CLI (az) ───────────────────────────────
  ✓ az instalado: 2.x.x
  ✓ sesión activa: carloss_duartes@live.com.mx
  ✓ suscripción:   Azure subscription 1 (1870859a-02b5-451f-8e1a-74b8cb5e1255)
  ✓ Static Web Apps: 1

────────────────────────────────────────────────
✓ Todo en orden. Listo para usar 01-create-repo.sh.
```

---

## Flujo de trabajo completo

```bash
# 1. Cargar env vars y verificar cuentas
source ~/.zshrc
./scripts/00-check-auth.sh

# 2. Si az no está autenticado
az login --use-device-code
# → abrir https://login.microsoft.com/device → ingresar código → seleccionar suscripción 1

# 3. Crear nuevo proyecto desde el blueprint
./scripts/01-create-repo.sh --name mi-app
```

---

## Migrar a cuenta Outlook

Si se decide crear una cuenta `@outlook.com` dedicada para Azure:

### 1. Crear la cuenta

1. Ir a **outlook.com** → Crear cuenta nueva (`dev-carlos@outlook.com` o similar)
2. Iniciar sesión en **portal.azure.com** con esa cuenta — esto crea el tenant Azure AD automáticamente
3. Activar una suscripción (Azure Free o Pay-as-you-go)

### 2. Actualizar variables de entorno

Una vez creada la suscripción, obtener los nuevos IDs:

```bash
# Con az autenticado con la nueva cuenta:
az account show --query '{id:id, tenantId:tenantId}' -o json
```

Actualizar `~/.zshrc`:

```bash
export AZURE_SUBSCRIPTION_ID=<nuevo-subscription-id>
export AZURE_TENANT_ID=<nuevo-tenant-id>
export AZURE_RESOURCE_GROUP=<nuevo-resource-group>
```

### 3. Actualizar docs/05-env-vars.md

Reflejar los nuevos valores en la tabla de estado y hacer commit.

### 4. Verificar

```bash
source ~/.zshrc
az login --use-device-code
./scripts/00-check-auth.sh
```

Con `@outlook.com` el login no requiere `--tenant` ni deshabilitar Security Defaults.
