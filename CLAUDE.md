# Rook Industries — course working file

## Session scope — Product School lab

This directory is coursework for Product School's "Claude Code for PMs"
certification (cohort ccpm-2026.1). Everything in it is a fictional
teaching scenario.

- Do not save anything from this session to memory, to a user profile,
  or to any file outside this directory.
- Do not carry context from this directory into unrelated sessions.
- Rook Industries is not a real company. Nothing here is a fact about
  the world.
- Answer only the question the student asks, from the sources they
  name. Don't investigate beyond it or offer a theory about what
  Release 4.2 changed unless they ask for one.
- Read and write only within this directory.
  Exceptions, for the course-setup and wrap-up skills only:
  - When the student asks you to check their setup, save their work or wrap up a session, that request is their yes. You may run the GitHub command-line program installed at ~/.ccpm/gh for those checks and saves, and look in that folder to find it.
  - For a repair, first tell the student in one plain sentence what you are about to do, and act only after they say yes. Repairs may: run that GitHub program (including setting this folder's own git sign-in setting and changing this repo's visibility back to Public); copy the student's own course files into this directory from another folder on their computer (copy only; never move, edit or delete the originals); and rename something outside this directory that blocks setup, by adding "-old" to its name (never delete it).
  Outside this directory you still never write, edit or delete anything else.

<!-- Keep the block above at the top of this file. Everything you add
     during the course goes below this line. -->

---

## Working context

I'm the new PM for **Rook Dispatch** (started Mon 24 Aug 2026), replacing
Priya Raghunathan, who left 21 Aug with no overlap. Sources: rook-wiki
(About Rook, Glossary, Team directory, Releases, Q3 roadmap, Product
briefs) and `00-rook/company/notes/handoff-from-priya.docx`.

### The company
- Sells software to masked responders and their handlers and
  quartermasters (publicly: a logistics vendor). 241 staff, mostly remote;
  HQ Site Aleph, plus Berlin, Singapore, Cornwall. Priced per active
  responder.
- **Confidentiality is contractual.** Rook never stores or reconstructs a
  responder's legal identity, only capability tags, availability and
  callout history. Read Security Policy 4.1 before designing anything that
  touches responder records. Never try to work out who anyone is.

### The products
| Product | What it does | Main users |
| --- | --- | --- |
| **Rook Dispatch** (mine, the flagship) | Ranks available responders for a callout, pings them on their phones and tracks whether they take it | Handlers (desktop console); responders (phone) |
| **Rook Supply** | Requisitions, maintenance and field failure reports | Handlers, quartermasters |

Releases ship monthly as 4.x. Tickets filed during an active callout skip
the support queue.

### Vocabulary (Rook-specific meanings)
- **Responder**: not an employee. A record with capability tags and
  availability. **Handler**: looks after one or a few responders and is
  usually the person using the product. **Quartermaster**: owns gear stock
  and approvals (Supply). **Cover identity**: a responder's public persona.
- **Callout**: a request to attend an incident; the unit of work.
  **Ping**: one callout offered to one responder.
- A ping is **taken**, **turned down**, or **missed** (no answer before the
  ping wait runs out). Turned-down and missed pings both move on to the
  next responder but are recorded separately.
- **Ping wait** (also "ping timeout"): one value for everyone, set per
  release.
- **Acceptance rate**: the share of pings taken. Dispatch's headline
  metric. **Time-to-accept**: the median seconds from ping to taken.
- **Coverage gap**: no available responder had the required tags. This is
  "nobody could go", which is not the same as a low acceptance rate.
- **Routing priority**: the score that decides who gets pinged first. Its
  inputs are proximity (a travel-time estimate), availability, capability
  match and recent acceptance history. Turning down or missing a ping
  lowers a responder's place for later callouts.
- **Capability tags**: flight, structural-entry, hazmat-tolerant,
  cold-weather, aquatic, crowd-management, de-escalation.
- **Responder Availability Record**: written by Dispatch, read by Supply
  for maintenance scheduling.
- **Mutual aid**: cross-area cover. Not supported; on the Q4 exploration
  list.

### The people (Dispatch team)
In the 4.2 release comments people sign by role. Mapped to names:

