  # shellcheck disable=SC2089

function require_command() {
  local command="$1"
  local package="${2:-}"

  local not_found_msg="Command '$command' not found."
  [[ -n $package ]] && not_found_msg="  Install the '$package' package with brew|apt|dnf|scoop"

  command -v "$command" >/dev/null 2>&1 || die "$not_found_msg"
}
