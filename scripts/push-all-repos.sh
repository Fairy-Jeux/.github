#!/usr/bin/env bash
# Bootstrap remotes, rewrite organization owner URLs, optionally create GitHub repos,
# and push all 5 PVE Command Center repositories to `main`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORG_REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_ROOT="$(cd "${ORG_REPO_DIR}/.." && pwd)"

PEER_DIRS=(
  "pve-panel"
  "pve-center-apple"
  "pve-center-clients"
  "pve-center-website"
  "pve-center-.github"
)

REMOTE_REPOS=(
  "pve-panel"
  "pve-center-apple"
  "pve-center-clients"
  "pve-center-website"
  ".github"
)

REPO_DESCRIPTIONS=(
  "Real-time Proxmox VE cockpit, SMART/MergerFS storage monitor, homelab hub, and multi-channel AlertEngine (FastAPI + React 19)"
  "Native Swift 6 & SwiftUI client for iOS, iPadOS, macOS, and Apple TV (tvOS) with Liquid Glass UI"
  "Cross-platform desktop (Windows & Linux via Tauri v2) and Android (Capacitor 8) clients for PVE Command Center"
  "Official VitePress landing page, platform download hub, and bilingual EN/FR documentation portal for PVE Command Center"
  "GitHub Organization profile, vector branding assets, and community health defaults for PVE Command Center"
)

DRY_RUN=0
USE_SSH=0
PRIVATE_REPO=0
GITHUB_OWNER=""

usage() {
  cat <<'EOF'
Usage: push-all-repos.sh [OPTIONS] <github_owner>

Synchronizes GitHub owner URLs, configures `origin` remotes across all 5 peer
PVE Command Center repositories, optionally creates missing repositories via
the GitHub REST API when GITHUB_TOKEN is exported, and pushes `main`.

Peer directories expected under the workspace parent:
  - pve-panel            -> <github_owner>/pve-panel
  - pve-center-apple     -> <github_owner>/pve-center-apple
  - pve-center-clients   -> <github_owner>/pve-center-clients
  - pve-center-website   -> <github_owner>/pve-center-website
  - pve-center-.github   -> <github_owner>/.github

Options:
  -n, --dry-run    Preview URL rewrites, remote changes, API checks, and pushes
                   without modifying any files, git state, or remote repos
      --ssh        Configure `git@github.com:<owner>/<repo>.git` instead of HTTPS
      --private    Create missing repos as private when using GITHUB_TOKEN
                   (Note: GitHub Organization profile READMEs require a public .github repo)
  -h, --help       Show this help message and exit

Environment:
  GITHUB_TOKEN     Optional GitHub Personal Access Token (repo / admin:org scope).
                   When set, missing repositories are created automatically via
                   the GitHub REST API before pushing.

Examples:
  ./scripts/push-all-repos.sh --dry-run Fairy-Jeux
  ./scripts/push-all-repos.sh --dry-run pve-center
  GITHUB_TOKEN=ghp_xxx ./scripts/push-all-repos.sh Fairy-Jeux
EOF
}

log_info() {
  printf '[info] %s\n' "$*"
}

log_warn() {
  printf '[warn] %s\n' "$*" >&2
}

log_err() {
  printf '[error] %s\n' "$*" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    --ssh)
      USE_SSH=1
      shift
      ;;
    --private)
      PRIVATE_REPO=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      log_err "Unknown option: $1"
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$GITHUB_OWNER" ]]; then
        log_err "Unexpected extra positional argument: $1"
        usage >&2
        exit 2
      fi
      GITHUB_OWNER="$1"
      shift
      ;;
  esac
done

if [[ -z "$GITHUB_OWNER" ]]; then
  log_err "Missing required <github_owner> argument."
  usage >&2
  exit 2
fi

if ! [[ "$GITHUB_OWNER" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,37}[A-Za-z0-9])?$ ]]; then
  log_err "Invalid GitHub owner '$GITHUB_OWNER'. Must match GitHub username/organization naming rules."
  exit 2
fi

if ! command -v git >/dev/null 2>&1; then
  log_err "git is required but was not found on PATH."
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  log_err "python3 is required for safe URL rewriting and JSON payloads."
  exit 1
fi

if [[ "$PRIVATE_REPO" -eq 1 ]]; then
  log_warn "--private was requested: GitHub only renders profile/README.md on the public Organization Overview when '.github' is public."
fi

log_info "Workspace root : $WORKSPACE_ROOT"
log_info "Org meta repo  : $ORG_REPO_DIR"
log_info "Target owner   : $GITHUB_OWNER"
if [[ "$DRY_RUN" -eq 1 ]]; then
  log_info "Mode           : DRY RUN (no files, git remotes, API state, or remotes will be modified)"
fi

