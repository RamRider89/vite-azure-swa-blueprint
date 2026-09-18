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

Editar en: **github.com → Settings → Developer settings → Personal access tokens → Fine-grained tokens**

---

## Azure CLI (`az`)

### Cuentas y suscripciones

```
Cuenta:          carloss_duartes@live.com.mx
Suscripción:     1870859a-02b5-451f-8e1a-74b8cb5e1255
Resource Group:  RecursosTEST
Región default:  East Asia
```

SWA existente en esta suscripción:
```
Nombre:    regina-countdown
URL:       https://purple-pebble-07a0da800.5.azurestaticapps.net
Repo:      https://github.com/RamRider89/regina-countdown
```

### Login en WSL

```bash
az login --use-device-code
```

Abrir `https://login.microsoft.com/device` en el browser de Windows e ingresar el código.

### Problema conocido: tenant bc31de7d bloquea el discovery

Durante el login, el tenant `bc31de7d-3859-4df0-9fc0-091b2c8810d4` (Default Directory de Microsoft) devuelve:

```
AADSTS530035: Access has been blocked by security defaults.
No subscriptions found for carloss_duartes@live.com.mx.
```

**Causa:** el discovery automático de suscripciones falla en ese tenant. La suscripción `1870859a` existe y funciona, pero `az` no la detecta sola.

**Fix — apuntar directamente al subscription ID:**

```bash
az login --use-device-code --subscription 1870859a-02b5-451f-8e1a-74b8cb5e1255
```

Esto carga la suscripción directamente sin pasar por el tenant problemático.

**O, si ya se autenticó, establecer la suscripción manualmente:**

```bash
az account set --subscription 1870859a-02b5-451f-8e1a-74b8cb5e1255
az account show
```

### Verificar acceso una vez autenticado

```bash
# Confirmar suscripción activa
az account show --query '{name:name, id:id, user:user.name}' --output table

# Listar SWAs en la suscripción
az staticwebapp list --output table
```

### Renovar sesión expirada

La sesión de az dura ~1 hora en WSL.

```bash
az login --use-device-code --subscription 1870859a-02b5-451f-8e1a-74b8cb5e1255
```

---

## Verificación conjunta

```bash
./scripts/00-check-auth.sh
```

Salida esperada:

```
── GitHub CLI (gh) ──────────────────────────────
  ✓ gh instalado: gh version 2.x.x
  ✓ sesión activa: RamRider89

── Azure CLI (az) ───────────────────────────────
  ✓ az instalado: 2.x.x
  ✓ sesión activa: carloss_duartes@live.com.mx
  ✓ suscripción:   <nombre>
  ✓ id:            1870859a-02b5-451f-8e1a-74b8cb5e1255
  ✓ Static Web Apps en la suscripción: 1

────────────────────────────────────────────────
✓ Todo en orden. Listo para usar 01-create-repo.sh.
```

---

## Flujo de trabajo completo

```bash
# 1. Verificar cuentas
./scripts/00-check-auth.sh

# 2. Si az no está autenticado
az login --use-device-code --subscription 1870859a-02b5-451f-8e1a-74b8cb5e1255

# 3. Crear nuevo proyecto desde el blueprint
./scripts/01-create-repo.sh --name mi-app --rg rg-mi-app
```
