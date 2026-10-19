#!/usr/bin/env bash
set -euo pipefail

# Set up a freshly created cheatsheet project: dotfiles and a CI workflow.
# Usage: ./setup.sh [github|gitlab|gitea|none]

src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template_dir="$src_dir/template"

usage() {
  cat <<'EOF'
Usage: ./setup.sh [github|gitlab|gitea|none]

Creates .gitignore and .envrc and installs a CI workflow for the chosen
platform (default: prompt):

  github   .github/workflows/render.yml
  gitlab   .gitlab-ci.yml
  gitea    .gitea/workflows/render.yml
  none     no workflow
EOF
}

platform="${1:-}"

if [ "$platform" = "-h" ] || [ "$platform" = "--help" ]; then
  usage
  exit 0
fi

if [ -z "$platform" ]; then
  echo "Choose a CI platform:"
  echo "  1) GitHub Actions"
  echo "  2) GitLab CI"
  echo "  3) Gitea Actions"
  echo "  4) none"
  read -r -p "Choice [1-4]: " choice
  case "$choice" in
    1) platform="github" ;;
    2) platform="gitlab" ;;
    3) platform="gitea" ;;
    4) platform="none" ;;
    *) echo "Invalid choice: $choice" >&2; exit 1 ;;
  esac
fi

case "$platform" in
  github | gitlab | gitea | none) ;;
  *) echo "Unknown platform: $platform" >&2; usage >&2; exit 1 ;;
esac

if [ ! -f .gitignore ]; then
  cp "$template_dir/gitignore" .gitignore
  echo "Created .gitignore"
else
  echo "Kept existing .gitignore"
fi

if [ ! -f .envrc ]; then
  cp "$template_dir/envrc" .envrc
  echo "Created .envrc"
else
  echo "Kept existing .envrc"
fi

case "$platform" in
  github)
    mkdir -p .github/workflows
    cp "$template_dir/workflows/github.yml" .github/workflows/render.yml
    echo "Installed GitHub Actions workflow: .github/workflows/render.yml"
    ;;
  gitlab)
    cp "$template_dir/workflows/gitlab.yml" .gitlab-ci.yml
    echo "Installed GitLab CI pipeline: .gitlab-ci.yml"
    ;;
  gitea)
    mkdir -p .gitea/workflows
    cp "$template_dir/workflows/gitea.yml" .gitea/workflows/render.yml
    echo "Installed Gitea Actions workflow: .gitea/workflows/render.yml"
    ;;
  none)
    echo "Skipped CI workflow"
    ;;
esac

if command -v direnv >/dev/null 2>&1; then
  direnv allow
  echo "Allowed direnv"
else
  echo "direnv not found; run 'direnv allow' manually after installing it"
fi
