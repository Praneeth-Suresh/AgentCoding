#!/usr/bin/env bash
set -euo pipefail

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  scripts/setup-project.sh [TARGET_DIR]

Interactively copies the agent control plane into TARGET_DIR, configures the
affected-test gate, optionally enables the Git hook, and can hand off unusual
setup work to a headless coding agent.

If TARGET_DIR is omitted, the script prompts for it.
USAGE
}

fail() {
  printf "ERROR: %s\n" "$*" >&2
  exit 1
}

prompt() {
  local label="$1"
  local default="${2:-}"
  local value

  if [[ -n "${default}" ]]; then
    printf "%s [%s]: " "${label}" "${default}" >&2
    read -r value || fail "input ended while reading: ${label}"
    printf "%s" "${value:-${default}}"
  else
    printf "%s: " "${label}" >&2
    read -r value || fail "input ended while reading: ${label}"
    printf "%s" "${value}"
  fi
}

confirm() {
  local label="$1"
  local default="${2:-y}"
  local value suffix

  case "${default}" in
    y|Y) suffix="Y/n" ;;
    n|N) suffix="y/N" ;;
    *) fail "confirm default must be y or n" ;;
  esac

  while true; do
    printf "%s [%s]: " "${label}" "${suffix}" >&2
    read -r value || fail "input ended while reading: ${label}"
    value="${value:-${default}}"
    case "${value}" in
      y|Y|yes|YES) return 0 ;;
      n|N|no|NO) return 1 ;;
      *) printf "Please answer y or n.\n" >&2 ;;
    esac
  done
}

choose() {
  local label="$1"
  shift
  local options=("$@")
  local choice

  printf "\n%s\n" "${label}" >&2
  local i
  for i in "${!options[@]}"; do
    printf "  %s) %s\n" "$((i + 1))" "${options[$i]}" >&2
  done

  while true; do
    printf "Choose 1-%s: " "${#options[@]}" >&2
    read -r choice || fail "input ended while choosing: ${label}"
    if [[ "${choice}" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#options[@]})); then
      printf "%s" "${options[$((choice - 1))]}"
      return 0
    fi
    printf "Please choose a listed option.\n" >&2
  done
}

ensure_target_dir() {
  local target="$1"

  [[ -n "${target}" ]] || fail "target directory is required"

  if [[ -e "${target}" && ! -d "${target}" ]]; then
    fail "target exists but is not a directory: ${target}"
  fi

  if [[ ! -d "${target}" ]]; then
    if confirm "Create target directory ${target}?" "y"; then
      mkdir -p "${target}"
    else
      fail "target directory does not exist: ${target}"
    fi
  fi
}

copy_path() {
  local rel="$1"
  local src="${SOURCE_ROOT}/${rel}"
  local dst="${TARGET_DIR}/${rel}"

  [[ -e "${src}" ]] || return 0
  [[ "${TARGET_DIR}" != "${SOURCE_ROOT}" ]] || {
    printf "setup-project: target is this repository; kept existing %s\n" "${rel}"
    return 0
  }

  if [[ -e "${dst}" ]]; then
    if ! confirm "Replace existing ${rel} in target?" "n"; then
      printf "setup-project: kept existing %s\n" "${rel}"
      return 0
    fi
  fi

  rm -rf "${dst}"
  mkdir -p "$(dirname "${dst}")"
  cp -R "${src}" "${dst}"
  printf "setup-project: copied %s\n" "${rel}"
}

ensure_gitignore_entry() {
  local gitignore="${TARGET_DIR}/.gitignore"

  touch "${gitignore}"
  if ! grep -qxF "agent/session-state.md" "${gitignore}"; then
    printf "\nagent/session-state.md\n" >>"${gitignore}"
    printf "setup-project: updated .gitignore\n"
  fi
}

ensure_git_repo() {
  command -v git >/dev/null 2>&1 || {
    printf "setup-project: git not found on PATH; skipped Git repository setup\n"
    return 0
  }

  if git -C "${TARGET_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi

  if confirm "Target is not a Git repository. Initialize Git there?" "y"; then
    git -C "${TARGET_DIR}" init
    printf "setup-project: initialized Git repository\n"
  fi
}

configure_affected_tests() {
  local stack="$1"
  local runner="$2"
  local config="${TARGET_DIR}/agent/affected-tests.conf"
  local related_cmd="()"
  local full_cmd="()"

  [[ -f "${config}" ]] || return 0

  case "${runner}" in
    "Jest")
      related_cmd="(bash -lc 'if [[ -f package.json ]]; then npx --no-install jest --findRelatedTests --passWithNoTests \"\$@\"; else echo \"check-affected: package.json missing; skipping Jest\"; fi' bash)"
      full_cmd="(bash -lc 'if [[ -f package.json ]]; then npm test; else echo \"check-affected: package.json missing; skipping npm test\"; fi')"
      ;;
    "Vitest")
      related_cmd="(bash -lc 'if [[ -f package.json ]]; then npx --no-install vitest related --run \"\$@\"; else echo \"check-affected: package.json missing; skipping Vitest\"; fi' bash)"
      full_cmd="(bash -lc 'if [[ -f package.json ]]; then npm test; else echo \"check-affected: package.json missing; skipping npm test\"; fi')"
      ;;
    "pytest + testmon")
      related_cmd="(bash -lc 'if command -v pytest >/dev/null 2>&1; then pytest --testmon; else echo \"check-affected: pytest missing; skipping pytest-testmon\"; fi')"
      full_cmd="(bash -lc 'if command -v pytest >/dev/null 2>&1; then pytest; else echo \"check-affected: pytest missing; skipping pytest\"; fi')"
      ;;
    "go test")
      related_cmd="()"
      full_cmd="(bash -lc 'if [[ -f go.mod ]]; then go test ./...; else echo \"check-affected: go.mod missing; skipping go test\"; fi')"
      ;;
    "Custom command")
      printf "\nEnter Bash array syntax for custom commands.\n"
      printf "Example: (npm test -- --changed)\n"
      related_cmd="$(prompt "RELATED_TEST_CMD" "()")"
      full_cmd="$(prompt "FULL_TEST_CMD" "()")"
      ;;
    *)
      case "${stack}" in
        "Generic shell/custom")
          related_cmd="()"
          full_cmd="$(prompt "FULL_TEST_CMD" "()")"
          ;;
      esac
      ;;
  esac

  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN
  awk -v related="${related_cmd}" -v full="${full_cmd}" '
    /^FULL_TEST_CMD=/ {
      print "FULL_TEST_CMD=" full
      next
    }
    /^RELATED_TEST_CMD=/ {
      print "RELATED_TEST_CMD=" related
      next
    }
    { print }
  ' "${config}" >"${tmp}"
  mv "${tmp}" "${config}"
  printf "setup-project: configured affected tests for %s / %s\n" "${stack}" "${runner}"
}

