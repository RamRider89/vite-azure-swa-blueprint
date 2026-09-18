# Autenticación — Cuentas personales

Estado y proceso de login para operar este blueprint con las cuentas personales.

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

```bash
# Verificar scopes activos
gh auth status
```

Editar en: **github.com → Settings → Developer settings → Personal access tokens → Fine-grained tokens**

---

## Azure CLI (`az`)

### Estado actual

```
Cuenta:       carloss_duartes@live.com.mx
Tenant:       bc31de7d-3859-4df0-9fc0-091b2c8810d4 (Default Directory)
Suscripción:  ninguna — pendiente de crear
Estado:       ⚠ autenticado, sin suscripción activa
```

### Error encontrado durante el login

```
AADSTS530035: Access has been blocked by security defaults.
Tenant: bc31de7d-3859-4df0-9fc0-091b2c8810d4 'Default Directory'
No subscriptions found for carloss_duartes@live.com.mx.
```

**Qué significa:**
- La autenticación de la cuenta personal fue exitosa
- El tenant `Default Directory` (creado automáticamente por Microsoft) bloqueó el acceso con security defaults — no afecta el uso de Azure con una suscripción propia
- La cuenta no tiene suscripción de Azure activa — sin ella no se pueden crear recursos

### Crear suscripción (paso necesario)

Para usar Azure Static Web Apps se requiere una suscripción activa. El free tier es suficiente para este blueprint:

**https://azure.microsoft.com/free**

Incluye:
- $200 USD de crédito por 30 días
- Static Web Apps Free tier — gratis indefinidamente (sin tarjeta después del período)

### Login en WSL (método probado)

```bash
az login --use-device-code
```

Salida esperada:
```
To sign in, use a web browser to open the page https://login.microsoft.com/device
and enter the code XXXXXXXX to authenticate.
```

Abrir en el browser de Windows, ingresar el código y autenticar con `carloss_duartes@live.com.mx`.

### Una vez creada la suscripción

```bash
# Autenticar
az login --use-device-code

# Verificar que la suscripción aparece
az account list --output table

# Establecer como default si hay más de una
az account set --subscription "<nombre-o-id>"

# Confirmar
az account show
```

### Renovar sesión expirada

```bash
az login --use-device-code
```

La sesión de az dura ~1 hora en WSL.

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
  ✓ suscripción:   <nombre de la suscripción>
  ✓ id:            xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  ✓ Static Web Apps en la suscripción: 0

────────────────────────────────────────────────
✓ Todo en orden. Listo para usar 01-create-repo.sh.
```

---

## Flujo de trabajo completo

```bash
# 1. Verificar cuentas
./scripts/00-check-auth.sh

# 2. Si az no tiene suscripción → crear en https://azure.microsoft.com/free
#    Luego re-autenticar:
az login --use-device-code

# 3. Crear nuevo proyecto desde el blueprint
./scripts/01-create-repo.sh --name mi-app --rg rg-mi-app
```
