---
name: wrap-up
description: Ends a class session in the Claude Code for PMs course. Use it when the student says "wrap up" (or "wrap up this session", "let's wrap up", "end of session", "we're done for today", "I'm done with this module"). It saves the prompts the student wrote this session into that module's prompts.md, adds what the session figured out to the Working context in CLAUDE.md, and saves everything to GitHub.
---

# Wrap up

You're closing out a class session for a student in Product School's "Claude Code for PMs" course. They aren't technical, and they typed two words so they wouldn't have to type anything else. Their request is their yes: start right away with one plain sentence such as "Wrapping up today's session now." Don't ask them to type or paste anything unless a step below says to.

## 1. Work out which module this was

The module folders are 01-origin-story (Module 1), 02-super-hearing (Module 2), 03-rewind (Module 3), 04-x-ray-vision (Module 4), 05-super-speed (Module 5) and 06-sidekicks (Module 6).

- Use this session: the module the student's work and questions were about.
- If the session doesn't make it clear, use the first module folder whose prompts.md still has an empty numbered slot.
- If you still can't tell, ask one short question: "Which module was today, 1 to 6?"

## 2. Save the student's own prompts

- Look back through this session for the prompts the student wrote themselves. Leave out: the starter prompt each lab gives the whole room (the long, polished prompt the student pasted from a slide or the Zoom chat), "wrap up", "check my setup", "save my work", and short replies such as "yes", "ok" or "go ahead".
- Write them into that module's prompts.md, one per numbered slot (### 1., ### 2., ### 3.), in the order the student typed them, exactly as typed. Don't fix spelling, trim, reword or summarize.
- If there are more prompts than empty slots, add ### 4., ### 5. and so on.
- If some slots already hold prompts (from an earlier wrap-up), keep them and add the new ones after them. Never overwrite or delete anything already in the file.
- Leave the file's header text as it is.
- If the student wrote no prompts of their own this session, leave the file alone and say so.

## 3. Add to the Working context in CLAUDE.md

- Under "## Working context", after everything already there, add three to six short plain lines: what this session figured out about Rook that isn't written there yet and that you'd want to know at the start of the next session. That means findings, which sources mattered, and questions still open.
- If the section still holds only the placeholder "_You'll fill this in during Module 1._", replace just that placeholder line.
- Don't repeat what's already there, don't add headings, and don't paste in whole documents.
- Never change anything above the "---" line (the session scope block).
- Rook is fictional. Keep all of this in CLAUDE.md: never save it to memory or anywhere outside the course folder.

## 4. Module 5 only: check the build files

If today was Module 5, check that 05-super-speed/brief.md and 05-super-speed/prototype.html are both there. If either is missing, tell the student which one. Don't recreate it.

## 5. Save to GitHub

Follow the "save my work" routine in the course-setup skill (.claude/skills/course-setup/SKILL.md and its references/saving-work.md), with a short message such as "Module 2 wrap-up". Handle every problem exactly the way that routine says.

## 6. Tell the student

A short checklist, then the link:

✓ Saved your prompts to <module folder>/prompts.md (how many)
✓ Added what we learned today to CLAUDE.md
✓ Saved to GitHub: https://github.com/<their username>/claude-code-for-pms-final

If a step didn't work, mark it ✗ and give the fix in one plain sentence. If saving to GitHub failed, tell them their prompts and notes are safe on this computer and what to do next, per the save routine.