run_if_present() {
  local description="$1"
  shift

  if [[ -x "$1" ]]; then
    printf "setup-project: %s\n" "${description}"
    (cd "${TARGET_DIR}" && "$@")
  else
    printf "setup-project: skipped %s; missing %s\n" "${description}" "$1"
  fi
}

read_multiline_prompt() {
  local prompt_file="$1"

  printf "\nDescribe the project setup you want the coding agent to complete.\n"
  printf "Finish with a line containing only EOF.\n\n"
  : >"${prompt_file}"

  local line
  while IFS= read -r line; do
    [[ "${line}" == "EOF" ]] && break
    printf "%s\n" "${line}" >>"${prompt_file}"
  done
}

run_agent_fallback() {
  local reason="$1"
  local agent_choice command_template prompt_file prompt_text

  printf "\nAI fallback selected: %s\n" "${reason}"
  agent_choice="$(choose "Choose a headless coding agent" \
    "Codex" \
    "Claude" \
    "Custom headless command" \
    "Skip AI fallback")"

  [[ "${agent_choice}" != "Skip AI fallback" ]] || return 0

  prompt_file="$(mktemp)"
  trap 'rm -f "${prompt_file}"' RETURN
  read_multiline_prompt "${prompt_file}"
  prompt_text="$(cat "${prompt_file}")"

  case "${agent_choice}" in
    "Codex")
      if command -v codex >/dev/null 2>&1; then
        if ! (cd "${TARGET_DIR}" && codex exec "${prompt_text}"); then
          printf "setup-project: codex command failed. Try manually:\n"
          printf "  cd %q && codex exec %q\n" "${TARGET_DIR}" "${prompt_text}"
        fi
      else
        printf "setup-project: codex not found on PATH.\n"
        printf "Manual command:\n  cd %q && codex exec %q\n" "${TARGET_DIR}" "${prompt_text}"
      fi
      ;;
    "Claude")
      if command -v claude >/dev/null 2>&1; then
        if ! (cd "${TARGET_DIR}" && claude -p "${prompt_text}"); then
          printf "setup-project: claude command failed. Try manually:\n"
          printf "  cd %q && claude -p %q\n" "${TARGET_DIR}" "${prompt_text}"
        fi
      else
        printf "setup-project: claude not found on PATH.\n"
        printf "Manual command:\n  cd %q && claude -p %q\n" "${TARGET_DIR}" "${prompt_text}"
      fi
      ;;
    "Custom headless command")
      printf "Use placeholders {target_dir}, {prompt_file}, and {prompt_text}.\n"
      command_template="$(prompt "Command template")"
      [[ -n "${command_template}" ]] || fail "custom command template cannot be empty"
      command_template="${command_template//\{target_dir\}/${TARGET_DIR}}"
      command_template="${command_template//\{prompt_file\}/${prompt_file}}"
      command_template="${command_template//\{prompt_text\}/${prompt_text}}"
      bash -lc "${command_template}"
      ;;
  esac
}

