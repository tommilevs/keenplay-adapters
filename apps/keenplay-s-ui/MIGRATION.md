# Adopt an existing S-UI installation

Unixplay installs this adapter beside S-UI; it does not move the S-UI files. The migration check requires:

- `/opt/etc/s-ui/sui` executable;
- `/opt/etc/s-ui/s-ui.sh` executable;
- `/opt/etc/s-ui/db/s-ui.db` present;
- `/opt/etc/init.d/S99s-ui` present and executable.

On success, Unixplay records `keenplay-s-ui` as installed. The S-UI process, service, database, certificates, configs, ports, and peers are not rewritten. Re-running the install check is safe.

The marketplace update action replaces only the `sui` core executable after downloading the exact official version-matched arm64 release and checking its SHA-256 digest against GitHub's release API. It saves the previous binary under `/opt/etc/s-ui/cache/playkeen-adapter/` and restores it if the service does not start. Marketplace rollback runs the adapter rollback hook to restore that binary. S-UI data files are not included in this update. A scheduled workflow tracks upstream releases and republishes the adapter version every six hours.

Removing the adapter detaches Unixplay and deliberately leaves S-UI running. This prevents an ordinary marketplace removal from interrupting VPN traffic or deleting the S-UI database. Use S-UI's own uninstaller only when you intend to remove S-UI itself.
