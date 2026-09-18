# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev        # dev server at http://localhost:5173
npm run build      # tsc -b && vite build → build/
npm run lint       # oxlint
npm run preview    # preview production build at http://localhost:4173
npm run test:run   # vitest run (CI mode, no watch)
```

Node version: 22 (`.nvmrc`). Run `nvm use` before any npm command — the shell default may be v18, which is too old for Vite 8 and Vitest 2.

## Scripts

Wrappers that handle `nvm use` automatically and combine common operations:

```bash
./scripts/01-create-repo.sh --name <repo> --rg <resource-group> [--location eastus2] [--private]
./scripts/02-dev.sh                                                    # nvm use + npm run dev
./scripts/03-build.sh                                                  # lint → test → build
./scripts/04-deploy-status.sh [--limit N] [--logs <id>] [--open <id>] # últimos runs del workflow Azure SWA
```

`01-create-repo.sh` requiere `gh` y `az` autenticados. Crea el repo en GitHub, el resource group en Azure, y el recurso Static Web App (que a su vez inyecta el workflow y el secret en GitHub automáticamente).

## Project purpose

Reference blueprint for deploying Vite + React + TypeScript apps to Azure Static Web Apps via GitHub Actions + OIDC. The repo is meant to be cloned, connected to Azure, and used as a starting point — not just read.

## Architecture

`src/` is currently the default Vite scaffold (counter demo). The planned architecture (from `plan/Contrato_Claude_ViteAzureSWA.md`) replaces it with:

- `public/config.json` — runtime configuration (title, colors, URLs). **Never put user-configurable values in `src/` or `import.meta.env`** — everything configurable must live here and be loaded at runtime so the app can be reconfigured without a rebuild.
- `src/hooks/useConfig.ts` — fetches `/config.json` at runtime
- `src/types/config.ts` — TypeScript interface for the config shape

The `plan/` directory contains the authoritative technical contracts:
- `plan/Contrato_GitHub_Actions_Azure_SWA.md` — full CI/CD guide including the exact workflow YAML, all Azure SWA constraints, and troubleshooting for every known error
- `plan/Contrato_Claude_ViteAzureSWA.md` — project scope, acceptance criteria, and pending work (Vitest setup, demo app, docs/, scripts/)

## Azure SWA constraints (non-obvious, discovered in production)

1. **Output dir must be `build/`** — Azure Oryx builder expects `build/`, not Vite's default `dist/`. Already set in `vite.config.ts`. The workflow must also use `output_location: "build"`.

2. **Workflow filename is immutable** — Azure OIDC verifies the exact filename `azure-static-web-apps-<adjective>-<noun>-<hex>.yml`. Renaming it breaks deployment with the error `Could not determine the Static Web App from the GitHub OIDC workflow reference`.

3. **Secret name includes the resource suffix** — Azure creates `AZURE_STATIC_WEB_APPS_API_TOKEN_<ADJECTIVE>_<NOUN>_<HEX>`, not a generic name. Check with: `gh api /repos/<owner>/<repo>/actions/secrets --jq '.secrets[].name'`

4. **OIDC is required in addition to the deployment token** — the workflow needs `permissions: id-token: write` and the github-script steps to obtain the token.

5. **`core` is a reserved variable in `actions/github-script`** — use any other name (e.g. `coredemo`) when requiring `@actions/core` inside a github-script step.

## Key files

| File | Purpose |
|---|---|
| `vite.config.ts` | `outDir: 'build'` — critical for Azure SWA |
| `staticwebapp.config.json` | SPA fallback routing + security headers |
| `.github/workflows/azure-static-web-apps-REPLACE-NAME.yml` | Template workflow — replace with the one Azure generates |
| `plan/Contrato_GitHub_Actions_Azure_SWA.md` | Full CI/CD reference with complete workflow YAML |

## Pending work

See `plan/Contrato_Claude_ViteAzureSWA.md` for the full task list. Key items not yet implemented:

- Vitest 2 + Testing Library setup (`npm run test:run`)
- `public/config.json` + runtime config loading
- Demo app replacing the Vite scaffold
- `docs/` directory (architecture, deployment, configuration, scripts)
- `scripts/` directory (dev.sh, build.sh, deploy-status.sh, create-repo.sh)