install_control_plane() {
  copy_path "agent"
  copy_path "scripts"
  copy_path "githooks"
  copy_path ".github"
  ensure_gitignore_entry

  chmod +x "${TARGET_DIR}"/scripts/*.sh 2>/dev/null || true
  chmod +x "${TARGET_DIR}"/agent/scripts/*.sh 2>/dev/null || true
  chmod +x "${TARGET_DIR}"/githooks/pre-commit 2>/dev/null || true
}

run_setup_checks() {
  run_if_present "syncing generated agent shims" "${TARGET_DIR}/agent/scripts/sync-agent-env.sh"
  run_if_present "creating test manifest" "${TARGET_DIR}/scripts/update-test-manifest.sh"
}

enable_git_hook() {
  if [[ ! -d "${TARGET_DIR}/.git" ]]; then
    printf "setup-project: target is not a Git repository; skipped hook setup\n"
    return 0
  fi

  if confirm "Enable pre-commit hook with git config core.hooksPath githooks?" "y"; then
    git -C "${TARGET_DIR}" config core.hooksPath githooks
    printf "setup-project: enabled githooks/pre-commit\n"
  fi
}

main() {
  local arg="${1:-}"
  local stack runner target_input

  case "${arg}" in
    -h|--help)
      usage
      exit 0
      ;;
  esac

  TARGET_DIR="${arg}"
  if [[ -z "${TARGET_DIR}" ]]; then
    target_input="$(prompt "Target project directory")"
    TARGET_DIR="${target_input}"
  fi

  case "${TARGET_DIR}" in
    /*) ;;
    *) TARGET_DIR="${PWD}/${TARGET_DIR}" ;;
  esac
  TARGET_DIR="${TARGET_DIR%/}"
  ensure_target_dir "${TARGET_DIR}"

  printf "setup-project: target %s\n" "${TARGET_DIR}"
  install_control_plane
  ensure_git_repo

  stack="$(choose "Choose the closest project stack" \
    "JavaScript/TypeScript" \
    "Python" \
    "Go" \
    "Generic shell/custom" \
    "Use AI agent fallback")"

  if [[ "${stack}" == "Use AI agent fallback" ]]; then
    run_agent_fallback "stack options were insufficient"
  else
    case "${stack}" in
      "JavaScript/TypeScript")
        runner="$(choose "Choose the test runner" \
          "Jest" \
          "Vitest" \
          "Custom command" \
          "Use AI agent fallback")"
        ;;
      "Python")
        runner="$(choose "Choose the test runner" \
          "pytest + testmon" \
          "Custom command" \
          "Use AI agent fallback")"
        ;;
      "Go")
        runner="$(choose "Choose the test runner" \
          "go test" \
          "Custom command" \
          "Use AI agent fallback")"
        ;;
      *)
        runner="$(choose "Choose the test runner" \
          "Custom command" \
          "Use AI agent fallback")"
        ;;
    esac

    if [[ "${runner}" == "Use AI agent fallback" ]]; then
      run_agent_fallback "test runner options were insufficient"
    else
      configure_affected_tests "${stack}" "${runner}"
    fi
  fi

  run_setup_checks
  enable_git_hook

  if confirm "Run ./scripts/check.sh in the target now?" "y"; then
    run_if_present "running deterministic checks" "${TARGET_DIR}/scripts/check.sh"
  fi

  if confirm "Use AI agent fallback for any remaining setup details?" "n"; then
    run_agent_fallback "user requested additional setup"
  fi

  printf "\nSetup complete for %s\n" "${TARGET_DIR}"
  printf "Next normal command: cd %q && ./scripts/check.sh\n" "${TARGET_DIR}"
}

main "$@"
