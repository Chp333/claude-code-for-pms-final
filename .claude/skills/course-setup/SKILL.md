---
name: course-setup
description: Checks, saves and repairs a student's setup for the Claude Code for PMs course. Use it when the student says "check my setup" (or "is my setup working", "am I ready for Module 1", "test my setup"); when they say "save my work" (or "save my progress", "push my work", "back up my work"); and when they describe a setup problem in their own words, such as GitHub asking them to sign in, their work not showing up on GitHub, saving failing, their repo being private or their instructor not seeing their work, "rook-wiki" or "rook-database" missing or not answering, or opening the wrong folder.
---

# Course setup

You're helping a student in Product School's "Claude Code for PMs" course. They
aren't technical. Their course folder is a copy of their own GitHub repo,
`<their username>/claude-code-for-pms-final`, which the course setup (the
steps in `setup/SETUP.md`) created before this session. This skill checks that setup, saves their work, and
repairs common problems.

## Rules for every part of this skill

- Keep messages to the student short and plain. Say what will happen to them
  and their work, not how the system works. Don't show them raw command output.
- Put `GIT_TERMINAL_PROMPT=0` in front of every git command that talks to
  GitHub (fetch, pull, push, clone, ls-remote), so nothing freezes waiting for a
  password. The scripts below already do this.
- Never ask for, type, print or store a password or token. GitHub sign-in only
  ever happens in the student's web browser, through the setup prompt.
- Commit the student's work before any repair (run `scripts/save.sh`, or at
  least `git add -A && git commit`), so a repair can never lose it.
- Never delete anything. If a file or folder is in the way, rename it with
  `-old` on the end and tell the student.
- Repairs are yours to do, not the student's. For each one, tell the student
  in one plain sentence what you're about to do, wait for their yes, do it,
  then tell them the result. The student never does file work by hand.
- Their repo stays Public until the course ends, so their instructor can see
  their work. Never make it Private.
