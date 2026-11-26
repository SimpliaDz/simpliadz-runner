# SimpliaWear local development

This folder is the shared local-development entry point for the three sibling repositories:

- `../simplia-wear-api` — .NET API and database tooling
- `../simplia-web` — Angular web application
- `../simplia-mobile` — Flutter mobile application

It centralizes local startup settings and the private development tenant catalog. Production deployments provide their own protected configuration.

The product is branded **SimpliaWear**. The runner uses the sibling checkout names above and the existing private tenant configuration. Keep those names when following the commands in this guide.

## First-time setup

From this folder, create your private configuration file:

```powershell
Copy-Item .\config\local.example.json .\config\local.json
Copy-Item .\config\tenants.example.json .\config\tenants.local.json
```

Set the SQL connection string and enabled modules in `config/tenants.local.json`. Update `api.phoneHost` with the IPv4 address of the development PC on the same Wi-Fi/LAN as a physical phone. Leave `api.listenHost` as `0.0.0.0` when testing from another device; use `127.0.0.1` when only the PC will reach the API.

`api.tenantCatalogPath` points to the private catalog, relative to this repository or by absolute path. `api.activeTenantId` selects an entry for the local API instance. The migrator takes an explicit tenant ID. Both processes read the same catalog; the backend owns its schema, migrations, and tenant validation.

`config/local.json` and `config/tenants.local.json` are ignored by Git. Keep production credentials in a secret store.

## Daily workflow

Open separate PowerShell terminals in this folder:

```powershell
.\scripts\start-database.ps1
.\scripts\start-api.ps1
.\scripts\start-web.ps1
.\scripts\test-web-build.ps1
.\scripts\run-mobile-emulator.ps1
.\scripts\run-mobile-phone.ps1
```

`start-web.ps1` prompts you to choose English, French, or Arabic before starting Angular. To skip the prompt, pass a language code:

```powershell
.\scripts\start-web.ps1 -Language fr
```

To test the production-style, folder-based localization build (including the saved language redirect), run:

```powershell
.\scripts\test-web-build.ps1
```

It builds the web app, then serves English at `/`, French at `/fr/`, and Arabic at `/ar/` on `http://localhost:4300`. It also proxies `/api` to the local API, so sign-in and saved language preferences work exactly as they do behind a production reverse proxy. Use `-NoBuild` to reuse an existing localized build or `-Port 4301` to select a different port.

The web app uses the repository's Yarn 4 configuration and lockfile; do not use npm to install its dependencies.

To temporarily serve a different migrated tenant without editing `local.json`:

```powershell
.\scripts\start-api.ps1 -TenantId new-tenant-id
```

The scripts use one profile to select the correct connectivity route:

| Consumer | API address |
| --- | --- |
| Angular browser app | `http://localhost:5278`, reached through Angular's `/api` proxy |
| Android emulator | `http://10.0.2.2:5278` |
| Phone on Wi-Fi | `http://<api.phoneHost>:5278` |

To check the profile, project locations, and required commands:

```powershell
.\scripts\doctor.ps1
```

## Adding a local tenant

1. Add the tenant descriptor and a unique SQL database name to `config/tenants.local.json`.
2. Start SQL Server with `./scripts/start-database.ps1`.
3. Create its schema and local admin with:

   ```powershell
   .\scripts\migrate-tenant.ps1 -TenantId new-tenant-id
   ```

   Add `-SeedDemo` only when you want disposable demo records.
4. Run that tenant's API with:

   ```powershell
   .\scripts\start-api.ps1 -TenantId new-tenant-id
   ```

The web app and mobile app automatically use the API process currently running on port `5278`. Stop the previous API before switching tenants, then sign out and sign in again: tokens are tenant-specific.

## Configuration ownership

This folder owns developer-machine orchestration and the private local tenant catalog. Applications remain responsible for their runtime behavior:

- The backend reads the tenant catalog path supplied by `SIMPLIAWEAR_TENANTS_FILE`, validates the selected tenant, and owns migrations and server behavior. A future control plane can replace the file-backed catalog.
- The web app owns its deploy-time `public/config/app-config.json` and production reverse-proxy design.
- The mobile app owns its `API_BASE_URL` Dart define and production build configuration.

For a physical phone, the API must listen on `0.0.0.0`, Windows Firewall must permit its private-network port, and the phone must be on the same network. Production should use HTTPS and a stable public API domain; do not use a private LAN address.
