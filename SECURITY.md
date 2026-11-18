# Security Policy

## Reporting a Vulnerability

**Please do NOT open a public GitHub Issue for security vulnerabilities.**

Instead, report security issues privately through GitHub Security Advisories on the affected repository:

- **Server & Embedded Web UI**: [Report a vulnerability in `pve-panel`](https://github.com/Fairy-Jeux/pve-panel/security/advisories/new)
- **Apple Native Apps**: [Report a vulnerability in `pve-center-apple`](https://github.com/Fairy-Jeux/pve-center-apple/security/advisories/new)
- **Desktop & Android Clients**: [Report a vulnerability in `pve-center-clients`](https://github.com/Fairy-Jeux/pve-center-clients/security/advisories/new)
- **Docs Portal**: [Report a vulnerability in `pve-center-website`](https://github.com/Fairy-Jeux/pve-center-website/security/advisories/new)

Please include:

- Affected repository and component (e.g., DualAuth middleware, `/api/pairing/*`, Tauri HTTP capability, Capacitor network config)
- Clear description of the vulnerability and potential impact
- Minimal reproduction steps or proof-of-concept
- Any suggested fix or mitigation if available

We aim to acknowledge reports within **48 hours** and coordinate disclosure responsibly.

## Ecosystem Security Architecture

- **DualAuth Middleware (`pve-panel`)**: Loopback requests validate `Tailscale-User-Login` headers against `security.allowed_tailscale_users`; LAN, WebSocket, and SSE clients require SHA-256 hashed Bearer tokens (`pve_...`) or HS256 JWT sessions (`PBKDF2-HMAC-SHA256` Admin PIN).
- **Encrypted Pairing Relay**: Apple TV 6-digit PIN onboarding encrypts credentials client-side using `ECDH P-256` + `HKDF-SHA256` + `AES-256-GCM` with single-use 5-minute TTL sessions and rate-limited lookups.
- **Credential Hygiene**: Secrets are masked in API responses (`********`), `${VAR_NAME}` placeholders are preserved on YAML writes, and `install.sh` applies `0700` / `0600` file permissions.
- **Proxmox Self-Shutdown Safeguard**: `proxmox.panel_self_vmid` prevents accidentally stopping or shutting down the host LXC/VM running `pve-panel`.
