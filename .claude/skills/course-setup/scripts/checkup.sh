#!/usr/bin/env bash
# course-setup checkup. Run from the session's folder with bash.
#
#   bash checkup.sh                  folder, repo visibility and GitHub sign-in
#   bash checkup.sh make-public      switches the student's repo back to Public
#                                    (only after the student says yes)
#   bash checkup.sh connect-git      sets this folder's own git setting to save
#                                    through the GitHub tool's sign-in (only
#                                    after the student says yes); never changes
#                                    git's settings for the rest of the computer
#   bash checkup.sh record WIKI DB   writes setup/setup-complete.md; WIKI and DB
#                                    are pass or fail (the Rook checks)
#   bash checkup.sh confirm          checks GitHub has this commit's
#                                    setup/setup-complete.md; prints its link
#
# Output is KEY=value lines for Claude to read, never shown to the student
# as is. Nothing here prints a remote URL, token or email address.

set -u
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"

OS=$(ccpm_os)
GH=$(ccpm_find_gh || true)
GH_VERSION=
GH_USER=
if [ -n "$GH" ]; then
  GH_VERSION=$(ccpm_gh_version "$GH")
  GH_USER=$(ccpm_gh_user "$GH" || true)
fi

# ---- check 1: the session is on the course folder, linked to the student's repo
IN_REPO=no; AT_TOP=no; OWNER=; REPO=; ORIGIN_KIND=none; CHECK1=
if ! command -v git >/dev/null 2>&1; then
  CHECK1=fail:git-missing
elif [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != true ]; then
  CHECK1=fail:not-a-repo
else
  IN_REPO=yes
  [ -z "$(git rev-parse --show-prefix 2>/dev/null)" ] && AT_TOP=yes
  url=$(git remote get-url origin 2>/dev/null || true)
  if [ -n "$url" ]; then
    read -r OWNER REPO <<EOF
$(ccpm_parse_github "$url")
EOF
    lrepo=$(ccpm_lower "$REPO")
    if [ -z "$REPO" ]; then ORIGIN_KIND=other
    elif [ "$lrepo" = "$COURSE_REPO_NAME" ]; then ORIGIN_KIND=own
    elif [ "$lrepo" = "$TEMPLATE_REPO_NAME" ]; then ORIGIN_KIND=template
    else ORIGIN_KIND=other
    fi
  fi
  if [ "$AT_TOP" = no ]; then CHECK1=fail:inside-subfolder
  elif [ "$ORIGIN_KIND" = template ]; then CHECK1=fail:linked-to-template
  elif [ "$ORIGIN_KIND" = none ]; then CHECK1=fail:not-linked
  elif [ "$ORIGIN_KIND" = other ]; then CHECK1=fail:linked-elsewhere
  elif [ -n "$GH_USER" ] && [ "$(ccpm_lower "$OWNER")" != "$(ccpm_lower "$GH_USER")" ]; then
    CHECK1=fail:someone-elses-repo
  else CHECK1=pass
  fi
fi

# ---- check 2: signed in to GitHub, and this folder's git uses that sign-in
GIT_SIGNIN=not-connected
[ "$IN_REPO" = yes ] && [ -n "$GH" ] && GIT_SIGNIN=$(ccpm_git_signin "$GH")
if [ -z "$GH" ]; then CHECK2=fail:gh-missing
elif [ -z "$GH_USER" ]; then CHECK2=fail:not-signed-in
elif [ "$IN_REPO" = yes ] && [ "$GIT_SIGNIN" != connected ]; then CHECK2=fail:git-not-connected
else CHECK2=pass
fi

# ---- visibility: the student's repo stays Public through the course
repo_visibility() {
  "$GH" api "repos/$OWNER/$REPO" --jq .visibility 2>/dev/null | tr -d '\r'
}
VISIBILITY=unknown
if [ "$CHECK1" != pass ] || [ -z "$GH_USER" ]; then
  CHECK_PUBLIC=fail:cannot-check
else
  VISIBILITY=$(repo_visibility)
  case "$VISIBILITY" in
    public) CHECK_PUBLIC=pass ;;
    private|internal) CHECK_PUBLIC=fail:private ;;
    *) VISIBILITY=unknown; CHECK_PUBLIC=fail:cannot-check ;;
  esac
fi

mark() { case "$1" in pass) printf '✓' ;; *) printf '✗' ;; esac; }

do_check() {
  echo "OS=$OS"
  echo "IN_REPO=$IN_REPO"
  echo "AT_TOP=$AT_TOP"
  echo "ORIGIN_KIND=$ORIGIN_KIND"
  [ -n "$REPO" ] && echo "ORIGIN=github.com/$OWNER/$REPO"
  echo "GH=${GH:-missing}"
  [ -n "$GH_VERSION" ] && echo "GH_VERSION=$GH_VERSION"
  echo "SIGNED_IN=$([ -n "$GH_USER" ] && echo yes || echo no)"
  [ -n "$GH_USER" ] && echo "GH_USER=$GH_USER"
  echo "GIT_SIGNIN=$GIT_SIGNIN"
  # Earlier work set aside by setup/SETUP.md, next to the course folder.
  if [ "$IN_REPO" = yes ] && [ -d "$(git rev-parse --show-toplevel)-old" ]; then echo "OLD_FOLDER=yes"; else echo "OLD_FOLDER=no"; fi
  echo "VISIBILITY=$VISIBILITY"
  echo "CHECK1=$CHECK1"
  echo "CHECK_PUBLIC=$CHECK_PUBLIC"
  echo "CHECK2=$CHECK2"
}

