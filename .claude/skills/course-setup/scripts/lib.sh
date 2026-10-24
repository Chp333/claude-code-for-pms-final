# Shared helpers for the course-setup scripts. Sourced, never run directly.
# Must work in bash 3.2 (Mac) and Git Bash (Windows): no associative arrays,
# no ${var,,}, no realpath or readlink -f.

COURSE_REPO_NAME=claude-code-for-pms-final
TEMPLATE_REPO_NAME=claude-code-for-pms-template
TEMPLATE_URL=https://github.com/Product-School-Platform/claude-code-for-pms-template.git
SETUP_GH_VERSION=2.101.0   # the version setup/SETUP.md (setup v2.0) installs into ~/.ccpm/gh

ccpm_lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

ccpm_os() {
  case "$(uname -s 2>/dev/null)" in
    Darwin) echo Mac ;;
    MINGW*|MSYS*|CYGWIN*) echo Windows ;;
    Linux) echo Linux ;;
    *) echo Unknown ;;
  esac
}

# Full path of a gh program that runs: ~/.ccpm/gh (any bin/gh or bin/gh.exe
# inside it) first, then gh on PATH. Prints nothing if none is found.
ccpm_find_gh() {
  local c
  if [ -d "$HOME/.ccpm/gh" ]; then
    while IFS= read -r c; do
      [ -n "$c" ] || continue
      if "$c" --version >/dev/null 2>&1; then printf '%s\n' "$c"; return 0; fi
    done <<EOF
$(find "$HOME/.ccpm/gh" -type f \( -name gh -o -name gh.exe \) -path '*/bin/*' 2>/dev/null)
EOF
  fi
  for c in gh gh.exe; do
    if command -v "$c" >/dev/null 2>&1 && "$c" --version >/dev/null 2>&1; then
      command -v "$c"; return 0
    fi
  done
  return 1
}

# "2.101.0" from `gh --version`.
ccpm_gh_version() {
  "$1" --version 2>/dev/null | tr -d '\r' | sed -n -E '1s/^gh version ([0-9][0-9.]*).*/\1/p'
}

# GitHub username if gh is signed in to github.com, else nothing.
ccpm_gh_user() {
  "$1" auth status --hostname github.com >/dev/null 2>&1 || return 1
  "$1" api user --jq .login 2>/dev/null | tr -d '\r'
}

# Whether this folder's own git setting saves to GitHub through the GitHub
# tool's sign-in: an empty credential.https://github.com.helper entry (which
# clears other sign-in methods for this folder only), then one that runs gh
# with "auth git-credential". Reads the folder's local git config only.
# Prints connected or not-connected.
ccpm_git_signin() {
  local gh=$1 vals last
  vals=$(git config --local --get-all credential.https://github.com.helper 2>/dev/null | tr -d '\r')
  last=$(printf '%s\n' "$vals" | tail -n 1)
  case "$last" in
    *"auth git-credential"*) ;;
    *) echo not-connected; return 0 ;;
  esac
  case "$last" in
    *"$gh"*|*.ccpm/gh/*|*'.ccpm\gh\'*) ;;
    *) echo not-connected; return 0 ;;
  esac
  if printf '%s\n' "$vals" | sed '$d' | grep -q '^$'; then echo connected; else echo not-connected; fi
}

# Sets this folder's own git setting to save through gh's sign-in (the setup
# prompt's Step 5). Never touches git's settings for the rest of the computer.
ccpm_connect_git() {
  git config --local --replace-all credential.https://github.com.helper "" &&
    git config --local --add credential.https://github.com.helper "!\"$1\" auth git-credential"
}

# "owner repo" for a github.com remote URL, else nothing. Never echoes the
# URL itself, so a password or token stored in a remote URL can't leak.
ccpm_parse_github() {
  printf '%s\n' "$1" | tr -d '\r' | sed -E 's#/+$##; s#\.git$##' |
    sed -n -E 's#^(https?://([^/@]+@)?github\.com/|git@github\.com:|ssh://git@github\.com/)([^/]+)/([^/]+)$#\3 \4#p'
}

# Removes anything that looks like credentials from a line of git output.
ccpm_scrub() { sed -E 's#(https?://)[^/@ ]+@#\1#g'; }
