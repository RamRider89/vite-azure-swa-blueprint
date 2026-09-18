# Contrato de Desarrollo — Vite Azure SWA Blueprint

## Objetivo

Construir y mantener un **repositorio de referencia** para desplegar aplicaciones de páginas estáticas (Vite + React + TypeScript) en Azure Static Web Apps mediante GitHub Actions con autenticación OIDC.

El repo debe funcionar como:
1. **Plantilla funcional** — clonable y lista para conectar a Azure
2. **Guía operativa** — documenta las restricciones no obvias de Azure SWA descubiertas en producción
3. **Blueprint reutilizable** — aplicable a cualquier proyecto estático, no solo React

---

## Estado inicial (entregado por agente anterior)

Ya existe en `/home/idavid/dev/davdav/vite-azure-swa-blueprint/`:

| Archivo | Estado |
|---|---|
| `vite.config.ts` | `outDir: 'build'` configurado |
| `staticwebapp.config.json` | SPA fallback + headers de seguridad |
| `.github/workflows/azure-static-web-apps-REPLACE-NAME.yml` | Template del workflow con OIDC |
| `.nvmrc` | Node 22 |
| `plan/Contrato_GitHub_Actions_Azure_SWA.md` | Guía completa con troubleshooting |
| `README.md` | Quickstart básico |
| `src/` | Scaffold Vite por defecto (counter demo) |

Repositorio en GitHub: `https://github.com/RamRider89/vite-azure-swa-blueprint`

---

## Alcance del nuevo agente

### Prioridad 1 — Estructura y configuración

- [ ] Crear `CLAUDE.md` en la raíz con instrucciones para futuros agentes
- [ ] Configurar Vitest + Testing Library (misma configuración que el proyecto de referencia)
- [ ] Agregar script `npm run test:run` que usa el workflow en CI
- [ ] Crear `scripts/` con: `dev.sh`, `build.sh`, `deploy-status.sh`, `create-repo.sh`
- [ ] Reemplazar el scaffold por defecto de Vite (counter) con un ejemplo mínimo y limpio

### Prioridad 2 — Documentación

- [ ] Crear `docs/` con: `architecture.md`, `deployment.md`, `configuration.md`, `scripts.md`
- [ ] `docs/deployment.md` — paso a paso detallado: crear recurso Azure → conectar repo → workflow → verificar deploy
- [ ] `docs/architecture.md` — estructura del proyecto y decisiones de diseño
- [ ] Actualizar `README.md` con badges de CI, link a docs y ejemplo visual

### Prioridad 3 — Ejemplo de app

- [ ] Página de demostración que muestre las capacidades del blueprint:
  - Configuración en runtime desde `public/config.json` (sin recompilar)
  - Soporte de tema (colores desde config)
  - i18n básico (es/en)
  - Responsive mobile-first
- [ ] La app debe ser lo suficientemente simple para entenderse a primera vista, pero lo suficientemente completa para mostrar buenas prácticas

### Prioridad 4 — CI/CD y calidad

- [ ] Verificar que el workflow template pasa lint + test + build sin errores
- [ ] Lighthouse ≥ 90 en build de producción
- [ ] Agregar Open Graph meta tags en `index.html`

---

## Stack

| Capa | Tecnología |
|---|---|
| Framework | React 19 + TypeScript |
| Bundler | Vite 8 |
| Runtime | Node 22 (vía nvm) |
| Tests | Vitest 2 + Testing Library |
| CI/CD | GitHub Actions + Azure Static Web Apps deploy action |
| Deploy | Azure Static Web Apps Free tier |

---

## Restricciones críticas de Azure SWA

Estas restricciones se descubrieron empíricamente en producción. **No ignorar.**

### 1. Nombre del workflow es fijo

Azure SWA OIDC verifica que el deploy venga del archivo:
```
azure-static-web-apps-<adjective>-<noun>-<hex>.yml
```
Renombrarlo rompe el deploy. El archivo de este repo es un *template* — cuando Azure genere el suyo, ese archivo reemplaza al template.

### 2. Output directory: `build/`, no `dist/`

Azure SWA Oryx builder espera `build/`. Vite por defecto usa `dist/`.
Configurar en `vite.config.ts`:
```ts
build: { outDir: 'build' }
```
Y en el workflow:
```yaml
output_location: "build"
```

### 3. OIDC es obligatorio además del deployment token

El workflow necesita:
```yaml
permissions:
  id-token: write
```
Y los pasos para obtener el token via `actions/github-script`. Sin OIDC el deployment token solo no es suficiente.

### 4. Secret name incluye sufijo del recurso

Azure crea: `AZURE_STATIC_WEB_APPS_API_TOKEN_<ADJECTIVE>_<NOUN>_<HEX>`  
No el genérico `AZURE_STATIC_WEB_APPS_API_TOKEN`.

### 5. Variable `core` reservada en github-script

En `actions/github-script`, `core` es una variable interna. Usar otro nombre:
```js
const coredemo = require('@actions/core')  // ✓
const core = require('@actions/core')      // ✗ SyntaxError
```

---

## Arquitectura objetivo

```
.github/
  workflows/
    azure-static-web-apps-REPLACE-NAME.yml   # template — reemplazar con el generado por Azure
docs/
  architecture.md
  deployment.md
  configuration.md
  scripts.md
plan/
  Contrato_Claude_ViteAzureSWA.md            # este archivo
  Contrato_GitHub_Actions_Azure_SWA.md       # guía técnica CI/CD
public/
  config.json                                # configuración en runtime
scripts/
  dev.sh
  build.sh
  deploy-status.sh
  create-repo.sh
src/
  types/config.ts                            # interfaz de config
  hooks/useConfig.ts                         # fetch /config.json en runtime
  components/                                # componentes de la app demo
  App.tsx
  main.tsx
  index.css
staticwebapp.config.json
vite.config.ts                               # outDir: 'build'
.nvmrc                                       # Node 22
CLAUDE.md                                    # instrucciones para agentes Claude
```

---

## Regla de configuración

**Nunca** importar valores de usuario desde `import.meta.env` o constantes en `src/`.  
Todo lo configurable vive en `public/config.json` y se carga en runtime.  
Esto permite cambiar título, colores, URLs sin recompilar — solo editar el JSON y hacer deploy.

---

## Criterios de aceptación

- `npm run dev` levanta el servidor en localhost:5173
- `npm run build` genera en `build/` sin errores
- `npm run test:run` corre los tests y pasa
- El workflow template incluye todos los pasos necesarios para conectar a Azure sin modificaciones adicionales más allá de renombrar el archivo y actualizar el nombre del secret
- `docs/deployment.md` permite a alguien sin contexto previo conectar el repo a Azure y tener un deploy exitoso
- La app demo es funcional, responsive y carga `public/config.json` en runtime
- Lighthouse ≥ 90 en production build

---

## Instrucción para el nuevo agente

Trabajar en `/home/idavid/dev/davdav/vite-azure-swa-blueprint/`.

Prioridades en orden:

1. Leer `plan/Contrato_GitHub_Actions_Azure_SWA.md` — contiene todos los detalles técnicos del CI/CD
2. Crear `CLAUDE.md` con las instrucciones del proyecto antes de cualquier código
3. Configurar Vitest y agregar `npm run test:run`
4. Construir la app demo con config en runtime
5. Generar `docs/` completo
6. Verificar Lighthouse en production build

Referencia del proyecto que originó este blueprint: `https://github.com/RamRider89/regina-countdown`  
Ese proyecto tiene implementación de producción funcional con el mismo stack y CI/CD.
