# Getting Support

Need help deploying or configuring **PVE Command Center**? Start with the official documentation and route questions to the right repository so maintainers can help quickly.

## Documentation Portal

- **Website & Docs Portal**: [`Fairy-Jeux/pve-center-website`](https://github.com/Fairy-Jeux/pve-center-website)
  - Installation (`install.sh` Proxmox LXC & Docker Compose)
  - Architecture & DualAuth Security (Tailscale Serve SSO, Bearer / JWT, ECDH P-256 pairing)
  - Configuration Reference (`config/config.yaml`, `.env`, `services.yaml`, AlertEngine & notification channels)
  - Client Setup Guides (iOS / iPadOS / macOS / tvOS / Windows / Linux / Android)

## Where to Open Issues

| Problem Area | Repository |
|---|---|
| Backend API, Proxmox/SMART metrics, AlertEngine, Docker, `install.sh`, Web UI | [`Fairy-Jeux/pve-panel/issues`](https://github.com/Fairy-Jeux/pve-panel/issues) |
| iPhone, iPad, Mac (`MenuBarExtra`), or Apple TV (`tvOS`) app & pairing | [`Fairy-Jeux/pve-center-apple/issues`](https://github.com/Fairy-Jeux/pve-center-apple/issues) |
| Windows / Linux Tauri v2 desktop app or Android Capacitor 8 APK | [`Fairy-Jeux/pve-center-clients/issues`](https://github.com/Fairy-Jeux/pve-center-clients/issues) |
| Broken documentation, translation errors, or VitePress portal bugs | [`Fairy-Jeux/pve-center-website/issues`](https://github.com/Fairy-Jeux/pve-center-website/issues) |
| Organization branding, profile README, or community health templates | [`Fairy-Jeux/.github/issues`](https://github.com/Fairy-Jeux/.github/issues) |

## Before Asking for Help

1. Check that `DEV_AUTH_BYPASS` is not mistakenly depended on over LAN (`http://127.0.0.1` loopback only).
2. Confirm your Proxmox API token (`PanelRole`) and Tailscale Serve (`--bg http://127.0.0.1:8000`) status.
3. **Redact all sensitive data** before pasting logs or YAML configs: strip Proxmox API tokens, Bearer keys, `.p8` private keys, passwords, Tailscale emails, and private LAN IPs/hostnames.
