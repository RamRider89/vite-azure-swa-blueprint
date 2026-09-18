# Arquitectura

Decisiones de diseño no obvias que explican por qué el repo está estructurado como está.

---

## Por qué `outDir: 'build'`

Vite por defecto compila a `dist/`. Azure SWA usa el builder Oryx (heredado de Create React App), que espera el artefacto en `build/`.

Sin este cambio el deploy falla con:
```
The app build failed to produce artifact folder: 'build'
```

Configurado en `vite.config.ts` y en el paso `output_location: "build"` del workflow.

---

## Por qué el workflow tiene nombre fijo

Azure SWA con OIDC verifica que el deploy provenga de un workflow con el nombre exacto asignado al crear el recurso:
```
azure-static-web-apps-<adjective>-<noun>-<hex>.yml
```

Renombrarlo rompe el OIDC. El archivo en este repo (`azure-static-web-apps-REPLACE-NAME.yml`) es un **template** que documenta los pasos — cuando Azure genera el real, ese reemplaza al template.

---

## Por qué OIDC además del deployment token

El deploy action de Azure SWA requiere dos formas de autenticación:

1. **Deployment token** (`azure_static_web_apps_api_token`) — identifica el recurso Azure
2. **OIDC token** (`github_id_token`) — prueba que el deploy viene de un workflow autorizado de GitHub Actions

Sin OIDC el deploy falla aunque el token sea válido. Requiere en el workflow:
```yaml
permissions:
  id-token: write
  contents: read
```

---

## Por qué el secret tiene sufijo del recurso

Azure genera el nombre del secret a partir del nombre del recurso SWA:
```
AZURE_STATIC_WEB_APPS_API_TOKEN_PURPLE_PEBBLE_07A0DA800
```

El sufijo (`PURPLE_PEBBLE_07A0DA800`) es el nombre del recurso en mayúsculas. No existe un secret genérico `AZURE_STATIC_WEB_APPS_API_TOKEN`.

---

## `staticwebapp.config.json`

Configura el comportamiento de Azure SWA en producción. Las partes críticas:

```json
{
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["/assets/*", "*.{ico,png,svg,...}"]
  }
}
```

Sin `navigationFallback`, las rutas del cliente (React Router, etc.) retornan 404 en refresh o acceso directo por URL. Azure SWA no sirve SPAs por defecto.

Los `globalHeaders` son seguridad básica (CSP mínima, framing, referrer).

---

## Patrón de configuración en runtime (planeado)

La convención de este blueprint es que **nada configurable** (título, colores, URLs de API, feature flags) vive en `src/` ni en variables de entorno de build. Todo va en `public/config.json`.

Razón: permite cambiar configuración sin recompilar — solo editar el JSON y hacer deploy del archivo estático. Útil para configurar distintos entornos (staging/prod) sin builds separados.

```
public/config.json     ← leído en runtime por useConfig.ts
src/hooks/useConfig.ts ← fetch('/config.json') al montar la app
src/types/config.ts    ← interfaz TypeScript del config
```

El archivo `public/config.json` se excluye del `navigationFallback` en `staticwebapp.config.json` para que Azure lo sirva directamente sin reescribirlo a `index.html`.

---

## Entornos de staging

Por cada PR contra `main`, Azure SWA crea automáticamente un entorno de staging con URL temporal:
```
https://<adjective>-<noun>-<hex>-<pr-number>.azurestaticapps.net
```

Al cerrar el PR, el entorno se destruye. El workflow maneja esto con el job `close_pull_request_job`.