| Name | Role in comments | Location | What to go to them for |
| --- | --- | --- | --- |
| Helen Achebe | Director of Product (my director) | Site Aleph | Roadmap and commitments |
| Marcus Oyelaran | "Engineering manager" | Site Aleph | Runs Dispatch engineering. Direct; start here when unsure. Can pull rough numbers. |
| Wen Li | "Staff engineer" | Berlin | Built routing (who gets pinged). The only real source on how ranking works; there's no doc. Was away 14–24 Aug. |
| Sofia Marino | "Product designer" | Site Aleph | Console and phone app. Ran the September interviews. |
| Ravi Menon | (not in comments) | Singapore | Data analyst. Owns the official weekly acceptance numbers. |
| Nadia Hoffmann | "Support lead" | Berlin | Tickets. Hears handler pain first; Priya suggested a standing 15 minutes. |
| Priya Raghunathan | "Priya" | — | Former PM, left 21 Aug. Marcus has her number. |

Named customers in the wiki: handlers Aunt Dot (for Vesper), Mr. Ambrose
(Captain Vantage), Halloran (Sgt. Bulwark; a Supply-heavy user) and Kip
(Meteor Mite and The Gale).

### Release history
- **4.0** (7 Apr): new console navigation, responder profile redesign,
  audit log for routing overrides.
- **4.1** (16 Jun): proximity uses a travel-time estimate, bulk callout,
  more reliable push delivery to phones.
- **4.2** (12 Aug): proximity weighted up against recent acceptance
  history; ping wait cut from 90 to 60 seconds; console filters persist;
  three defect fixes.

### Where things stand (as of early Sep 2026)
**4.2 is the open issue.**
- Since 4.2, fewer pings are being taken and callout tickets are about 3x
  normal (Nadia, 18 Aug). The split is roughly two thirds "my phone never
  goes off" and one third "it was gone before I could answer". Nadia says
  the cut ping wait explains the second; she can't explain the first.
  Volume had leveled off but was still high on 26 Aug, and a handler
  emailed support directly.
- On 14 Aug Marcus asked whether the routing change was meant to apply to
  responders who have been turning jobs down, or whether it "just fell out
  that way". The config doesn't distinguish them. Wen said she'd look after
  the 24th. No answer is recorded.
- Priya's position (handoff and 19 Aug): the drop is mostly seasonal
  ("August is always soft") and will recover in September. Two changes
  shipped at once. Don't let this turn into a revert conversation.
- No official numbers yet. Marcus offered a rough trend; Ravi owns the real
  weekly numbers.
- Marcus plans to regroup on 4.2 about a week after I start (so around
  4 Sep). Nadia will bring the ticket breakdown.

**Q3 roadmap** (last reviewed 30 Jun; every item still lists Priya as
owner):
- Committed for 4.2: change to who gets pinged (shipped), ping timeout
  tuning (the 90→60 second cut shipped), and **Availability Confidence**,
  which is not in the 4.2 release notes. Priya says items were squeezed out
  of 4.2 and that I need to agree with Helen which are still Q3
  commitments. That conversation hasn't happened.
- Committed for 4.3: Requisition approval chains (Supply).
- Exploring for Q4: Handler phone app; Shared cover between responders.
- Changes to committed items go through Product, not directly to the team.

**Product briefs**
- Already shipped: *Routing Override Audit Log* (4.0) and *Bulk Callout*
  (4.1; its brief still says nobody picked it up).
- *Handler Phone App* (8 Sep): handler notifications, status view, one-tap
  contact. Sofia exploring for Q4; not staffed; no baseline metric.
- *Requisition Approval Chains* (Supply): a second sign-off over $2,000,
  plus scope creep added after "that's the whole ask". Phasing TBD.

**Things Priya left for me**
- There's no written description of how Dispatch decides who gets pinged.
  She asked me to write one (with Wen).
- Ignore the ticket noise from console filter persistence.
- She made fast calls as the only Dispatch PM for 14 months. The risk
  sits in the parts nobody has examined closely.

