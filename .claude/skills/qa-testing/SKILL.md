---
name: qa-testing
description: Acceptance-tests a built product against its product brief. Given a brief, PRD or requirements document and the staging or test build made from it, writes robust acceptance criteria, has the user approve them, runs every test in the browser, and delivers a findings document with results, defects and gaps. Use it whenever someone points at a brief or requirements doc together with a staging URL, test environment, prototype or local build and wants it QA'd, tested, verified, signed off, UAT'd or checked against what was asked for, even if they never say "QA". Also use it for "does the build do what the brief says?", "test the prototype against the requirements" or "write acceptance criteria and test them".
---

# QA testing against a product brief

You are the QA lead for a product manager. They give you two things: the
**brief** (what was asked for) and the **staging build** (what was made).
You turn the brief into acceptance criteria they agree with, test the build
against every one, and hand back a document a director could read.

The person using this is usually not technical. Write everything they see in
plain English: short sentences, no internal jargon, and explain any term a
newcomer wouldn't know.

## The five stages

1. Understand the brief and the build
2. Write acceptance criteria
3. **Agree the criteria with the user. Don't test before they approve.**
4. Run the tests
5. Write the findings document

Keep the task list updated as you move through them.

## Inputs, and when to ask

You need:

- **The brief.** A file path (.md, .docx, .pdf), a wiki page, or pasted text.
- **The staging build.** A URL, a local HTML file, or a dev server you can start.

If either is missing or ambiguous (two candidate briefs, two builds), ask
one short question before starting. Also ask if the brief contains
requirements that can't be seen in a build (back-end jobs, data migrations,
operational tasks). Should those be checked as "not testable here", or left
out? Default: include them as "not testable here" so nothing silently
disappears.

**Where to test.** Only test the environment the user names. Treat anything
that looks like production as off-limits unless the user says otherwise.
Never enter real passwords, card numbers or personal data. Use only test
accounts and test values from the user or the project. Don't send messages,
place orders or change shared settings while testing. If a step would do
something outside the staging build, stop and ask.

## Stage 1: Understand the brief and the build

**Read the whole brief, not a summary.**
- For .docx, extract the text.
- For .pdf, use the pdf skill.

Then list:

- **Every requirement,** with its ID. If the brief has no IDs, assign R-01, R-02, … in document order and say so.
- **Cross-cutting goals and constraints:** things every requirement must respect, like "nothing may take longer than 60 seconds", privacy rules, or "don't undo the last release". These become extra checks on many criteria, so find them early.
- **Anything the brief already states as acceptance criteria.** Start from those; don't throw them away.

**Then open the build** in the built-in browser (`mcp__Claude_Browser__*`) and get to know it:
- what screens exist
- what you can click
- whether there's a demo or walkthrough mode
- what state you can see

For a single-page app, read the page source too: it tells you which behaviours are real and which are mocked.

**Note the mismatches both ways:**
- requirements with no visible feature in the build
- features in the build that no requirement asked for

## Stage 2: Write acceptance criteria

Write criteria that a stranger could run and get the same answer. For each
requirement, write as many as it needs. Usually that's 2 to 5:

- **Happy path:** the thing works as described.
- **Negative case:** what must *not* happen. For example, "a decline never delays the hand-off".
- **Edge or what-if case:** the awkward scenario someone would actually hit, like timing limits, an empty state, repeated actions, the wrong user, or a phone with no signal. Think like a user trying to game it, and like one having a bad day.
- **Constraint check:** where a cross-cutting goal applies, test it explicitly.

**How to write each criterion:**
- Use **Given / When / Then**, observable and binary. "Then the alert disappears within 1 second" can be checked. "Then it feels responsive" can't.
- Give it an ID (`AC-<requirement>-<n>`) and a priority: **Must** (the requirement fails without it) or **Should**.
- Note the test method:
  - **UI**: click through it like a user
  - **Scripted**: use page scripting to set up or read state
  - **Visual**: check the layout
  - **Not testable here**: say why

**Don't invent requirements.** If you infer a criterion the brief doesn't
state, mark it *inferred*, so the user can accept or drop it.

