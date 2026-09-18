# Autenticación — Cuentas personales

Estado y proceso de login para operar este blueprint con las cuentas personales.

---

## GitHub CLI (`gh`)

### Estado actual

```
Cuenta:    RamRider89
Token:     fine-grained PAT (github_pat_11A3WZ3XI...)
Protocolo: SSH
```

La sesión está activa. `gh auth status` muestra dos entradas para la misma cuenta:

| Fuente | Estado | Por qué existe |
|---|---|---|
| `GITHUB_TOKEN` (env var) | active | La variable de entorno tiene precedencia |
| `~/.config/gh/hosts.yml` | inactive | Credencial almacenada en disco |

Ambas usan la misma token — no hay conflicto. La entrada activa es la de `GITHUB_TOKEN`.

### Renovar o cambiar la sesión

Si el token expira o hay que reautenticar:

```bash
# Desloguear la sesión activa
gh auth logout

# Volver a autenticar (abre browser)
gh auth login
# → GitHub.com → HTTPS → Login with a web browser
```

### Verificar scopes de la token

Los scopes mínimos requeridos por `01-create-repo.sh`:

| Operación | Scope requerido |
|---|---|
| Crear repositorios | `Administration: read/write` (fine-grained) |
| Gestionar secrets | `Secrets: read/write` (fine-grained) |
| Leer/disparar Actions | `Actions: read/write` (fine-grained) |

```bash
# Ver scopes activos
gh auth status
```

Si falta alguno, editar la token en:
**github.com → Settings → Developer settings → Personal access tokens → Fine-grained tokens**

---

## Azure CLI (`az`)

### Estado actual

```
Estado: sin sesión activa
```

### Login interactivo (personal)

```bash
az login
# → abre el browser
# → seleccionar la cuenta personal de Microsoft/Azure
# → confirmar en el browser
```

Al completar, la CLI muestra las suscripciones disponibles. Si hay más de una:

```bash
# Listar suscripciones
az account list --output table

# Establecer la suscripción activa
az account set --subscription "<nombre-o-id>"

# Confirmar
az account show
```

### Verificar acceso a Static Web Apps

```bash
# Listar SWAs existentes (debe devolver [] si no hay ninguna aún)
az staticwebapp list --output table
```

### Renovar sesión expirada

```bash
az login
```

La sesión de az dura ~1 hora en entornos interactivos. En WSL puede expirar más rápido.

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
  ✓ sesión activa: usuario@ejemplo.com
  ✓ suscripción:   Mi Suscripción
  ✓ id:            xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  ✓ Static Web Apps en la suscripción: 0

────────────────────────────────────────────────
✓ Todo en orden. Listo para usar 01-create-repo.sh.
```

---

## Flujo de trabajo recomendado

```bash
# 1. Verificar cuentas
./scripts/00-check-auth.sh

# 2. Si az no está autenticado
az login

# 3. Crear nuevo proyecto desde el blueprint
./scripts/01-create-repo.sh --name mi-app --rg rg-mi-app
```
