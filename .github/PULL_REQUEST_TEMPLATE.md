## Summary

<!-- Describe what this PR changes across the .github organization repository and why. -->

## Type of Change

- [ ] Organization profile update (`profile/README.md` / `profile/README.fr.md`)
- [ ] Vector branding update (`branding/SVG/*.svg`)
- [ ] Community health files or issue/PR templates
- [ ] Multi-repo automation (`scripts/push-all-repos.sh`)
- [ ] Documentation / maintenance (`docs:` / `chore:`)

## Related Issues

<!-- Link related issues, e.g., Closes #12 -->

## Verification Performed

- [ ] All `branding/SVG/*.svg` files parse cleanly as XML and contain no `<script>`, `<foreignObject>`, or external `<image>` tags
- [ ] Both dark and light SVG banners (`banner-logo-solid.svg` and `banner-logo-light.svg`) were checked visually or structurally
- [ ] All `.github/**/*.yml` files parse cleanly via `yaml.safe_load`
- [ ] Relative Markdown links in `profile/README.md`, `profile/README.fr.md`, and `README.md` resolve on disk
- [ ] `bash -n scripts/push-all-repos.sh` passes and `--dry-run` behaves safely

## Security & Hygiene Checklist

- [ ] No `GITHUB_TOKEN`, `.env`, private keys, or personal hostnames/emails are included
- [ ] Both English (`profile/README.md`) and French (`profile/README.fr.md`) profiles remain in sync
