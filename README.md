# Vite + Azure Static Web Apps — Blueprint

Plantilla para desplegar una app **Vite + React + TypeScript** en **Azure Static Web Apps** con GitHub Actions y autenticación OIDC.

Incluye todas las configuraciones no obvias descubiertas en producción. Ver `plan/Contrato_GitHub_Actions_Azure_SWA.md` para la guía completa.

## Stack

- React 19 + TypeScript
- Vite 8 (`outDir: 'build'` — requerido por Azure SWA)
- GitHub Actions + OIDC
- Azure Static Web Apps Free tier

## Quickstart

### 1. Instalar dependencias

```bash
npm install
```

### 2. Desarrollo local

```bash
npm run dev       # http://localhost:5173
npm run build     # build → build/
npm run preview   # preview del build en http://localhost:4173
```

### 3. Conectar a Azure Static Web Apps

1. Azure Portal → Static Web Apps → **+ Create**
2. Conectar este repo, rama `main`
3. Build preset: **Custom**
4. App location: `/` · Output location: `build` · API location: *(vacío)*
5. Azure generará el archivo `.github/workflows/azure-static-web-apps-<nombre>.yml`
6. Reemplazar el workflow template de este repo con el generado por Azure
7. Agregar los pasos Node/test/build al archivo generado (marcados con `# ADD` en el template)

> El nombre del workflow NO puede cambiar después — Azure lo verifica para OIDC.

### 4. Secrets

Azure crea automáticamente el secret en GitHub:

```
AZURE_STATIC_WEB_APPS_API_TOKEN_<ADJECTIVE>_<NOUN>_<HEX>
```

Verificar el nombre exacto:

```bash
gh api /repos/<owner>/<repo>/actions/secrets --jq '.secrets[].name'
```

## Estructura

```
.github/
  workflows/
    azure-static-web-apps-REPLACE-NAME.yml  ← reemplazar con el generado por Azure
src/                                         ← código de la app
staticwebapp.config.json                     ← SPA fallback + headers de seguridad
vite.config.ts                               ← outDir: 'build' (crítico para Azure)
plan/
  Contrato_GitHub_Actions_Azure_SWA.md       ← guía completa con troubleshooting
```

## Troubleshooting

Ver `plan/Contrato_GitHub_Actions_Azure_SWA.md` para los errores más comunes y sus soluciones.
