#!/usr/bin/env bash
# Copies the student's own course files from another folder on their computer
# into the course folder. Run from the course folder with bash, only after the
# student says yes.
#
#   bash copy-in.sh <other folder>
#
# - Commits the course folder first, so nothing here can lose work.
# - Copies only: the other folder is never moved, edited or deleted.
# - Keeps both copies: a file that already exists here with different content
#   stays as it is, and the copy is saved next to it as <name>-from-old-folder.
# - Skips identical files and course plumbing (.git, .claude, .mcp.json,
#   .codex, setup/, .DS_Store).
# Then run save.sh to save the result to GitHub.

set -u
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib.sh"

src=${1:-}
if [ -z "$src" ] || [ ! -d "$src" ]; then echo "RESULT=no-such-folder"; exit 1; fi
if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != true ]; then echo "RESULT=not-a-repo"; exit 1; fi
top=$(git rev-parse --show-toplevel)
src=$(cd "$src" && pwd)
dest=$(cd "$top" && pwd)
case "$src/" in "$dest"/*) echo "RESULT=same-folder"; exit 1 ;; esac
case "$dest/" in "$src"/*) echo "RESULT=course-folder-is-inside-it"; exit 1 ;; esac
cd "$dest" || exit 1

# Commit first.
git add -A
if ! git diff --cached --quiet; then
  git commit -q -m "Save before copying in work" || { echo "RESULT=commit-failed"; exit 1; }
  echo "SAVED_FIRST=$(git rev-parse --short HEAD)"
fi

# "notes.md" -> "notes-from-old-folder.md", then -2, -3 ... if that's taken.
side_name() {
  local f=$1 dir base stem ext n cand
  dir=$(dirname "$f"); base=$(basename "$f")
  case "$base" in
    ?*.*) stem=${base%.*}; ext=".${base##*.}" ;;
    *) stem=$base; ext= ;;
  esac
  cand="$dir/$stem-from-old-folder$ext"; n=2
  while [ -e "$cand" ]; do cand="$dir/$stem-from-old-folder-$n$ext"; n=$((n + 1)); done
  printf '%s\n' "${cand#./}"
}

copied=0; both=0; same=0
while IFS= read -r -d '' f; do
  rel=${f#./}
  if [ ! -e "$dest/$rel" ]; then
    mkdir -p "$dest/$(dirname "$rel")"
    cp -p "$src/$rel" "$dest/$rel" && copied=$((copied + 1)) && echo "COPIED=$rel"
  elif cmp -s "$src/$rel" "$dest/$rel"; then
    same=$((same + 1))
  else
    side=$(side_name "$rel")
    cp -p "$src/$rel" "$dest/$side" && both=$((both + 1)) && echo "KEPT_BOTH=$rel -> $side"
  fi
done < <(cd "$src" && find . \( -name .git -o -name .claude -o -name .codex -o -name node_modules \) -prune -o \
  -type f ! -name .DS_Store ! -name .mcp.json ! -path './setup/*' -print0)

echo "NEW_FILES=$copied"
echo "KEPT_BOTH_COUNT=$both"
echo "ALREADY_THE_SAME=$same"
echo "RESULT=copied"
