#!/usr/bin/env bash
set -euo pipefail

# Update an existing project without replacing its documents.
# Usage: ./update.sh [github|gitlab|gitea|none] [--yes] [--ref BRANCH_OR_TAG]

usage() {
  cat <<'EOF'
Usage: ./update.sh [github|gitlab|gitea|none] [--yes] [--ref BRANCH_OR_TAG]

Downloads the latest template (main by default) and updates the extension,
flake.nix, flake.lock, template/, setup.sh, update.sh, and the chosen workflow.
Run from your cheatsheet project directory. Documents are left unchanged.

An existing CI platform is detected automatically if exactly one is installed.
Otherwise the platform is selected interactively. Use 'none' to skip CI updates.
Existing files are backed up under .cheatsheet-backups/ before replacement.
Existing .envrc and .gitignore entries are preserved.

  --yes       Skip confirmation (requires an explicit or detected platform)
  --ref REF   Use an upstream branch or tag instead of main
  -h, --help  Show this help

Set CHEATSHEET_REPOSITORY to use a different template Git repository.
EOF
}

install_path() {
  local relative="$1" source="$2"
  local target="$project_dir/$relative"
  if [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "$(dirname "$backup_dir/$relative")"
    mv -- "$target" "$backup_dir/$relative"
  fi
  mkdir -p "$(dirname "$target")"
  cp -a -- "$source" "$target"
  echo "Updated $relative"
}

main() {
  platform=""
  ref="main"
  assume_yes=false
  while [ "$#" -gt 0 ]; do
    case "$1" in
      github | gitlab | gitea | none)
        if [ -n "$platform" ]; then
          echo "Specify only one CI platform" >&2
          exit 1
        fi
        platform="$1"
        ;;
      --yes) assume_yes=true ;;
      --ref)
        if [ "$#" -lt 2 ] || [ -z "$2" ]; then
          echo "--ref requires a branch or tag" >&2
          exit 1
        fi
        ref="$2"
        shift
        ;;
      -h | --help) usage; exit 0 ;;
      *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
    esac
    shift
  done

  project_dir="$PWD"
  if [ ! -d _extensions/cheatsheet ] && [ ! -f index.qmd ] && [ ! -f _quarto.yml ]; then
    echo "Run this script from an existing cheatsheet project directory" >&2
    exit 1
  fi

  if [ -z "$platform" ]; then
    detected=()
    [ ! -f .github/workflows/render.yml ] || detected+=(github)
    [ ! -f .gitlab-ci.yml ] || detected+=(gitlab)
    [ ! -f .gitea/workflows/render.yml ] || detected+=(gitea)
    if [ "${#detected[@]}" -eq 1 ]; then
      platform="${detected[0]}"
      echo "Detected CI platform: $platform"
    elif "$assume_yes"; then
      echo "Specify github, gitlab, gitea, or none; CI platform is ambiguous" >&2
      exit 1
    else
      echo "Choose a CI platform to update:"
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
  fi

  case "$platform" in
    github) workflow=".github/workflows/render.yml" ;;
    gitlab) workflow=".gitlab-ci.yml" ;;
    gitea) workflow=".gitea/workflows/render.yml" ;;
    none) workflow="" ;;
  esac

  repository="${CHEATSHEET_REPOSITORY:-https://github.com/z10n-dev/quarto-cheatsheet.git}"
  echo "Update template files from $repository (ref: $ref)."
  echo "This replaces the extension, flake, template/, setup.sh, and update.sh."
  [ -z "$workflow" ] || echo "Workflow to replace: $workflow"
  echo "Existing versions will be backed up; QMD documents are not changed."
  if ! "$assume_yes"; then
    read -r -p "Continue? [y/N]: " answer
    case "$answer" in
      y | Y | yes | YES) ;;
      *) echo "Update cancelled"; exit 0 ;;
    esac
  fi

  command -v git >/dev/null 2>&1 || { echo "git is required" >&2; exit 1; }
  work_dir=$(mktemp -d "${TMPDIR:-/tmp}/quarto-cheatsheet-update.XXXXXX")
  trap 'rm -rf -- "$work_dir"' EXIT
  snapshot="$work_dir/template"
  git clone --quiet --depth 1 --branch "$ref" -- "$repository" "$snapshot"

  # Validate the complete snapshot before changing any project files.
  paths=(_extensions/cheatsheet template flake.nix flake.lock setup.sh update.sh)
  for relative in "${paths[@]}" template/gitignore template/envrc _extensions/cheatsheet/_extension.yml; do
    if [ ! -e "$snapshot/$relative" ]; then
      echo "Template is missing $relative; project left unchanged" >&2
      exit 1
    fi
  done
  if [ -n "$workflow" ] && [ ! -f "$snapshot/template/workflows/$platform.yml" ]; then
    echo "Template is missing the $platform workflow; project left unchanged" >&2
    exit 1
  fi

  mkdir -p "$project_dir/.cheatsheet-backups"
  backup_dir=$(mktemp -d "$project_dir/.cheatsheet-backups/$(date +%Y%m%d-%H%M%S).XXXXXX")
  for relative in "${paths[@]}"; do
    install_path "$relative" "$snapshot/$relative"
  done
  if [ -n "$workflow" ]; then
    install_path "$workflow" "$snapshot/template/workflows/$platform.yml"
  fi

  if [ ! -f .envrc ]; then
    install_path .envrc "$snapshot/template/envrc"
  fi
  if [ ! -f .gitignore ]; then
    install_path .gitignore "$snapshot/template/gitignore"
  fi
  if ! grep -qxF '/.cheatsheet-backups/' .gitignore; then
    # Only append the backup ignore entry; keep all custom ignore rules.
    if [ ! -e "$backup_dir/.gitignore" ]; then
      cp -p .gitignore "$backup_dir/.gitignore"
    fi
    printf '\n/.cheatsheet-backups/\n' >> .gitignore
  fi
  chmod +x setup.sh update.sh

  echo "Update complete. Backups: $backup_dir"
  echo "Review the changes, reload direnv (or enter nix develop), then run quarto render."
}

# Parse this whole block before main replaces update.sh itself.
{
  main "$@"
  exit 0
}
