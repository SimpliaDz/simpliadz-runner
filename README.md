# SimpliaDz local development

This folder is the shared local-development entry point for the three sibling repositories:

- `../simpliadz-platform` — .NET API and database tooling
- `../simpliadz-web` — Angular web application
- `../simpliadz-mobile` — Flutter mobile application

It centralizes machine-specific endpoints without coupling production builds or storing secrets outside the application that owns them.

## First-time setup

From this folder, create your private configuration file:

```powershell
Copy-Item .\config\local.example.json .\config\local.json
```

Then update `api.phoneHost` with the IPv4 address of the development PC on the same Wi-Fi/LAN as a physical phone. Leave `api.listenHost` as `0.0.0.0` when testing from another device; use `127.0.0.1` when only the PC will reach the API.

`api.activeTenantId` selects an existing tenant from `../simpliadz-platform/src/tenants.json`. It only selects the tenant served by the local API process; the tenant descriptor, database connection string, modules, migrations, and seed data remain owned by the backend repository.

`config/local.json` is intentionally ignored by Git. Do not put database passwords, tokens, or production URLs in this folder.

## Daily workflow

Open separate PowerShell terminals in this folder:

```powershell
.\scripts\start-database.ps1
.\scripts\start-api.ps1
.\scripts\start-web.ps1
.\scripts\run-mobile-emulator.ps1
.\scripts\run-mobile-phone.ps1
```

`start-web.ps1` prompts you to choose English, French, or Arabic before starting Angular. To skip the prompt, pass a language code:

```powershell
.\scripts\start-web.ps1 -Language fr
```

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

1. Add the tenant descriptor and a unique SQL database name to `../simpliadz-platform/src/tenants.json`.
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

This folder owns only developer-machine orchestration. Each application remains the source of truth for its own runtime configuration:

- The API owns tenant settings, connection strings, migrations, and server configuration.
- The web app owns its deploy-time `public/config/app-config.json` and production reverse-proxy design.
- The mobile app owns its `API_BASE_URL` Dart define and production build configuration.

For a physical phone, the API must listen on `0.0.0.0`, Windows Firewall must permit its private-network port, and the phone must be on the same network. Production should use HTTPS and a stable public API domain; do not use a private LAN address.