do_make_public() {
  local out rc
  if [ "$CHECK1" != pass ] || [ -z "$GH_USER" ]; then
    echo "RESULT=not-changed (fix the folder and sign-in checks first)"; echo "CHECK1=$CHECK1"; echo "CHECK2=$CHECK2"; exit 1
  fi
  if [ "$VISIBILITY" = public ]; then echo "RESULT=already-public"; exit 0; fi
  out=$("$GH" repo edit "$OWNER/$REPO" --visibility public --accept-visibility-change-consequences 2>&1); rc=$?
  if [ $rc -eq 0 ] && [ "$(repo_visibility)" = public ]; then
    echo "RESULT=public"
  else
    echo "RESULT=failed"
    echo "ERROR=$(printf '%s\n' "$out" | tr -d '\r' | grep -v '^ *$' | head -n 1)"
    exit 1
  fi
}

do_connect_git() {
  local out rc
  if [ "$CHECK1" != pass ] || [ -z "$GH_USER" ]; then
    echo "RESULT=not-changed (fix the folder and sign-in checks first)"; echo "CHECK1=$CHECK1"; echo "CHECK2=$CHECK2"; exit 1
  fi
  if ! ccpm_connect_git "$GH"; then echo "RESULT=failed"; echo "ERROR=could not change this folder's git setting"; exit 1; fi
  out=$(GIT_TERMINAL_PROMPT=0 git ls-remote origin 2>&1 >/dev/null); rc=$?
  if [ $rc -eq 0 ] && [ "$(ccpm_git_signin "$GH")" = connected ]; then
    echo "RESULT=connected"
  else
    echo "RESULT=failed"
    echo "ERROR=$(printf '%s\n' "$out" | tr -d '\r' | ccpm_scrub | grep -v '^ *$' | head -n 1)"
    exit 1
  fi
}

do_record() {
  local wiki=${1:-} db=${2:-} top version
  case "$wiki" in pass|fail) ;; *) echo "RESULT=usage: record pass|fail pass|fail"; exit 1 ;; esac
  case "$db" in pass|fail) ;; *) echo "RESULT=usage: record pass|fail pass|fail"; exit 1 ;; esac
  if [ "$CHECK1" != pass ] || [ "$CHECK2" != pass ]; then
    echo "RESULT=not-recorded (fix checks 1 and 2 first)"; echo "CHECK1=$CHECK1"; echo "CHECK2=$CHECK2"; exit 1
  fi
  version=unknown
  case "$GH" in
    "$HOME/.ccpm/gh/"*) [ "$GH_VERSION" = "$SETUP_GH_VERSION" ] && version=v2.0 ;;
  esac
  top=$(git rev-parse --show-toplevel)
  mkdir -p "$top/setup"
  cat > "$top/setup/setup-complete.md" <<EOF
# Setup complete

- GitHub username: $GH_USER
- Date: $(date +%Y-%m-%d)
- Computer: $OS
- Setup prompt: $version

## Checks

- $(mark "$CHECK1") Course folder linked to my GitHub repo
- $(mark "$CHECK_PUBLIC") My repo is Public
- $(mark "$CHECK2") Signed in to GitHub
- $(mark "$wiki") Rook wiki answers
- $(mark "$db") Rook database answers
- ✓ Saving works (this file was saved to GitHub)
EOF
  echo "RESULT=recorded"
  echo "FILE=setup/setup-complete.md"
}

do_confirm() {
  local branch local_sha remote_sha i
  if [ "$ORIGIN_KIND" != own ] || [ -z "$GH_USER" ]; then
    echo "CONFIRMED=no"; echo "REASON=check1:$CHECK1 check2:$CHECK2"; exit 1
  fi
  branch=$(git symbolic-ref --short -q HEAD || echo main)
  local_sha=$(git rev-parse -q --verify "HEAD:setup/setup-complete.md" 2>/dev/null || true)
  if [ -z "$local_sha" ]; then echo "CONFIRMED=no"; echo "REASON=file-not-committed"; exit 1; fi
  for i in 1 2 3; do
    remote_sha=$("$GH" api "repos/$OWNER/$REPO/contents/setup/setup-complete.md?ref=$branch" --jq .sha 2>/dev/null | tr -d '\r' || true)
    [ "$remote_sha" = "$local_sha" ] && break
    sleep 5
  done
  if [ "$remote_sha" = "$local_sha" ]; then
    echo "CONFIRMED=yes"
  else
    echo "CONFIRMED=no"
    [ -z "$remote_sha" ] && echo "REASON=not-on-github" || echo "REASON=github-has-an-older-copy"
  fi
  echo "LINK=https://github.com/$OWNER/$REPO/blob/$branch/setup/setup-complete.md"
  [ "$remote_sha" = "$local_sha" ]
}

case "${1:-check}" in
  check) do_check ;;
  record) shift; do_record "$@" ;;
  make-public) do_make_public ;;
  connect-git) do_connect_git ;;
  confirm) do_confirm ;;
  *) echo "RESULT=usage: checkup.sh [check|make-public|connect-git|record WIKI DB|confirm]"; exit 1 ;;
esac