- Outside the course folder, the course folder's CLAUDE.md allows exactly
  these, for this skill only:
  - When the student asks you to check their setup or save their work, that
    request is their yes. You may run the GitHub program installed at
    `~/.ccpm/gh` for those checks and saves, and look in that folder to find
    it.
  - For a repair, first tell the student in one plain sentence what you're
    about to do, and act only after they say yes. Repairs may: run that GitHub
    program (including setting this folder's own git sign-in setting and
    changing this repo's visibility back to Public); copy the student's own
    course files into the course folder from another folder on their
    computer (copy only; never move, edit or delete the originals); and
    rename something outside the course folder that blocks setup, by adding
    `-old` to its name (never delete it).

  Outside the course folder you never write, edit or delete anything else.
- Rook content: the checks below may confirm that a Rook connector answers, but
  never show, summarize or comment on what it returned beyond the one page
  title or the one number named in the check.

The scripts are in this skill's folder (the folder this file is in). Run them
with `bash`, from the session's folder, for example
`bash <this skill's folder>/scripts/checkup.sh`. They print `KEY=value` lines
for you to read.

## "check my setup"

The student's request is their yes: start right away, with at most one plain
sentence such as "Checking your setup now." Run the six checks in order and
show the checklist. Work out each result first;
don't narrate every step.

Run `bash <skill folder>/scripts/checkup.sh`. It answers the first three:

1. **Course folder linked to your GitHub repo** — `CHECK1=pass`. If it failed,
   use the matching fix from `references/troubleshooting.md`:
   `inside-subfolder` and `not-a-repo` → "Wrong folder";
   `linked-to-template` → "Linked to the course template"; `not-linked`,
   `linked-elsewhere`, `someone-elses-repo` → "Linked to the wrong repo";
   `git-missing` → paste the course setup prompt again (the one-line prompt
   from their pre-class materials).
2. **Your repo is Public** — `CHECK_PUBLIC=pass`. If `fail:private`, say:
   "Your repo on GitHub is set to Private, so your instructor can't see your
   work. Can I switch it back to Public?" On yes, run
   `bash <skill folder>/scripts/checkup.sh make-public`. `RESULT=public`
   passes; tell them it's Public again. If `fail:cannot-check`, check 1 or 3
   failed; fix that first.
3. **Signed in to GitHub** — `CHECK2=pass`. If `gh-missing` or
   `not-signed-in`, the fix is: paste the course setup prompt again (the
   one-line prompt from their pre-class materials; troubleshooting,
   "GitHub tool missing or not signed in"). If `git-not-connected`, the
   student is signed in but this folder's git isn't using that sign-in: use
   the repair in troubleshooting, "Signed in, but git isn't using the
   sign-in".

If check 1 or 3 fails, still do checks 4 and 5, but skip check 6 (saving can't
work yet) and mark it ✗ with "fix the checks above first".

**Check 4. Rook wiki answers.** Make one call to the rook-wiki tool
`search_wiki` with the query `Team directory`. It passes if the reply lists a
result titled "Team directory". Show the student only that title.

**Check 5. Rook database answers.** Make one call to the rook-database tool
`run_query` with `select count(*) as row_count from handlers`. It passes if the
count is above zero. Show the student only the number.

For checks 4 and 5:

- **Busy, not broken.** If the reply says the connector "is busy right now",
  or the wiki "is not available yet", or it starts "Something went wrong" and
  mentions connections: wait about 30 seconds (`sleep 30`) and call again, up
  to 3 more times. If it's still busy, mark ✗ and tell the student it's busy,
  not broken, and to type "check my setup" again in a few minutes.
- **Tools not there.** If this session has no rook-wiki or rook-database
  tools, mark ✗ and tell the student: "Start a new session: in the Claude app,
  go to the Code tab, click + New session, choose your course folder
  (<full path>) as the Project folder, and type: check my setup. If Claude
  asks whether you trust this folder, or whether to allow the rook-wiki and
  rook-database servers, say yes." The trust question is the normal first
  prompt on a new course folder; the connectors only start once the student
  says yes to it. More in troubleshooting, "A Rook connector doesn't show
  up".
- Any other reply is ✗: note the exact message for the Slack post.

**Check 6. Saving works.** Only if checks 1 and 3 passed:

1. `bash <skill folder>/scripts/checkup.sh record <4> <5>`, where `<4>` and
   `<5>` are `pass` or `fail`. This writes `setup/setup-complete.md` with the
   username, date, Mac or Windows, the setup prompt version, and each check's
   result, including whether the repo is Public (it checks that again
   itself). Don't add anything else to that file: no email, computer name or
   paths.
2. `bash <skill folder>/scripts/save.sh "Setup complete" setup/setup-complete.md`.
   `RESULT=saved` is what you want. For anything else, see "save my work"
   below.
3. `bash <skill folder>/scripts/checkup.sh confirm`. `CONFIRMED=yes` passes;
   give the student the `LINK`.

**Finish** with the checklist, one line per check, ✓ or ✗:

```
✓ Course folder linked to your GitHub repo
✓ Your repo is Public
✓ Signed in to GitHub
✓ Rook wiki answers (found "Team directory")
✓ Rook database answers (<the count> rows)
✓ Saving works: <link>
```

If the checkup said `OLD_FOLDER=yes`, the student has earlier work in
`claude-code-for-pms-final-old`: offer to copy it in (troubleshooting,
"Linked to the course template").

- All ✓: "You're all set. You're ready for Module 1."
- Any ✗: give the fix for the first ✗ in one or two plain sentences. If the
  fix doesn't work, tell them to post in their course Slack channel: which
  check failed, the exact error message, and whether they're on a Mac or
  Windows (`OS` from the checkup).

## "save my work"

The end-of-module routine. Full steps, and what to do when saving is refused,
are in `references/saving-work.md`. In short:

1. The student's request is their yes: start right away, with at most one
   plain sentence such as "Saving your work to GitHub now."
2. `bash <skill folder>/scripts/checkup.sh`. If check 1 or 3 fails, fix that
   first (the save would go nowhere). If the repo is Private, offer to switch
   it back to Public (check 2).
3. Pick a short plain message from what changed, like "Module 2 work".
4. `bash <skill folder>/scripts/save.sh "<message>"`.
5. `RESULT=saved`: tell them their work is saved to GitHub and give the link
   `https://github.com/<GH_USER>/claude-code-for-pms-final`.
   `COMMITTED=nothing-new` with `RESULT=saved` means everything was already
   saved; say so.
   Anything else: follow `references/saving-work.md`.

## Problems described in plain words

Match the symptom to `references/troubleshooting.md` and follow it. Run
`scripts/checkup.sh` first when you're not sure what's wrong. If the student
hasn't set up yet at all, see `references/first-time-setup.md`.
