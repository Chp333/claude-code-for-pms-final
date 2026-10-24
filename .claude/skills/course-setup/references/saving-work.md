# Saving work

"Save my work" is the end-of-module routine: everything in the course folder
is committed and pushed to the student's own GitHub repo, so it's backed up
and they can pick up on any computer.

## The routine

1. Run `bash <skill folder>/scripts/checkup.sh`. Both `CHECK1` and `CHECK2`
   must be `pass`. If not, fix that first (see troubleshooting.md). Saving
   to the course template or to someone else's repo can't work.
2. Look at what changed (`git status --short`) so you can write a short plain
   message: "Module 3 work", "Module 1 working context", "Prompts from
   Module 2". No jargon.
3. Run `bash <skill folder>/scripts/save.sh "<message>"`. It:
   - sets the folder's name and private GitHub email if they're missing (the
     same values `setup/SETUP.md` uses);
   - commits everything (`git add -A`);
   - pushes to GitHub with `GIT_TERMINAL_PROMPT=0`;
   - if GitHub refuses the push because it has changes this computer doesn't
     (for example, the student edited a file on the GitHub website), brings
     those in with a merge and pushes again.
4. Tell the student the result in one or two sentences, with the link
   `https://github.com/<username>/claude-code-for-pms-final`.

## What the results mean

| Result | What to do |
|---|---|
| `RESULT=saved` | Done. If `COMMITTED=nothing-new`, say everything was already saved. |
| `RESULT=clash` (exit 2) | GitHub and this computer both changed the same file(s) (`CLASHING_FILES`). Nothing is lost: the student's work is committed here and nothing was pushed. Follow "Keeping both versions" below, with their OK. |
| `RESULT=no-identity` | gh isn't signed in, so the name and email couldn't be set. Fix the sign-in (troubleshooting.md, "GitHub tool missing or not signed in"), then save again. |
| `RESULT=push-failed` | Read `ERROR`. "Authentication failed", "could not read Username" or 403: the sign-in is gone (same fix as above). "Repository not found": troubleshooting.md, "Linked to the wrong repo". "Could not resolve host" or timeouts: the computer is offline; try again when it's back. |
| `RESULT=pull-failed` | Read `ERROR` and use the same table row as push-failed. |
| `RESULT=detached` | See troubleshooting.md, "Not on the main branch". |
| `RESULT=merge-in-progress` | An earlier merge was left half-finished. Commit what's there (`git add -A`, `git commit --no-edit`), then save again. |
| `RESULT=not-a-repo` or `not-linked` | Wrong folder: troubleshooting.md, "Wrong folder". |

## Keeping both versions

Only after the student says OK. Their work is already committed, so this
can't lose anything.

1. `GIT_TERMINAL_PROMPT=0 git fetch origin <branch>`, then
   `git merge -m "Bring in changes from GitHub" FETCH_HEAD` (it stops with
   the clashing files).
2. For each clashing file `F`, keep the student's version in place and save
   GitHub's version next to it with `-from-github` before the extension:
   `git show MERGE_HEAD:F > "F-from-github.ext"` and `git checkout --ours -- F`.
3. `git add -A`, then `git commit --no-edit`.
4. Run `scripts/save.sh "<message>"` again.
5. Tell the student which files have a `-from-github` copy, and that they can
   compare the two and delete the one they don't want whenever they like.

## Never

- Never force-push, reset, or rebase the student's work.
- Never use `git stash` or `git clean` as a shortcut.
- Never save to any repo other than `<username>/claude-code-for-pms-final`.