# Step 1: Update github.com/<owner> URLs across profile/README.md, profile/README.fr.md, and README.md
update_owner_urls() {
  local target_owner="$1"
  local dry_run="$2"

  python3 - "$ORG_REPO_DIR" "$target_owner" "$dry_run" <<'PY'
import pathlib
import re
import subprocess
import sys

org_dir = pathlib.Path(sys.argv[1])
target_owner = sys.argv[2]
dry_run = sys.argv[3] == "1"

target_files = [
    org_dir / "profile" / "README.md",
    org_dir / "profile" / "README.fr.md",
    org_dir / "README.md",
]

# Detect current owner configured in origin remote or profile/README.md
prev_owner = None
try:
    origin_url = subprocess.check_output(
        ["git", "-C", str(org_dir), "remote", "get-url", "origin"],
        stderr=subprocess.DEVNULL,
        text=True,
    ).strip()
    m = re.search(r"github\.com[:/]([A-Za-z0-9-]+)/\.github(?:\.git)?$", origin_url)
    if m:
        prev_owner = m.group(1)
except Exception:
    pass

if not prev_owner and target_files[0].exists():
    txt = target_files[0].read_text(encoding="utf-8")
    m = re.search(r"https://github\.com/([A-Za-z0-9-]+)/pve-panel\b", txt)
    if m:
        prev_owner = m.group(1)

repo_pattern = re.compile(
    r"https://github\.com/([A-Za-z0-9-]+)(?=/(?:\.github|pve-panel|pve-center-apple|pve-center-clients|pve-center-website)(?:[/?#)\s\"']|$))"
)

changed_files = []
for path in target_files:
    if not path.exists():
        print(f"[warn] Missing expected file: {path}", file=sys.stderr)
        continue
    original = path.read_text(encoding="utf-8")
    updated = repo_pattern.sub(f"https://github.com/{target_owner}", original)

    if prev_owner and prev_owner != target_owner:
        # Update bare org profile links such as https://github.com/<prev_owner>
        org_url_pattern = re.compile(
            rf"https://github\.com/{re.escape(prev_owner)}(?=(?:[/?#)\s\"']|$))"
        )
        updated = org_url_pattern.sub(f"https://github.com/{target_owner}", updated)
        # Update display labels like [`Fairy-Jeux`] or [`Fairy-Jeux/pve-panel`]
        updated = re.sub(
            rf"\[`{re.escape(prev_owner)}(?=(?:/(?:\.github|pve-panel|pve-center-apple|pve-center-clients|pve-center-website))?`\])",
            f"[`{target_owner}",
            updated,
        )

    if updated != original:
        rel = path.relative_to(org_dir)
        changed_files.append(str(rel))
        if dry_run:
            print(f"[dry-run] Would update github.com owner URLs to '{target_owner}' in {rel}")
        else:
            path.write_text(updated, encoding="utf-8")
            print(f"[info] Updated github.com owner URLs to '{target_owner}' in {rel}")

if not changed_files:
    print(f"[info] Profile and README URLs already match '{target_owner}'.")
elif not dry_run:
    subprocess.run(["git", "-C", str(org_dir), "add", *changed_files], check=True)
    diff_check = subprocess.run(
        ["git", "-C", str(org_dir), "diff", "--cached", "--quiet"],
        check=False,
    )
    if diff_check.returncode != 0:
        subprocess.run(
            [
                "git",
                "-C",
                str(org_dir),
                "commit",
                "-m",
                f"chore: update GitHub owner URLs to {target_owner}",
            ],
            check=True,
        )
        print(f"[info] Committed URL updates in {org_dir.name}.")
else:
    print(f"[dry-run] Would commit updated URLs in {org_dir.name}: {', '.join(changed_files)}")
PY
}

# Step 2: Ensure GitHub repository exists via REST API if GITHUB_TOKEN is set
ensure_remote_repo_exists() {
  local owner="$1"
  local repo="$2"
  local description="$3"
  local is_private="false"
  if [[ "$PRIVATE_REPO" -eq 1 ]]; then
    is_private="true"
  fi

  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_info "[dry-run] GITHUB_TOKEN detected: would check/create https://github.com/${owner}/${repo} via GitHub REST API (private=${is_private})"
    return 0
  fi

  if ! command -v curl >/dev/null 2>&1; then
    log_err "curl is required when GITHUB_TOKEN is set."
    return 1
  fi

  local status_code
  status_code="$(curl -sS -o /dev/null -w '%{http_code}' \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${owner}/${repo}")"

  if [[ "$status_code" == "200" ]]; then
    log_info "GitHub repo ${owner}/${repo} already exists."
    return 0
  fi

  if [[ "$status_code" != "404" ]]; then
    log_warn "Unexpected HTTP ${status_code} checking https://api.github.com/repos/${owner}/${repo}; skipping auto-create."
    return 0
  fi

  local owner_json owner_type payload endpoint create_code
  owner_json="$(curl -sS \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/users/${owner}")"

  owner_type="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print(d.get("type",""))' <<<"$owner_json" 2>/dev/null || true)"

  payload="$(python3 - "$repo" "$description" "$is_private" <<'PY'
