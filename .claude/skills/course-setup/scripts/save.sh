#!/usr/bin/env bash
# Saves the student's work: commits and pushes to origin, and recovers from a
# rejected push without losing anything. Run from the course folder with bash.
#
#   bash save.sh "Short plain message" [path ...]    (no paths = everything)
#
# Output is KEY=value lines for Claude to read. Exit 0 = saved to GitHub.
# Exit 2 = GitHub has changes that clash with the student's; nothing was lost
# (their work is committed on this computer) and nothing was pushed.

set -u
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"
export GIT_TERMINAL_PROMPT=0   # every git network command below: never wait for a password

msg=${1:-Save my work}
[ $# -gt 0 ] && shift

if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != true ]; then
  echo "RESULT=not-a-repo"; exit 1
fi
cd "$(git rev-parse --show-toplevel)" || exit 1

if ! git remote get-url origin >/dev/null 2>&1; then echo "RESULT=not-linked"; exit 1; fi
branch=$(git symbolic-ref --short -q HEAD) || { echo "RESULT=detached"; exit 1; }
if [ -n "$(git rev-parse -q --verify MERGE_HEAD 2>/dev/null)" ]; then echo "RESULT=merge-in-progress"; exit 1; fi

# Name and email for this repo only, the same way setup/SETUP.md sets them.
if [ -z "$(git config user.name)" ] || [ -z "$(git config user.email)" ]; then
  GH=$(ccpm_find_gh || true)
  user=; email=
  if [ -n "$GH" ]; then
    user=$(ccpm_gh_user "$GH" || true)
    [ -n "$user" ] && email=$("$GH" api user --jq '"\(.id)+\(.login)@users.noreply.github.com"' 2>/dev/null | tr -d '\r')
  fi
  if [ -z "$user" ] || [ -z "$email" ]; then echo "RESULT=no-identity"; exit 1; fi
  git config user.name "$user"
  git config user.email "$email"
  echo "IDENTITY=set"
fi

if [ $# -gt 0 ]; then git add -A -- "$@"; else git add -A; fi
if git diff --cached --quiet; then
  echo "COMMITTED=nothing-new"
else
  git commit -q -m "$msg" || { echo "RESULT=commit-failed"; exit 1; }
  echo "COMMITTED=$(git rev-parse --short HEAD)"
fi

push() { git push -u origin "$branch" 2>&1 | ccpm_scrub; return "${PIPESTATUS[0]}"; }
bring_in() {
  git fetch origin "$branch" 2>&1 | ccpm_scrub
  [ "${PIPESTATUS[0]}" -eq 0 ] || return 1
  git merge --no-edit -m "Bring in changes from GitHub" FETCH_HEAD 2>&1 | ccpm_scrub
  return "${PIPESTATUS[0]}"
}

# The line of git's output worth quoting to the student or in Slack.
first_error() {
  printf '%s\n' "$1" | grep -m 1 -E '^(fatal|error|ERROR|remote: [A-Za-z])' ||
    printf '%s\n' "$1" | grep -v '^ *$' | tail -n 1
}

out=$(push); rc=$?
if [ $rc -ne 0 ] && printf '%s' "$out" | grep -qiE 'rejected|non-fast-forward|fetch first'; then
  # GitHub has commits this computer doesn't. Bring them in with a merge
  # (the student's commit stays as it is), then push again.
  echo "PUSH=rejected-once"
  pout=$(bring_in); prc=$?
  if [ "$prc" -ne 0 ]; then
    if [ -n "$(git rev-parse -q --verify MERGE_HEAD 2>/dev/null)" ]; then
      echo "CLASHING_FILES=$(git diff --name-only --diff-filter=U | tr '\n' ' ')"
      git merge --abort
      echo "RESULT=clash"
      exit 2
    fi
    echo "RESULT=pull-failed"
    echo "ERROR=$(first_error "$pout")"
    exit 1
  fi
  out=$(push); rc=$?
fi

if [ $rc -eq 0 ]; then
  echo "PUSHED=yes"
  echo "BRANCH=$branch"
  echo "RESULT=saved"
else
  echo "RESULT=push-failed"
  echo "ERROR=$(first_error "$out")"
  exit 1
fi
