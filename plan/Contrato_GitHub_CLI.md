# Contrato de Uso — GitHub CLI (`gh`)

Referencia operativa para gestionar repositorios, pull requests, Actions y secrets desde terminal.

---

## Instalación y autenticación

```bash
# Instalar (Ubuntu/Debian)
sudo apt install gh

# Instalar (macOS)
brew install gh

# Autenticar
gh auth login
# → seleccionar GitHub.com → HTTPS → autenticar via browser

# Verificar sesión activa
gh auth status
```

### Tipos de token

| Tipo | Prefijo | Editable después |
|---|---|---|
| Fine-grained PAT | `github_pat_...` | Sí — se pueden agregar/quitar permisos |
| Classic PAT | `ghp_...` | No — hay que crear uno nuevo |

Crear o editar: **GitHub.com → Settings → Developer settings → Personal access tokens**

### Scopes mínimos por operación

| Operación | Scope requerido |
|---|---|
| Leer repos públicos | *(ninguno)* |
| Leer repos privados | `repo` (classic) o `Contents: read` (fine-grained) |
| Crear repositorios | `repo` (classic) o `Administration: read/write` (fine-grained) |
| Gestionar secrets | `repo` (classic) o `Secrets: read/write` (fine-grained) |
| Leer GitHub Actions | `repo` (classic) o `Actions: read` (fine-grained) |
| Disparar workflows | `repo` (classic) o `Actions: write` (fine-grained) |

---

## Repositorios

```bash
# Crear repo interactivo
gh repo create

# Crear repo no interactivo
gh repo create <nombre> --public --description "descripción" --clone
gh repo create <nombre> --private --add-readme --gitignore Node

# Clonar repo
gh repo clone <owner>/<repo>
gh repo clone <owner>/<repo> /ruta/destino

# Ver info del repo actual
gh repo view

# Abrir repo en browser
gh repo view --web

# Listar repos del usuario
gh repo list --limit 20
gh repo list <org> --limit 20
```

---

## Pull Requests

```bash
# Crear PR (interactivo)
gh pr create

# Crear PR con título y body
gh pr create --title "feat: nueva funcionalidad" --body "descripción del cambio"

# Crear PR hacia rama específica
gh pr create --base main --head feature/mi-rama

# Listar PRs abiertos
gh pr list

# Ver PR específico
gh pr view 42
gh pr view 42 --web

# Revisar PR (approve/request-changes/comment)
gh pr review 42 --approve
gh pr review 42 --request-changes --body "falta test"

# Hacer merge
gh pr merge 42 --squash
gh pr merge 42 --merge
gh pr merge 42 --rebase

# Cerrar sin mergear
gh pr close 42

# Checkout local de un PR
gh pr checkout 42
```

---

## Issues

```bash
# Listar issues
gh issue list
gh issue list --label bug --state open

# Crear issue
gh issue create --title "Bug: descripción" --body "pasos para reproducir..."
gh issue create --label bug --assignee @me

# Ver issue
gh issue view 10

# Cerrar issue
gh issue close 10
gh issue close 10 --comment "resuelto en #42"
```

---

## GitHub Actions

```bash
# Listar runs de todos los workflows
gh run list --limit 10

# Listar runs de un workflow específico
gh run list --workflow azure-static-web-apps-purple-pebble-07a0da800.yml --limit 5

# Ver detalle de un run
gh run view <run-id>

# Ver logs de un run
gh run view <run-id> --log
gh run view <run-id> --log-failed   # solo los pasos fallidos

# Abrir run en browser
gh run view <run-id> --web

# Re-ejecutar un run fallido
gh run rerun <run-id>
gh run rerun <run-id> --failed       # solo los jobs fallidos

# Disparar workflow manualmente (requiere workflow_dispatch)
gh workflow run <workflow-name>
gh workflow run deploy.yml --field environment=production

# Listar workflows del repo
gh workflow list
```

---

## Secrets

```bash
# Listar secrets (solo nombres, los valores son opacos)
gh api /repos/<owner>/<repo>/actions/secrets --jq '.secrets[].name'

# Crear/actualizar secret desde variable de entorno
gh secret set MI_SECRET --body "$MI_VARIABLE_LOCAL"
gh secret set MI_SECRET --repo <owner>/<repo> --body "$MI_VARIABLE_LOCAL"

# Crear/actualizar secret desde stdin
echo "mi-valor-secreto" | gh secret set MI_SECRET

# Crear/actualizar secret desde archivo
gh secret set MI_SECRET < archivo.txt

# Eliminar secret
gh secret delete MI_SECRET

# Listar secrets de un entorno (environment secrets)
gh api /repos/<owner>/<repo>/environments/<env>/secrets --jq '.secrets[].name'
```

---

## API REST directa

Para operaciones no cubiertas por los comandos nativos:

```bash
# GET genérico
gh api /repos/<owner>/<repo>
gh api /user

# Con jq para filtrar
gh api /repos/<owner>/<repo>/actions/runs --jq '.workflow_runs[0].conclusion'

# POST
gh api /repos/<owner>/<repo>/issues \
  --method POST \
  --field title="Nuevo issue" \
  --field body="Descripción"

# Paginación automática
gh api /repos/<owner>/<repo>/issues --paginate --jq '.[].title'
```

---

## Flujos comunes

### Ciclo de desarrollo estándar

```bash
# 1. Crear rama
git checkout -b feature/mi-feature

# 2. Desarrollar y commitear
git add .
git commit -m "feat: descripción"

# 3. Push
git push -u origin feature/mi-feature

# 4. Crear PR
gh pr create --title "feat: descripción" --base main

# 5. Verificar CI
gh run list --limit 3

# 6. Merge cuando CI pasa
gh pr merge --squash
```

### Verificar y re-trigger deploy

```bash
# Ver último run del workflow de deploy
gh run list --workflow azure-static-web-apps-*.yml --limit 1

# Ver logs si falló
gh run view <run-id> --log-failed

# Re-trigger via commit vacío
git commit --allow-empty -m "ci: re-trigger deploy"
git push
```

### Rotar deployment token de Azure SWA

```bash
# 1. Regenerar token en Azure Portal
# 2. Actualizar el secret en GitHub
gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN_<SUFFIX> \
  --repo <owner>/<repo> \
  --body "$NUEVO_TOKEN"

# 3. Verificar que el secret existe con el nombre correcto
gh api /repos/<owner>/<repo>/actions/secrets --jq '.secrets[].name'
```

---

## Tips

- `gh` respeta la variable `GH_TOKEN` o `GITHUB_TOKEN` del entorno — no es necesario pasar `--auth` si está exportada.
- En scripts, agregar `--json` y `--jq` para parsear output programáticamente.
- `gh api` cubre cualquier endpoint de la API REST de GitHub que no tenga comando nativo.
- Los secrets de Actions son opacos — `gh secret list` solo muestra nombres, nunca valores.