import json, sys
print(json.dumps({
    "name": sys.argv[1],
    "description": sys.argv[2],
    "private": sys.argv[3] == "true",
    "has_issues": True,
}))
PY
)"

  if [[ "$owner_type" == "Organization" ]]; then
    endpoint="https://api.github.com/orgs/${owner}/repos"
  else
    auth_login="$(curl -sS \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/user" \
      | python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("login",""))' 2>/dev/null || true)"
    if [[ -n "$auth_login" && "$(printf '%s' "$auth_login" | tr '[:upper:]' '[:lower:]')" != "$(printf '%s' "$owner" | tr '[:upper:]' '[:lower:]')" ]]; then
      log_err "Owner '${owner}' is a User account (not an Organization) and does not match authenticated GITHUB_TOKEN user '${auth_login}'."
      return 1
    fi
    endpoint="https://api.github.com/user/repos"
  fi

  local resp_file
  resp_file="$(mktemp)"
  create_code="$(curl -sS -o "$resp_file" -w '%{http_code}' \
    -X POST \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -d "$payload" \
    "$endpoint")"

  if [[ "$create_code" == "201" ]]; then
    log_info "Created GitHub repository ${owner}/${repo} (private=${is_private})."
    rm -f "$resp_file"
    return 0
  fi

  log_err "Failed to create ${owner}/${repo} via ${endpoint} (HTTP ${create_code}):"
  cat "$resp_file" >&2
  rm -f "$resp_file"
  return 1
}

remote_url_for() {
  local owner="$1"
  local repo="$2"
  if [[ "$USE_SSH" -eq 1 ]]; then
    printf 'git@github.com:%s/%s.git\n' "$owner" "$repo"
  else
    printf 'https://github.com/%s/%s.git\n' "$owner" "$repo"
  fi
}

update_owner_urls "$GITHUB_OWNER" "$DRY_RUN"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  log_info "GITHUB_TOKEN not set — skipping automatic GitHub repository creation (assuming repositories already exist)."
fi

count="${#PEER_DIRS[@]}"
for ((i = 0; i < count; i++)); do
  local_dir="${PEER_DIRS[$i]}"
  remote_repo="${REMOTE_REPOS[$i]}"
  repo_desc="${REPO_DESCRIPTIONS[$i]}"
  repo_path="${WORKSPACE_ROOT}/${local_dir}"
  target_url="$(remote_url_for "$GITHUB_OWNER" "$remote_repo")"

  printf '\n=== [%d/%d] %s -> %s/%s ===\n' "$((i + 1))" "$count" "$local_dir" "$GITHUB_OWNER" "$remote_repo"

  if [[ ! -d "$repo_path" ]]; then
    log_err "Missing repository directory: $repo_path"
    exit 1
  fi

  if ! git -C "$repo_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log_err "Directory is not a Git repository: $repo_path"
    exit 1
  fi

  if [[ -n "$(git -C "$repo_path" status --porcelain)" ]]; then
    log_warn "Working tree in ${local_dir} is not clean (uncommitted changes remain local; only committed 'main' history will be pushed)."
  fi

  if ! git -C "$repo_path" rev-parse --verify main >/dev/null 2>&1; then
    log_err "Branch 'main' does not exist in ${repo_path}."
    exit 1
  fi

  current_url="$(git -C "$repo_path" remote get-url origin 2>/dev/null || true)"
  if [[ "$current_url" != "$target_url" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      if [[ -z "$current_url" ]]; then
        log_info "[dry-run] Would add origin in ${local_dir}: ${target_url}"
      else
        log_info "[dry-run] Would update origin in ${local_dir}: ${current_url} -> ${target_url}"
      fi
    else
      if [[ -z "$current_url" ]]; then
        git -C "$repo_path" remote add origin "$target_url"
        log_info "Added origin in ${local_dir}: ${target_url}"
      else
        git -C "$repo_path" remote set-url origin "$target_url"
        log_info "Updated origin in ${local_dir}: ${current_url} -> ${target_url}"
      fi
    fi
  else
    log_info "Remote origin already set to ${target_url}"
  fi

  ensure_remote_repo_exists "$GITHUB_OWNER" "$remote_repo" "$repo_desc"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_info "[dry-run] Would run: git -C \"$repo_path\" push -u origin main"
  else
    git -C "$repo_path" push -u origin main
  fi
done

printf '\n'
if [[ "$DRY_RUN" -eq 1 ]]; then
  log_info "Dry run completed cleanly for all ${count} repositories (no modifications performed)."
else
  log_info "All ${count} repositories processed and pushed to 'main' under ${GITHUB_OWNER}."
fi