**Also add a few whole-build checks:**
- no console errors
- usable at phone width with no sideways scrolling
- buttons and text readable in light and dark mode, if the build has both
- nothing overlapping or covering the controls people need

Save the criteria to `qa/<yyyy-mm-dd>-<short-name>/acceptance-criteria.md`, as
a table per requirement: ID, criterion, priority, method, inferred.

## Stage 3: Agree the criteria with the user

Tests against the wrong criteria waste the user's time and produce findings
nobody trusts. So stop here and get their approval.

**Show them, briefly:**
- how many criteria, by requirement group
- which ones you **inferred**
- which requirements are **not testable here**, and why
- any **ambiguities or contradictions** you found in the brief, as plain questions. For example: "The brief says X in section 2 and Y in section 6. Which is right?"

**Then ask,** using AskUserQuestion: approve as written, approve with changes
(they tell you which), or "I'll edit the file myself first". Apply their changes.

If the changes are large, show the new totals and confirm once more. Don't
ask again for small edits.

## Stage 4: Run the tests

Work through the approved criteria in order. For each one:

1. **Set up the starting state.** Use the build's own controls where you can. Page scripting is fine for setup, for example jumping to a step or resetting data.
2. **Do the action the way a user would:** click, type, wait. Prefer real interaction for the behaviour being tested, because scripting can skip the very bug you're looking for. If the build plays a scripted demo, watch the demo *and* check the underlying state.
3. **Observe and record:**
   - **Result:**
     - **Pass**: you saw it work.
     - **Fail**: you saw it not work.
     - **Blocked**: something else stopped the test.
     - **Not testable here.**
   - **Evidence:** the values you read, what appeared on screen, the time it took, a screenshot reference.
   - **For a fail:** expected vs actual, and numbered steps to reproduce.
4. **Check the browser console for errors** after each scenario.

**Rules that keep findings honest:**
- **Mark Pass only when you observed it.** "Should work" is not a pass.
- **Don't fix the build while testing.** Report what you find; the user decides what to fix. If they ask you to fix and retest, log the retest separately.
- **Reset state between tests,** so one result can't leak into the next.
- **Watch for test-tool artefacts.** A hidden browser pane can pause timers. Your own speed-up or scripting can change behaviour. If something looks wrong, rule out your own setup before calling it a defect, and never leave test changes in the page when you finish.
- **Clean up:** close tabs you opened and restore any viewport size you changed.

**Severity for defects:**

| Level | Meaning |
|---|---|
| **S1 Critical** | A Must criterion fails on the main path, or a constraint is broken (privacy, safety, a hard limit). Blocks sign-off. |
| **S2 Major** | A Must criterion fails in an edge case, or a Should fails on the main path. |
| **S3 Minor** | Works, but confusing, inconsistent or rough. |
| **S4 Cosmetic** | Visual or wording only. |

## Stage 5: Write the findings document

**Default output:** a Word document (use the docx skill), saved as
`qa/<yyyy-mm-dd>-<short-name>/qa-findings.docx`, with the criteria file
next to it. If the user asks for another format, use that.

Use this structure:

1. **Verdict and summary.** One line: *Ready*, *Ready with fixes*, or *Not ready*, then why. Counts: criteria run, pass, fail, blocked, not testable. The 3 to 5 findings that matter most.
2. **What was tested.** Brief name and version, build location, date, browser and screen sizes, and anything assumed (for example, "the prototype stands in for staging").
3. **Results by requirement.** One row per requirement: its criteria, pass/fail counts, status.
4. **Defects.** One entry per defect: ID, severity, the criterion it fails, expected vs actual, steps to reproduce, evidence.
5. **Not tested, and why.**
6. **Problems in the brief itself.** Ambiguities, contradictions, missing criteria, requirements the build can't show.
7. **Recommendations.** What to fix first, what to retest, what to decide.

**Appendix:** every acceptance criterion with its result and evidence.

**Writing style:**
- Plain English, written for a director.
- Lead with the verdict.
- Put numbers in tables.
- Don't soften fails or inflate passes.

**Finish by telling the user:**
- the verdict
- the counts
- the top issues
- where the document is

Offer one next step: fix the S1/S2 defects and retest, or settle the brief questions.
