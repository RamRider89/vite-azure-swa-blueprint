# Vite + Azure Static Web Apps — Blueprint

Plantilla para desplegar una app **Vite + React + TypeScript** en **Azure Static Web Apps** con GitHub Actions y autenticación OIDC.

Documenta las restricciones no obvias descubiertas en producción que no están en la documentación oficial de Azure.

## Stack

- React 19 + TypeScript · Vite 8 · Node 22
- Vitest 2 + Testing Library
- GitHub Actions + OIDC
- Azure Static Web Apps Free tier

## Quickstart

```bash
nvm use
npm install
npm run dev        # http://localhost:5173
```

## Deploy a Azure

```bash
./scripts/01-create-repo.sh --name mi-app --rg rg-mi-app
```

Requiere `gh auth login` y `az login`. Ver [docs/02-deployment.md](docs/02-deployment.md) para el proceso manual paso a paso.

## Documentación

| Doc | Contenido |
|---|---|
| [docs/01-architecture.md](docs/01-architecture.md) | Por qué `outDir: 'build'`, OIDC, configuración en runtime, staging automático |
| [docs/02-deployment.md](docs/02-deployment.md) | Guía completa: crear recurso Azure → conectar repo → verificar deploy → troubleshooting |
| [docs/03-configuration.md](docs/03-configuration.md) | Referencia de `vite.config.ts`, `staticwebapp.config.json`, workflow YAML |
| [docs/04-scripts.md](docs/04-scripts.md) | Uso de `01-create-repo.sh`, `02-dev.sh`, `03-build.sh`, `04-deploy-status.sh` |
| [plan/Contrato_GitHub_Actions_Azure_SWA.md](plan/Contrato_GitHub_Actions_Azure_SWA.md) | Workflow YAML completo + todos los errores conocidos |

## Estructura

```
.github/workflows/
  azure-static-web-apps-REPLACE-NAME.yml  ← reemplazar con el generado por Azure
docs/                                      ← guías de uso
scripts/                                   ← 01-create-repo.sh · 02-dev.sh · 03-build.sh · 04-deploy-status.sh
src/                                       ← código de la app
staticwebapp.config.json                   ← SPA fallback + headers de seguridad
vite.config.ts                             ← outDir: 'build' (crítico para Azure)
plan/                                      ← contratos de referencia técnica
```
