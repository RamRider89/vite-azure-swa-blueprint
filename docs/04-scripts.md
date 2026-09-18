# Scripts

Los scripts en `scripts/` requieren `bash` y manejan `nvm use` automáticamente.

---

## `02-dev.sh`

```bash
./scripts/02-dev.sh
```

Activa Node 22 desde `.nvmrc` y corre `npm run dev`. Dev server en `http://localhost:5173` con HMR.

---

## `03-build.sh`

```bash
./scripts/03-build.sh
```

Corre en orden: lint → test → build. Si cualquier paso falla, el script se detiene. Al terminar muestra el tamaño del directorio `build/`.

Útil para verificar localmente que el build que va a CI es limpio antes de hacer push.

---

## `04-deploy-status.sh`

```bash
./scripts/04-deploy-status.sh [--limit N] [--logs <run-id>] [--open <run-id>]
```

Detecta automáticamente el archivo `azure-static-web-apps-*.yml` en `.github/workflows/` y consulta la API de GitHub Actions.

| Flag | Descripción |
|---|---|
| `--limit N` | Número de runs a mostrar (default: 5) |
| `--logs <run-id>` | Muestra los logs de los pasos fallidos de ese run |
| `--open <run-id>` | Abre el run en el browser |

Flujo típico cuando un deploy falla:

```bash
# 1. Ver cuál run falló
./scripts/04-deploy-status.sh

# 2. Ver qué paso falló
./scripts/04-deploy-status.sh --logs 15234567

# 3. Re-trigger
gh run rerun 15234567 --failed
```

Requiere `gh auth login`.

---

## `01-create-repo.sh`

```bash
./scripts/01-create-repo.sh \
  --name <repo-name> \
  --rg <resource-group> \
  [--location eastus2] \
  [--private]
```

Setup completo del blueprint en un nuevo proyecto. Requiere `gh auth login` y `az login`.

| Flag | Obligatorio | Descripción |
|---|---|---|
| `--name` | ✓ | Nombre del repo GitHub y del recurso Azure SWA |
| `--rg` | ✓ | Nombre del resource group de Azure |
| `--location` | — | Región Azure (default: `eastus2`) |
| `--private` | — | Crear repo privado (default: público) |

Qué hace internamente:
1. `gh repo create` — crea el repo y hace push del código actual
2. `az group create` — crea el resource group
3. `az staticwebapp create --login-with-github` — crea el recurso y deja que Azure inyecte el workflow y el secret en GitHub
4. Verifica que el secret fue creado e imprime la URL de producción y los próximos pasos

> Después de ejecutar este script, Azure habrá generado un nuevo workflow en el repo. Reemplazar el template `azure-static-web-apps-REPLACE-NAME.yml` con ese archivo.
