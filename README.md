# Unixplay adapters

Marketplace adapters for applications that need integration beyond a native Entware package. Each app lives under `apps/<id>/` and is published as a release asset named `<id>-<version>.tar.gz`.

## S-UI migration

The `keenplay-s-ui` adapter adopts the Keenetic S-UI installation already present at `/opt/etc/s-ui`. It keeps S-UI's database, certificates, configs, init service and running tunnels in place. Installation checks the existing files and registers the adapter with Unixplay; it does not run S-UI's upstream installer.

The adapter update action updates only the S-UI core binary from the official `alireza0/s-ui` GitHub release, verifying GitHub's published SHA-256 digest first. A scheduled workflow tracks upstream releases and publishes a matching marketplace bundle every six hours. It retains the prior binary for marketplace rollback and leaves the database and configuration untouched. Removing the adapter from Unixplay detaches marketplace management and leaves S-UI running; it never deletes user data or disables the router service.

See [`apps/keenplay-s-ui/MIGRATION.md`](apps/keenplay-s-ui/MIGRATION.md) before adopting an installation.
