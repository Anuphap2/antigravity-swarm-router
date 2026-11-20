#!/usr/bin/env bash
set -euo pipefail

REPO_ARCHIVE_URL="https://github.com/Anuphap2/antigravity-swarm-router/archive/refs/heads/main.tar.gz"
TARGET_DIR="."
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--force)
      FORCE=1
      shift
      ;;
    -h|--help)
      echo "Usage: install.sh [TARGET_DIR] [--force]"
      exit 0
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

TMP_DIR=""
cleanup() {
  if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/AGENTS.md" && -d "$SCRIPT_DIR/.agent/skills" ]]; then
  SOURCE_DIR="$SCRIPT_DIR"
else
  TMP_DIR="$(mktemp -d)"
  echo "[INFO] Fetching antigravity-swarm-router..."
  curl -fsSL "$REPO_ARCHIVE_URL" | tar -xz -C "$TMP_DIR"
  SOURCE_DIR="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  if [[ -z "$SOURCE_DIR" || ! -f "$SOURCE_DIR/AGENTS.md" ]]; then
    echo "[ERROR] Failed to locate AGENTS.md in downloaded archive." >&2
    exit 1
  fi
fi

# Copy AGENTS.md with overwrite prompt if it already exists
if [[ -f "$TARGET_DIR/AGENTS.md" && "$FORCE" -ne 1 ]]; then
  REPLY="n"
  if [[ -r /dev/tty ]]; then
    read -r -p "[WARN] $TARGET_DIR/AGENTS.md already exists. Overwrite? [y/N] " REPLY < /dev/tty || REPLY="n"
  elif [[ -t 0 ]]; then
    read -r -p "[WARN] $TARGET_DIR/AGENTS.md already exists. Overwrite? [y/N] " REPLY || REPLY="n"
  else
    echo "[SKIP] $TARGET_DIR/AGENTS.md exists (non-interactive; pass --force to overwrite)."
  fi

  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    cp "$SOURCE_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
    echo "[OK] Overwrote $TARGET_DIR/AGENTS.md"
  else
    echo "[SKIP] Kept existing $TARGET_DIR/AGENTS.md"
  fi
else
  cp "$SOURCE_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
  echo "[OK] Installed $TARGET_DIR/AGENTS.md"
fi

# Copy only router skills into .agent/skills/ without touching unrelated files
mkdir -p "$TARGET_DIR/.agent/skills"
for skill in board-updater system-architect deep-coder; do
  if [[ -d "$SOURCE_DIR/.agent/skills/$skill" ]]; then
    mkdir -p "$TARGET_DIR/.agent/skills/$skill"
    cp -R "$SOURCE_DIR/.agent/skills/$skill/." "$TARGET_DIR/.agent/skills/$skill/"
    echo "[OK] Installed $TARGET_DIR/.agent/skills/$skill"
  fi
done

echo "[DONE] antigravity-swarm-router installed into $TARGET_DIR"
