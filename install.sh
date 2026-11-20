#!/usr/bin/env bash
set -euo pipefail

REPO_ARCHIVE_URL="https://github.com/Anuphap2/antigravity-swarm-router/archive/refs/heads/main.tar.gz"
TARGET_DIR="."
PRESET="quota-saver"
PRESET_SET=0
MODE="install" # install | update | uninstall
FORCE=0
ROUTER_SKILLS=(board-updater test-runner system-architect deep-coder)

usage() {
  cat <<'EOF'
Usage: install.sh [TARGET_DIR] [OPTIONS]

Options:
  --preset <name>   Tier 1 model preset: quota-saver (default), balanced, speed-first
  --update          Update only router SKILL.md files (preserves AGENTS.md)
  --uninstall       Remove router skills (and prompt before removing AGENTS.md)
  -f, --force       Overwrite or remove AGENTS.md without prompting
  -h, --help        Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --preset)
      [[ $# -ge 2 ]] || { echo "[ERROR] --preset requires a value." >&2; exit 1; }
      PRESET="$2"
      PRESET_SET=1
      shift 2
      ;;
    --preset=*)
      PRESET="${1#*=}"
      PRESET_SET=1
      shift
      ;;
    --update)
      MODE="update"
      shift
      ;;
    --uninstall)
      MODE="uninstall"
      shift
      ;;
    -f|--force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "[ERROR] Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

case "$PRESET" in
  quota-saver) TIER_LOW_MODEL="gemini-4-argon-low" ;;
  balanced)    TIER_LOW_MODEL="claude-sonnet-5-5-low" ;;
  speed-first) TIER_LOW_MODEL="gemini-3.8-flash-low" ;;
  *)
    echo "[ERROR] Invalid preset '$PRESET'. Use: quota-saver | balanced | speed-first" >&2
    exit 1
    ;;
esac

confirm_prompt() {
  local prompt_msg="$1"
  local reply="n"
  if { exec 3< /dev/tty; } 2>/dev/null; then
    read -r -u 3 -p "$prompt_msg " reply || reply="n"
    exec 3<&-
  elif [[ -t 0 ]]; then
    read -r -p "$prompt_msg " reply || reply="n"
  else
    return 2
  fi
  [[ "$reply" =~ ^[Yy]$ ]]
}

replace_in_file() {
  local file="$1"
  local old="$2"
  local new="$3"
  [[ -f "$file" ]] || return 0
  sed "s|$old|$new|g" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

if [[ "$MODE" == "uninstall" ]]; then
  if [[ ! -d "$TARGET_DIR" ]]; then
    echo "[ERROR] Target directory does not exist: $TARGET_DIR" >&2
    exit 1
  fi
  TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

  for skill in "${ROUTER_SKILLS[@]}"; do
    skill_dir="$TARGET_DIR/.agent/skills/$skill"
    if [[ -d "$skill_dir" ]]; then
      rm -rf "$skill_dir"
      echo "[OK] Removed $skill_dir"
    fi
  done
  rmdir "$TARGET_DIR/.agent/skills" 2>/dev/null || true
  rmdir "$TARGET_DIR/.agent" 2>/dev/null || true

  if [[ -f "$TARGET_DIR/AGENTS.md" ]]; then
    if [[ "$FORCE" -eq 1 ]]; then
      rm -f "$TARGET_DIR/AGENTS.md"
      echo "[OK] Removed $TARGET_DIR/AGENTS.md"
    else
      rc=0
      confirm_prompt "[WARN] Remove $TARGET_DIR/AGENTS.md? [y/N]" || rc=$?
      if [[ "$rc" -eq 0 ]]; then
        rm -f "$TARGET_DIR/AGENTS.md"
        echo "[OK] Removed $TARGET_DIR/AGENTS.md"
      elif [[ "$rc" -eq 2 ]]; then
        echo "[SKIP] Kept $TARGET_DIR/AGENTS.md (non-interactive; pass --force to remove)."
      else
        echo "[SKIP] Kept $TARGET_DIR/AGENTS.md"
      fi
    fi
  fi
  echo "[DONE] Uninstalled antigravity-swarm-router from $TARGET_DIR"
  exit 0
fi

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

INSTALLED_AGENTS=0
if [[ "$MODE" == "update" ]]; then
  echo "[INFO] Update mode: preserving existing AGENTS.md"
elif [[ -f "$TARGET_DIR/AGENTS.md" && "$FORCE" -ne 1 ]]; then
  rc=0
  confirm_prompt "[WARN] $TARGET_DIR/AGENTS.md already exists. Overwrite? [y/N]" || rc=$?
  if [[ "$rc" -eq 0 ]]; then
    cp "$SOURCE_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
    INSTALLED_AGENTS=1
    echo "[OK] Overwrote $TARGET_DIR/AGENTS.md"
  elif [[ "$rc" -eq 2 ]]; then
    echo "[SKIP] $TARGET_DIR/AGENTS.md exists (non-interactive; pass --force to overwrite)."
    echo "[SKIP] Kept existing $TARGET_DIR/AGENTS.md"
  else
    echo "[SKIP] Kept existing $TARGET_DIR/AGENTS.md"
  fi
else
  cp "$SOURCE_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
  INSTALLED_AGENTS=1
  echo "[OK] Installed $TARGET_DIR/AGENTS.md"
fi

if [[ "$INSTALLED_AGENTS" -eq 1 && "$TIER_LOW_MODEL" != "gemini-4-argon-low" ]]; then
  replace_in_file "$TARGET_DIR/AGENTS.md" "gemini-4-argon-low" "$TIER_LOW_MODEL"
  echo "[OK] Applied preset '$PRESET' ($TIER_LOW_MODEL) to AGENTS.md"
fi

mkdir -p "$TARGET_DIR/.agent/skills"
for skill in "${ROUTER_SKILLS[@]}"; do
  if [[ -d "$SOURCE_DIR/.agent/skills/$skill" ]]; then
    mkdir -p "$TARGET_DIR/.agent/skills/$skill"
    cp -R "$SOURCE_DIR/.agent/skills/$skill/." "$TARGET_DIR/.agent/skills/$skill/"
    if [[ "$TIER_LOW_MODEL" != "gemini-4-argon-low" && ( "$skill" == "board-updater" || "$skill" == "test-runner" ) ]]; then
      if [[ "$MODE" == "install" || "$PRESET_SET" -eq 1 ]]; then
        replace_in_file "$TARGET_DIR/.agent/skills/$skill/SKILL.md" "gemini-4-argon-low" "$TIER_LOW_MODEL"
      fi
    fi
    echo "[OK] Installed $TARGET_DIR/.agent/skills/$skill"
  fi
done

echo "[DONE] antigravity-swarm-router ($MODE, preset=$PRESET) applied to $TARGET_DIR"
