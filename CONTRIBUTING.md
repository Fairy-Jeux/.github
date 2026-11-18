# Contributing to PVE Command Center

Thank you for helping improve the **PVE Command Center** ecosystem! These organization-wide guidelines apply across all repositories under [`Fairy-Jeux`](https://github.com/Fairy-Jeux), and individual repositories may include additional build or test commands.

## Choose the Right Repository

| Repository | Scope & Ownership |
|---|---|
| [`Fairy-Jeux/pve-panel`](https://github.com/Fairy-Jeux/pve-panel) | FastAPI backend, SQLite WAL `AlertEngine`, DualAuth middleware, embedded React 19 Web UI, Dockerfile, `install.sh` |
| [`Fairy-Jeux/pve-center-apple`](https://github.com/Fairy-Jeux/pve-center-apple) | Native Swift 6 / SwiftUI clients for iOS, iPadOS, macOS, and tvOS |
| [`Fairy-Jeux/pve-center-clients`](https://github.com/Fairy-Jeux/pve-center-clients) | Cross-platform desktop (Windows / Linux via Tauri v2) and Android (Capacitor 8) clients |
| [`Fairy-Jeux/pve-center-website`](https://github.com/Fairy-Jeux/pve-center-website) | Official VitePress landing page, download hub, and EN / FR documentation portal |
| [`Fairy-Jeux/.github`](https://github.com/Fairy-Jeux/.github) | Organization overview profile (`profile/`), SVG vector branding (`branding/SVG/`), and default health files |

## Pull Request Guidelines

1. **Fork & Branch**: Create a focused topic branch from `main` (e.g., `feat/multi-node-selector`, `fix/mdns-timeout`, `docs/fr-update`).
2. **Conventional Commits**: Prefix commit messages clearly (`feat:`, `fix:`, `docs:`, `ci:`, `refactor:`, `chore:`).
3. **Bilingual Documentation**: Update both English (`README.md` / `docs/en/`) and French (`README.fr.md` / `docs/fr/`) documentation when introducing new configuration options, API routes, or CLI behavior.
4. **Sanitize Secrets**: Never commit real `.env` files, `config/config.yaml`, `services.yaml`, `*.db`, APNs `.p8` keys, Bearer tokens, or private Tailscale hostnames/emails.
5. **Verify Before Opening a PR**:
   - **`pve-panel`**: `ruff check backend`, `pytest -v`, `cd frontend && npx tsc --noEmit && npm run build`, `bash -n install.sh`
   - **`pve-center-apple`**: `swift build`, `xcodebuild` (macOS / iOS / tvOS targets), `bash -n scripts/*.sh`
   - **`pve-center-clients`**: `npm run build`, `npx cap sync android`, `cargo check` (inside `src-tauri/`), `bash -n scripts/*.sh`
   - **`pve-center-website`**: `npm run docs:build`
   - **`.github`**: Validate SVG XML (`branding/SVG/*.svg`), parse `.github/**/*.yml` with `yaml.safe_load`, check `bash -n scripts/push-all-repos.sh`, and verify Markdown relative links.

## Community Standards

All contributors and maintainers are expected to follow our [Code of Conduct](CODE_OF_CONDUCT.md).