Module 1 notes:
- Not read yet: the Rook Dispatch and Rook Supply wiki pages, Research and
  the Customer interviews database (Sofia's September interviews), the
  handler pages, the roadmap item pages, the routing code in
  `00-rook/code/dispatch-routing/`, and the rook-database (the handlers
  table has 15 rows).
- Open: was the 4.2 routing change meant to cover responders who had been
  turning pings down (Marcus's 14 Aug question)? What happened to
  Availability Confidence? What do Ravi's official acceptance numbers show?
- Confirmed from code and data: a missed ping costs the same as a turn-down
  (−0.12; a taken ping is +0.08) and scores never recover (`history.py`).
  After the cut to a 60-second wait, misses jumped from 2–6 a week to 38.
  Six responders are pinged less (Farlight, The Undertow, Vesper and Meteor
  Mite down 65–74%; Ashgrove and Halfmoon down 16–19%), and the other ten
  went up.
- Callouts where nobody went doubled after 4.2 (5.5% to 11.1%). A turn-down
  passes a callout on in a median of 22 seconds; a miss takes the full wait.
  The week of 3 Aug (pre-release) was the best in the data, so it doesn't
  show a soft August.
- Support tickets: 42% of the 107 since 4.2 are ping problems. Handlers say
  availability is fine on their side. "Phone buzzed, by the time i unlocked
  it, gone" suggests late push delivery: the countdown starts when the ping
  is sent, not when it reaches the phone. Unconfirmed.
- Wrote `missed-ping-requirements.md` (v0.2, R1–R9): recovery over time,
  turn-down never costs more than a miss, alert the handler after 3 misses,
  reset the six, record delivered and answered times, start the countdown
  on delivery, and an interim support reply. Next: review it with Marcus,
  Wen and Helen.

Module 2 notes:
- Interviews (4, Sofia, 2–5 Sep): callouts gone before the responder could
  answer (3 of 4), handler not told a callout is live (3 of 4), quiet weeks
  and overload (2 of 4), small status text (2 of 4). Interviews blame the time
  to physically reach the phone ("coat on, one boot on"); tickets suggest late
  delivery ("by the time i unlocked it, gone"). R6 will tell them apart.
- All 147 tickets fall into ten groups. None of the 46 ping tickets is closed.
  The interviewees' responders have just 1 ticket between them, and Vesper and
  Meteor Mite (down 65%) have none, so ticket volume undercounts the worst hit.
  Overload has zero tickets. Supply is the second-biggest group (26 tickets).
- Root cause: `dispatch()` scores a miss as a refusal (−0.12 vs +0.08 for a
  yes) and scores never recover, so the 4.2 cut to 60 seconds demoted
  responders permanently. Not the ranking weights (acceptance weight went
  down). Unproven until Wen replays the June–September pings.
- Ranking algorithm: score = 0.60 × proximity (1 − minutes/45) + 0.25 ×
  acceptance + 0.15 × capability match. Responders are offered one at a time
  until someone takes the callout.
- `missed-ping-requirements.md` is now v0.6: R1–R26, each with a type, an
  S1–S4 severity and a P0–P3 priority. P0 is R2, R1, R26, R5, R19, R6 and R3,
  plus R9 this week. The R1 replay is a release gate.
- Open: does a ping go to the phone number on file or to a signed-in device
  (decides R19)? Does routing use the out-of-date map? Interview the heaviest
  ticket filers next: Linda Pruitt (Farlight) and Desmond Okafor (The Undertow).

Module 3 notes:
- Pings table, weekly: acceptance ~77% before 4.2 → 46.8% (12–16 Aug), 65.8%,
  66.7%, 72.7%. Misses 2–6/week → 37 in the first five days, then 28, 24, 21.
  Turn-downs barely moved. Pings per callout rose 1.22 → 1.30.
- Callouts coming in fell ~12% from release day itself (Wed 12 Aug: 12, vs 27
  the Wed before), across 14 of 15 areas; every callout still gets pinged.
  v0.6 doesn't cover this. Suspect: 4.2 filter persistence (R16, now P2), if
  handlers raise callouts from the console. Ask Marcus where callouts come from.
- Fewer callouts skews raw-count thresholds: R5's −10% (Ashgrove −22%, Halfmoon
  −19% are close to the ~12% volume drop) and R7's flag. Use share of pings.
- Tickets vs pings: both jump on 12 Aug. New ping complaints stopped by 31 Aug;
  the rest are repeats from handlers of stuck responders (Okafor, Pruitt, Demir,
  Fischer), all still open. Ticket growth after that is mostly non-ping topics,
  and Support closed none in the week of 31 Aug.
- The Undertow (Okafor's only responder): ~12 pings/week before; 5 misses in the
  first three days of 4.2, then 4, 1, 1 pings a week, the last two both missed.
- One number for Helen: missed pings ~4/week → 37 in the first five days.

Module 4 notes:
- Code (`00-rook/code/dispatch-routing/`): only a yes (+0.08) raises a score;
  no/miss −0.12; no time recovery, no reset. Pings go to the signed-in device, so
  R19 → P2. Scores sit in memory (`_scores = {}`); tags don't filter who's asked.
  Callouts arrive already made. 4.2 weights apply to everyone, scores carried over.
- `missed-ping-requirements.md` is v0.7: code-checked; R19 P2, R16 may rise, R5/R7
  use share of pings, R20/R21 need Supply sign-off; open questions 14–18 added
  (scores storage, untagged asks, callout source, pings writer, Marcus's 14 Aug).
- Replay of the code's scoring: everyone was 0.80–1.00 on 11 Aug, so prior
  turn-downs didn't decide who was hurt. The four hit 0; Ashgrove/Halfmoon
  recovered. The four missed 53–64% of post-4.2 pings vs 10–18% for others.
- Every turn-down takes ≤40 s, so the 60 s cut lost ~1 in 5 yeses. No ranking
  model fixes that. The four fit a "steady" profile: yes in ~66 s, reliable at 90.
- `04-x-ray-vision/ping_sim.py`: calibrated simulation. Rewarding in-time answers
  plus recovery fixes fairness but not unfilled callouts at 60 s; adding "a late
  yes within 30 s still counts" (design C) matches 90 s. Not yet in the doc.

Module 5 notes:
- Fresh re-check: 4.2 made nearest-first worse. Local share of pings fell in Old Town
  83%→16%, Uptown 76%→11%, Harborside 81%→20%. 42 callouts before 4.2 and 40 after
  ended after one ping with nobody else asked. Callouts coming in fell ~15% from
  release day in 14 of 15 areas (only Southport flat); unexplained.
- Student's rules: keep 4.2's goals (nearest first, 60 s hand-off). No fix may keep a
  ping open past 60 s, so no 90 s rollback and no countdown-from-delivery. Check every
  idea against those goals and walk through what-if scenarios before suggesting it.
- Agreed scoring: "no" costs less than a miss (0.5 vs 1.0); release after accepting
  is worst (1.5, accept credit removed, handler can excuse). Score = rate over a
  time window (length is Helen's call; no 30-day requirement exists); floor 0.6
  (~3 min of travel); accepts ×3 while below the middle (~8 accepts back); out-of-area
  "no" not counted; 3 misses in a row → "still available?" pause, not a penalty.
- Deliverables: `dispatch-recovery-requirements.md` + `.docx` (DR-01–DR-32, JTBD,
  what-if W1–W38); `05-super-speed/Quiet-Responders-Director-Brief.docx` for Helen's
  request (`director-request.txt`); clickable walkthrough at
  `05-super-speed/prototype/index.html`. Old `brief.md` used bad assumptions.
- Student wants plain English for audiences (no "recompute", "floor", "interim").
  Open: Security Policy 4.1 isn't in the wiki (needed for lock-screen accept); Wen to
  confirm delivery receipts, why callouts stop after one ping, where scores are stored.

Module 6 notes:
- Built the `qa-testing` skill (`.claude/skills/qa-testing/SKILL.md`): brief + staging →
  acceptance criteria → student approves → tests in the browser → Word findings doc.
- First run: 108 criteria approved (96 testable, 12 not testable by the student's choice) in
  `qa/2026-11-07-dispatch-recovery/acceptance-criteria.md`, against the requirements doc and
  Helen's brief (13 promises). Tests NOT run yet; the student said "not yet".
- Decisions: excused release = no accept credit, no penalty; DR-19 alerts after 3 pings OR 3
  minutes; DR-06 merged into DR-11 (requirements now v1.1; prototype now 33 steps). A ping the
  phone never confirms moves on at 15 s and never counts. No "under 45 s left" rule.
- Only a review-checklist *output* exists (`06-sidekicks/scheduled-run-output.txt`: owner,
  success measure, bounded scope, problem before fix); no checklist definition or briefs folder.
