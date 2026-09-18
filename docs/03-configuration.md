# Configuración

Referencia de los archivos de configuración del proyecto.

---

## `vite.config.ts`

```ts
build: {
  outDir: 'build',  // Azure SWA requiere 'build/', no el default 'dist/'
}

test: {
  environment: 'jsdom',  // simular DOM en tests unitarios
  globals: true,         // describe/test/expect sin import
  setupFiles: ['./src/test/setup.ts'],
}
```

---

## `staticwebapp.config.json`

| Sección | Qué hace |
|---|---|
| `navigationFallback` | Redirige rutas no encontradas a `index.html` — necesario para SPAs con routing del lado del cliente |
| `globalHeaders` | Headers de seguridad aplicados a todas las respuestas |
| `mimeTypes` | Fuerza `application/json` para archivos `.json` |
| `responseOverrides` | Convierte 404 en 200 + `index.html` para que el router del cliente maneje la ruta |

El `exclude` del `navigationFallback` evita que assets y archivos estáticos sean interceptados:
```json
"exclude": ["/assets/*", "*.{ico,png,svg,webp,jpg,jpeg,gif,woff,woff2}"]
```

Cuando se agregue `public/config.json`, añadir `/config.json` a ese array.

---

## `.nvmrc`

```
22
```

Fija la versión de Node en 22 para desarrollo local. En CI, el workflow usa `node-version: '22'` explícitamente — el `.nvmrc` es solo para entornos locales con `nvm`.

---

## `tsconfig.app.json`

Puntos relevantes:

| Opción | Valor | Por qué |
|---|---|---|
| `types` | `["vite/client", "vitest/globals"]` | Acceso a `import.meta.env` y a globals de Vitest (`describe`, `test`, `expect`) sin imports |
| `moduleResolution` | `"bundler"` | Modo moderno — permite imports con extensión `.ts` |
| `verbatimModuleSyntax` | `true` | Fuerza `import type` para imports de solo tipos — evita side effects en tree-shaking |

---

## Workflow de GitHub Actions

Archivo: `.github/workflows/azure-static-web-apps-<nombre>.yml`

El archivo en este repo (`-REPLACE-NAME.yml`) es un template. Al conectar a Azure, reemplazarlo con el generado automáticamente.

Pasos que debe contener (en orden):

```yaml
- uses: actions/checkout@v4

- name: Set up Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '22'
    cache: 'npm'

- run: npm ci
- run: npm run test:run
- run: npm run build

# Pasos OIDC (generados por Azure — no modificar)
- name: Install OIDC Client from Core Package
  run: npm install @actions/core@1.6.0 @actions/http-client

- name: Get Id Token
  uses: actions/github-script@v6
  id: idtoken
  with:
    script: |
      const coredemo = require('@actions/core')   # NO usar 'core'
      return await coredemo.getIDToken()
    result-encoding: string

- name: Build And Deploy
  uses: Azure/static-web-apps-deploy@v1
  with:
    azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN_<SUFFIX> }}
    action: "upload"
    app_location: "/"
    output_location: "build"
    github_id_token: ${{ steps.idtoken.outputs.result }}
```

Ver [plan/Contrato_GitHub_Actions_Azure_SWA.md](../plan/Contrato_GitHub_Actions_Azure_SWA.md) para el workflow completo incluyendo el job de cierre de PR.
