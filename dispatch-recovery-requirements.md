# Rook Dispatch: fixing 4.2's side effects without undoing 4.2

Requirements · Product, Dispatch · v1.0 · 7 November 2026
For: Helen Achebe (Director of Product), Marcus Oyelaran, Wen Li, Sofia Marino,
Ravi Menon, Nadia Hoffmann, Rook Supply

Supersedes `missed-ping-requirements.md` (v0.7) for planning. That draft was written
on earlier assumptions; this one is built from a fresh read of the wiki, Priya's
handoff, the four interviews, all 147 support tickets, the pings, callouts and
responders tables, and the routing code.

---

## 1. Purpose

Release 4.2 (12 Aug 2026) set out to fix real problems. It mostly didn't, and it
caused new ones. This document specifies what to build so that:

1. the problems 4.2 was solving **stay solved** (or get solved for the first time),
2. the damage 4.2 caused is repaired, and
3. the gaps nobody had looked at are covered.

Every requirement has been checked against the goals in section 2 and against
"what if" scenarios (how it could backfire). Options that failed those checks are
listed in section 8 with the reason, so they don't come back.

## 2. Goals that must stay solved, and constraints

| ID | Goal from 4.2 | Source | Test applied to every requirement | Measured by |
|---|---|---|---|---|
| **G1** | **Nearest first.** A nearby responder isn't skipped for someone further away with a better record. | Priya's handoff; 4.2 release note ("Long requested by responders who cover wide areas") | Does it make it more likely the nearest available responder is asked first? | Share of an area's pings going to its local responder |
| **G2** | **Faster hand-off.** "Pings that go unanswered move to the next responder sooner." | 4.2 release note | Does it reduce the time a callout waits on someone who isn't answering? | Time lost to unanswered pings; time to fill a callout |
| **G3** | **Filters persist.** Handlers stop rebuilding filters every session. | 4.2 release note; tickets 3005, 3012; Ambrose interview | Does it keep this working without new risk? | Filter-related tickets |

The three 4.2 defect fixes (duplicate pushes, tag ordering, export time zone) have
had no repeat tickets since 12 Aug and are out of scope.

| ID | Constraint | Source |
|---|---|---|
| **C1** | **No ping stays open longer than 60 seconds after it was sent.** No requirement may extend the wait for any responder. | 4.2 ping wait; Product decision in this review |
| **C2** | **Confidentiality.** Nothing may store, reveal or help reconstruct a link between a person and their responder role. | About Rook, "A note on confidentiality"; Glossary ("Cover identity"); Security Policy 4.1 (not in the wiki; must be obtained) |
| **C3** | **Supply contract.** Supply reads the Responder Availability Record and never writes to it; changes to it reach Supply's maintenance scheduling automatically. | Rook Supply one-pager; `availability.py` header |

## 3. What happened (evidence)

All figures from the rook-database unless marked. "Before" = 29 Jun – 11 Aug
(6.3 weeks); "after" = 12 Aug – 6 Sep (3.7 weeks).

| # | Finding | Evidence |
|---|---|---|
| E1 | **4.2 made G1 worse in three areas.** Callouts there now mostly go to responders from other areas. | Local responder's share of the area's pings: Old Town 83% → 16%, Uptown 76% → 11%, Harborside 81% → 20% |
| E2 | **Four responders were frozen out.** | Pings a week: Vesper 13.7 → 4.6, Farlight 11.9 → 3.0, The Undertow 11.9 → 3.8, Meteor Mite 11.1 → 3.8 |
| E3 | **Misses rose sharply after the 60-second cut.** | Misses: 2–6 a week before, 38 in release week, about 30 a week after. Time lost to misses: about 6 min/week → about 30 min/week. Every turn-down came within 40 s (median 22 s). |
| E4 | **The score punishes a miss like a "no" and never recovers.** | `history.py`: a miss and a "no" both cost 0.12, a yes earns 0.08, no decay (2019 TODO). Expected change per ping for Vesper after 4.2: 0.3 × 0.08 − 0.7 × 0.12 = −0.06. She keeps sinking. |
| E5 | **Ranking is effectively selection.** | About 1.3 pings per callout; the first-ranked responder almost always gets it. A score of 0 vs 1.0 is worth about 19 minutes of travel (0.25 ÷ (0.60 ÷ 45)). |
| E6 | **The 4.2 weights are not the cause.** | 4.2 cut the acceptance weight 0.40 → 0.25 (`config.py`). Under these weights a responder 5 min away always beats one 40 min away. The score collapse (E4) is what overrode proximity. |
| E7 | **Unfilled callouts doubled.** | 5.5% (48 of 879) → 11.1% (49 of 440). Callouts that ended after a single ping with nobody else asked: 42 before, 40 after; 21 of those 40 ended on a single miss. The code says it works down the whole list. |
| E8 | **Work shifted onto neighbours.** | Pings a week: The Gale 13.0 → 18.6, Nightwell 15.1 → 18.9, Stormwrack 13.0 → 17.0, Falkirk 10.0 → 14.1. Kip: "Mite thinks Mite's been forgotten. Gale's exhausted." |
| E9 | **"Gone before I could answer."** | 3 of 4 interviews (Dot, Ambrose, Halloran). 13 of 45 post-4.2 ping tickets. "phone buzzed, by the time i unlocked it, gone." The countdown starts when the ping is sent, not when it arrives (`offer.py`). |
| E10 | **Handlers aren't told a callout is live, and can't see why a responder went quiet.** | Dot and Ambrose (2 of 4). 32 of 45 ping tickets say the phone has gone quiet; many say "I have checked her availability and everything is set to available." Availability Confidence (committed for 4.2) didn't ship. |
| E11 | **Filter persistence has new bugs.** | Silent resets after updates (3044, 3064, 3072, 3134), wrong user's filters on shared computers (3046, 3115), not across computers (3042, 3085), no "clear all" (3066, 3076), easy-to-miss badge (3061, 3124). Ambrose watched the wrong filter for 15 minutes. |
| E12 | **Pre-4.2 seasonality isn't supported.** | The week of 3 Aug was the best in the data (77.9% acceptance). The drop starts on release day. |
| E13 | **Headline metric hides the harm.** | Acceptance recovered to 72.7% partly because the system stopped asking the four. |
| E14 | **Tickets undercount the worst hit.** | 45 ping tickets since 4.2, all open. Vesper's and Meteor Mite's handlers filed none. |
| E15 | **Callouts coming in fell about 15% from release day,** in 14 of 15 areas. Unexplained. | 139.5 → 119 a week |
| E16 | **Scores live in memory.** | `history.py`: `_scores = {}`. A deploy may reset everyone to 0.5. Unconfirmed. |
| E17 | **Capability counts for little.** | Capability weight 0.15 ≈ 11 minutes of travel. A nearer responder without the needed tag outranks a qualified one 12 minutes further away. Tags are incomplete (ticket 3024). |
| E18 | **Not recorded:** delivery time, answer time, arrival, release after accepting. | `pings` table has only `sent_at` and outcome. |

## 4. Who this is for

| Person | Who they are here | What they need |
|---|---|---|
| **Responder** | Takes callouts on their phone (Vesper, Farlight, The Undertow, Meteor Mite, The Gale…) | A fair chance at callouts near them, time to answer, and a way back after a bad stretch |
| **Handler** | Runs the console for one or a few responders (Aunt Dot, Mr. Ambrose, Kip, Halloran, Linda Pruitt, Desmond Okafor…) | To know when a callout is live, why their responder is quiet, and to trust what the console shows |
| **Support lead** (Nadia) | Owns tickets | An honest answer to give handlers |
| **Data analyst** (Ravi) | Owns the weekly numbers | Metrics that show harm, not hide it |
| **Director** (Helen) | Owns commitments | A fix that keeps 4.2's goals and can be explained |
| **Supply** | Reads the availability record | No surprise changes to it |

## 5. Scoring model (the numbers behind section 6)

These are **proposed values**, to be confirmed by Wen and tested by the replay
(DR-28). Values marked **Decision** belong to Helen.

**Score** = weighted acceptance rate over a time window, used as the 0.25-weight
"recent acceptance" input to ranking.

```
score = (accept credits + 0.75 × 5) ÷ (accept credits + 0.5 × quick no's
         + 1.0 × counted misses + 1.5 × releases + 5)
```

| Input | Value | Why |
|---|---|---|
| Accept | 1 credit; **3 credits while the responder is below the middle** (median of all active responders' scores) | Recovery boost (DR-04) |
| Quick "no" | 0.5 against | Cheaper than a miss, so declining beats ignoring (DR-01) |
| Delivered miss | 1.0 against | Holds the callout the full 60 s |
| Release after accepting | 1.5 against, **and the accept's credit (including any boost) is removed** | Faking an accept always costs more than declining (DR-07) |
| Not counted | Declines for callouts outside home area or beyond 45 min; undelivered pings; pings delivered with under 45 s left; excused releases | DR-05, DR-06, DR-07 |
| Starting point | As if 5 pings at 0.75 (pre-4.2 average acceptance was 77%) | A responder with no recent pings sits at 0.75 |
| Window | **Time-based.** Length is a **Decision**: no requirement exists. Options: 3 days (earlier draft R1), 14 days, 30 days. | A count-based window never moves for someone who gets no pings |
| Floor | **0.6** for ranking (**Decision**) | A bad record costs at most about 3 minutes of travel vs a typical responder (0.77) |

**Worked numbers (post-4.2 records, every miss assumed delivered):**

| Responder | Score after recompute | Ranked at | Accepts in a row back to the middle (0.73) |
|---|---|---|---|
| Farlight | 0.38 | 0.60 (floor) | 19 without boost · **7 with 3× boost** |
| Meteor Mite | 0.39 | 0.60 | 22 · **8** |
| Vesper | 0.43 | 0.60 | 23 · **8** |
| The Undertow | 0.38 | 0.60 | 24 · **8** |
| *The Gale (typical)* | 0.77 | 0.77 | – |

A typical responder before 4.2 had about 11 pings and 8 accepts a week, so the
boost returns a responder to the middle in **about one normal week**. Under
today's rules they never return (E4).

## 6. Requirements

Format for each: problem → job to be done → requirement → acceptance criteria →
goal check → what-if checks. Priority: **P0** must ship in the first release;
**P1** next; **P2** later. Release groups are in section 9.

### A. Scoring

#### DR-01 Answer ordering: a "no" costs less than a miss · P0
- **Problem:** A miss and a "no" both cost 0.12 (E4). A responder who can't go gains nothing by tapping "no", so there's no reason to answer quickly. Honest local decliners sink as fast as non-answerers.
- **Job to be done:** *When a callout comes in that I can't take, I want saying "no" to be clearly better than ignoring it, so I pass it on fast without losing my place.*
- **Requirement:** Outcomes are weighted yes > quick "no" > miss > release after accepting (section 5). The gap is made by **lowering the "no" weight**, not by raising the miss weight.
- **Acceptance criteria:**
  - A build check fails if the weights don't satisfy: release ≥ miss > "no" > 0.
  - The miss weight is no heavier than today's equivalent.
  - In the replay (DR-28), a responder with 10 "no"s ranks above an otherwise identical responder with 10 misses.
- **Goal check:** G1 ✅ honest local decliners keep their place · G2 ✅ declining is rewarded over timing out · C1 ✅
- **What-if checks:**
  - *Responders tap yes to avoid any penalty, then don't go* → DR-07 makes a fake yes the costliest outcome.
  - *A habitual decliner stays at the top because "no" is cheap and adds ~20 s to every local callout* → DR-10 decline streak triggers an availability check.
  - *Raising the miss penalty instead* → rejected: lets history override proximity more (fails G1).

#### DR-02 Score is a rate over a time window · P0
- **Problem:** The score is a running total that only moves when someone is pinged (E4). A low-ranked responder is rarely pinged, so they can't climb back.
- **Job to be done:** *When I've had a bad stretch, I want it to stop counting against me after a while, so one bad week doesn't cost me a month of work.*
- **Requirement:** Replace the running total with the weighted rate in section 5, over a **time-based** window. Old outcomes drop out with time, even with no new pings.
- **Acceptance criteria:**
  - A responder with no pings returns to 0.75 once all old outcomes leave the window.
  - The window length is a single config value.
  - A count-based window ("last N pings") is not allowed.
  - Responders with few pings are blended toward 0.75 (the 5-ping starting point), so one miss in two pings doesn't read as 50%.
- **Goal check:** G1 ✅ · G2 ➖ · C1 ✅
- **What-if checks:**
  - *Window by count instead of time* → a frozen-out responder's window never moves. Forbidden above.
  - *Switching formulas re-ranks everyone at once, a second 4.2-style shock* → DR-08 recompute + DR-28 replay and shadow run before switching on.
  - *Window too short makes rankings jumpy; too long makes recovery slow* → length is a Helen decision informed by the replay; DR-04 makes recovery depend less on it.

#### DR-03 Floor on the score · P0
- **Problem:** A score of 0 is worth about 19 minutes of travel (E5). A responder at zero loses their own area to neighbours. That is the problem 4.2 was meant to fix.
- **Job to be done:** *When my score is low, I want to still be asked for callouts right next to me, so a bad record never hands my area to someone further away.*
- **Requirement:** Ranking uses max(score, floor). Proposed floor 0.6. The floor is expressed to Helen as "a bad record can cost at most N minutes of travel": about 3 minutes against a typical responder at 0.77.
- **Acceptance criteria:**
  - No responder is ranked with a recent-acceptance input below the floor.
  - In the replay, Old Town, Uptown and Harborside each return to ≥ 76% of pings going to the local responder.
- **Goal check:** G1 ✅ directly delivers 4.2's stated intent · G2 ➖ alone, ✅ with DR-10 · C1 ✅
- **What-if checks:**
  - *The floor keeps a chronic non-answerer near the top, so their area loses 60 s per callout* → DR-10 streak check pauses genuinely unresponsive responders. The floor protects against rule changes; the streak handles behaviour.

#### DR-04 Recovery boost · P0
- **Problem:** Under a plain rate, accepts barely move a low score. It takes 19–24 accepts in a row (about 3 weeks) to reach the middle; time does the work, not the responder.
- **Job to be done:** *When I've been pushed to the bottom, I want my accepts to visibly count, so I can work my way back in about a week instead of waiting it out.*
- **Requirement:** While a responder's score is below the middle (median of active responders), each accept earns 3 credits. Once they reach the middle, accepts earn 1.
- **Acceptance criteria:**
  - In the replay, each of the four reaches the middle within 7–8 accepts in a row.
  - The boost stops at the middle.
  - Misses and "no"s are unaffected by the boost.
- **Goal check:** G1 ✅ locals win their areas back within about a week · G2 ✅ misses still cost the same · C1 ✅
- **What-if checks:**
  - *Raise accept credit for everyone instead* → rejected: shrinks the gap between reliable and unreliable for everyone (weakens G2) and strengthens the fake-yes incentive.
  - *Fake accepts to climb faster* → DR-07 removes the boosted credit and adds the biggest penalty, so faking always loses.
  - *Climb, then relapse* → DR-10 streak check.
  - *Sink on purpose to earn the boost* → no gain: they lose work while down and the boost stops at the middle.

#### DR-05 No penalty for declining out-of-area callouts · P0
- **Problem:** Neighbours are asked about callouts outside their area (E1, E8). Declining sensibly costs them standing in their own area.
- **Job to be done:** *When I'm asked to cover a callout far from my area, I want to be able to say no without it hurting me at home, so I stay first for callouts near me.*
- **Requirement:** A "no" for a callout outside the responder's home area, or beyond the 45-minute proximity limit, is not counted. Misses on those pings still count (they still hold the callout).
- **Acceptance criteria:**
  - Score is unchanged after an out-of-area or beyond-45-minute decline.
  - Out-of-area misses still count.
- **Goal check:** G1 ✅ · G2 ✅ declining stays the fast option · C1 ✅
- **What-if checks:**
  - *Neighbours start declining every out-of-area callout, so coverage drops in the four areas* → once DR-03/DR-08 restore the local responders, fewer out-of-area pings are sent at all. Unfilled rate is a guardrail (DR-27).

#### DR-06 Only count misses the responder could have answered · P0 · depends on delivery receipts
- **Problem:** The countdown starts at send (E9). Late or failed delivery is charged to the responder as a miss.
- **Job to be done:** *When my phone gets the ping late or not at all, I want that not to count against me, so I'm not punished for the network.*
- **Requirement:** A miss counts only if the phone confirmed delivery with at least 45 seconds left. Undelivered pings and late deliveries are recorded but not counted.
- **Acceptance criteria:**
  - Delivery time is recorded for every ping (DR-26).
  - Misses delivered with under 45 s left don't change the score.
  - Wen confirms phones can report delivery reliably on supported devices, including older phones (ticket 3034).
- **Goal check:** G1 ✅ · G2 ➖ · C1 ✅ no time added
- **What-if checks:**
  - *Responders switch delivery off to dodge penalties* → DR-11 marks repeated undelivered pings as "unreachable".
  - *Delivery reports are unreliable on some phones, so real misses go uncounted* → measure report reliability before switching this rule on.

#### DR-07 Release after accepting is the costliest outcome · P0
- **Problem:** With "no" cheaper and accepts boosted, the cheapest move could be a fake yes. Nothing records a responder who accepts and doesn't go (E18).
- **Job to be done:** *As a handler, when my responder accepts a callout, I want to trust that they're going, so the incident isn't left waiting on a fake yes.*
- **Requirement:**
  - Add the outcome "released after accepting". It removes the accept's credit (including any boost) and counts 1.5 against.
  - A handler reassigning a taken callout to someone else counts as a release (overrides are already logged, since 4.0).
  - Responders can mark "on scene".
  - A handler can mark a release excused, with a reason (logged); excused releases cost nothing.
- **Acceptance criteria:**
  - A release always leaves the score lower than an honest "no" would have, including during the boost.
  - Releases, arrivals and excuse reasons are stored.
  - A released callout goes straight back out.
- **Goal check:** G1 ✅ points can't be farmed to displace nearer responders · G2 ✅ callouts don't stall on a fake yes · C1 ✅
- **What-if checks:**
  - *A responder accepts in good faith and has to drop out (gear failure on the way)* → handler marks it excused.
  - *Handlers excuse everything* → excuse rate per handler is visible to Support; review if it is out of line.

#### DR-08 Recompute everyone at switchover · P0
- **Problem:** A hand-picked reset of four responders is a special case: it gives any chronic decliner who was legitimately low a free pass, and under today's rules the four would fall back to zero within days.
- **Job to be done:** *When the scoring rules change, I want everyone judged by the same new rules from day one, so nobody is helped or hurt by being on a list.*
- **Requirement:** At release, recompute every responder's score from their ping history under the new rules. Ship in the same release as DR-01 to DR-07 and DR-09, never before.
- **Acceptance criteria:**
  - Every active responder has a recomputed score at switch-on.
  - The four start at the floor (0.6) or above.
  - All affected handlers are told in advance, including the neighbours' handlers, who will see fewer pings.
- **Goal check:** G1 ✅ · G2 ➖ · C1 ✅
- **What-if checks:**
  - *The Gale, Nightwell, Stormwrack and Falkirk drop in pings and their handlers think something broke* → advance notice: it's the intended return to nearest-first.
  - *Past misses can't be tested for late delivery (not recorded)* → recompute assumes every past miss counts; the floor and boost cover this.

#### DR-09 Store scores so they survive a deploy · P0
- **Problem:** Scores sit in memory (E16). A deploy may silently reset everyone, so standing is inconsistent.
- **Job to be done:** *As an engineer, when we deploy, I want scores to persist, so ranking doesn't change for reasons nobody can see.*
- **Requirement:** Store scores durably. **Only ship together with DR-02** (recovery).
- **Acceptance criteria:**
  - Scores are identical before and after a restart.
  - Wen confirms where scores are kept today.
- **Goal check:** correctness; G1/G2 ➖
- **What-if checks:**
  - *Persisting under today's rules makes freeze-outs permanent; a deploy reset has been accidental relief* → only with DR-02.

### B. Availability and reachability

#### DR-10 Streak check → confirm availability · P0
- **Problem:** The floor (DR-03) and cheap "no" (DR-01) could keep a non-answering or always-declining responder at the top, costing their area time on every callout.
- **Job to be done:** *As a handler, when my responder has stopped answering, I want to be told and to have them paused until they confirm, so callouts near them aren't stalled and they aren't buried for weeks.*
- **Requirement:**
  - After 3 delivered misses in a row, or 5 "no"s in a row (proposed thresholds), the responder is asked to confirm they're available and their handler is alerted.
  - If nobody confirms, routing treats them as unavailable until the responder or handler confirms with one tap.
  - This is an availability state, not a score penalty.
- **Acceptance criteria:**
  - The pause clears with one tap.
  - The handler alert names the reason.
  - The pause is **not** written to the shared availability record without Supply's sign-off (DR-29).
- **Goal check:** G1 ✅ no long penalty · G2 ✅ unresponsive responders stop holding callouts · C1 ✅ · C3 ✅
- **What-if checks:**
  - *Paused while genuinely busy for an evening* → one tap to return; the alert says so.
  - *Supply books maintenance into a "paused" window it reads as quiet* → keep the pause Dispatch-only unless Supply signs off.

#### DR-11 Undelivered pings move on early; repeated non-delivery → "unreachable" · P0
- **Problem:** An undelivered ping holds the callout for the full 60 s for nothing (E3, E9).
- **Job to be done:** *When a responder's phone can't be reached, I want the callout to move on quickly, so the incident doesn't wait on a dead phone.*
- **Requirement:**
  - With no delivery receipt within 15 seconds, the callout moves to the next responder, with no penalty.
  - Two undelivered pings in a row mark the responder "unreachable" until the app checks in; the handler is alerted.
  - A late-arriving push for a ping that has moved on is withdrawn, or shown as "already covered".
- **Acceptance criteria:**
  - No ping waits longer than 15 s without a delivery receipt.
  - A withdrawn ping never shows as live.
- **Goal check:** G1 ➖ · G2 ✅ 15 s instead of 60 · C1 ✅ shorter, never longer
- **What-if checks:**
  - *Delivery switched off to dodge penalties* → "unreachable" state.
  - *Ping arrives at second 16 after moving on, so the responder sees a vanished ping* → withdraw or "already covered".

### C. Answering inside 60 seconds

#### DR-12 Hard 60-second limit · P0
- **Problem:** Earlier options (90 s rollback, countdown from delivery) would have extended the wait.
- **Job to be done:** *When a callout is live, I want every ping to close within 60 seconds of being sent, so hand-offs stay as fast as 4.2 made them.*
- **Requirement:** Every ping closes no later than 60 s after it is sent. No feature may extend this for any responder.
- **Acceptance criteria:** An automated check verifies no ping in production exceeds 60 s from send to close.
- **Goal check:** G2 ✅ · C1 ✅

#### DR-13 Answer from the lock screen, without exposing anyone · P1 · blocked on Security Policy 4.1 review
- **Problem:** "phone buzzed, by the time i unlocked it, gone" (E9). Unlocking eats the 60 seconds.
- **Job to be done:** *When my phone buzzes and I'm halfway into the suit, I want to answer without unlocking, so I don't lose a callout I wanted.*
- **Requirement:**
  - Accept and decline from the notification.
  - **Accept requires fingerprint or face.**
  - Lock-screen text is generic ("New request: respond"): no incident details, no cover name, no Rook branding.
- **Acceptance criteria:**
  - A bystander can't accept or read callout details from the lock screen.
  - Security Policy 4.1 reviewed and signed off before build.
- **Goal check:** G1 ✅ nearby responder answers in time · G2 ✅ fewer timeouts · C1 ✅ · C2 ✅ with generic text
- **What-if checks:**
  - *A lock-screen alert reveals to a bystander (Dot's kitchen counter) that the phone's owner is a responder* → generic text, no branding.
  - *Someone else taps "decline"* → low harm (cheap "no"), and DR-17 lets the responder change it to accept within 5 s.

#### DR-14 Hard-to-miss alert · P1
- **Problem:** "Coat on, one boot on" (Ambrose); the phone upstairs (Dot).
- **Job to be done:** *When a callout comes in and I'm not holding my phone, I want to notice it immediately, so I have the full 60 seconds.*
- **Requirement:** Full-screen alert, optional sound that breaks through silent mode, and a buzz on a paired watch. Off by default; the responder chooses when it's on.
- **Acceptance criteria:**
  - Breaking through silent mode is opt-in and can be scheduled.
  - Watch content is as generic as the lock screen.
- **Goal check:** G1 ✅ · G2 ✅ · C1 ✅ · C2 ✅
- **What-if checks:**
  - *A loud alert in a covert situation exposes the responder* → opt-in only, never default.

#### DR-15 Countdown on the alert · P1
- **Problem:** Responders can't tell how much of the 60 seconds is left.
- **Job to be done:** *When I see a ping, I want to know how long I have, so I either go for it or decline straight away.*
- **Requirement:** The alert shows seconds remaining.
- **Acceptance criteria:** The countdown matches the server's 60 s limit to within 2 s.
- **Goal check:** G2 ✅ encourages quick declines · C1 ✅

#### DR-16 Reliable, fast delivery · P1
- **Problem:** Late and failed delivery (E9; ticket 3034, older phones). The retry code shown in review retries instantly with no protection against duplicates, and 4.2's duplicate-push fix may have switched resends off.
- **Job to be done:** *When I'm pinged, I want the ping to arrive at once, exactly once, so I have the full time to answer.*
- **Requirement:**
  - Use the high-priority push channel.
  - Retry within the 60 s using a duplicate-proof ping ID, so a retry never shows twice.
- **Acceptance criteria:**
  - Median delivery time and delivery failure rate are reported weekly (DR-26).
  - No duplicate pings shown.
  - Wen confirms how 4.2's duplicate fix interacts with resends.
- **Goal check:** G1 ✅ · G2 ✅ · C1 ✅

#### DR-17 Mis-tap protection: change a "no" to accept within 5 seconds · P1
- **Problem:** The Drift tapped "no" by mistake and lost the job (ticket 3033).
- **Job to be done:** *When I hit "no" by accident, I want to take it back straight away, so a slip doesn't cost me the callout.*
- **Requirement:**
  - Decline and accept are physically separated (or decline is a swipe).
  - A "no" passes the callout on **immediately**. For 5 seconds the responder can change it to accept: they take the callout, the next responder's ping is withdrawn, and that ping doesn't count against them.
- **Acceptance criteria:**
  - A "no" never delays the hand-off.
  - Undo only converts to accept; it can't erase a "no" without taking the job.
- **Goal check:** G1 ✅ the nearer responder gets it back · G2 ✅ no delay · C1 ✅
- **What-if checks:**
  - *A "cancel decline" button would let people erase every "no"* → rejected; undo only converts to accept.
  - *A 5-second hold on every "no" before passing it on* → rejected; slows every hand-off (fails G2).

### D. Routing

#### DR-18 Keep 4.2's ranking weights · P0
- **Problem:** The weights aren't the cause (E6); reverting them would bring back the original complaint.
- **Job to be done:** *As a responder covering a wide area, when something happens near me, I want to be asked before someone far away, so the nearest person goes.*
- **Requirement:** Keep proximity 0.60, recent acceptance 0.25, capability 0.15.
- **Acceptance criteria:** No weight change in this release. Weight changes in future need the DR-28 replay.
- **Goal check:** G1 ✅

#### DR-19 Keep working down the list; escalate to the handler · P0 · Wen to explain the current stop
- **Problem:** 40 callouts since 4.2 (42 before) ended after a single ping with nobody else asked (E7). The code says it works down the whole list.
- **Job to be done:** *When the first responder doesn't take a callout, I want it offered to the next, so the incident isn't left with nobody.*
- **Requirement:**
  - Continue down the ranked list until someone accepts.
  - After 3 pings or 3 minutes with no yes (proposed), alert the handler, who can override (overrides are logged).
- **Acceptance criteria:**
  - No callout ends unfilled while an available responder hasn't been asked.
  - In the replay, the unfilled rate is ≤ 5.5%.
  - Wen documents why callouts stop today.
- **Goal check:** G1 ➖ ranking order unchanged · G2 ✅ · C1 ✅
- **What-if checks:**
  - *The callout cycles through far responders for minutes* → handler escalation.
  - *Far responders get more pings they'll decline* → DR-05.
  - *The early stop is deliberate (e.g., only one responder available)* → confirm with Wen before changing.

#### DR-20 Nearest *capable* responder · P1 (phase 1), P2 (phase 2)
- **Problem:** Capability is worth only about 11 minutes (E17), so nearest-first can send someone who can't do the job. Tags are incomplete.
- **Job to be done:** *When an incident needs a specific skill, I want the nearest responder who has it, so the person who arrives can actually help.*
- **Requirement:**
  - Phase 1: handlers can add and edit capability tags (ticket 3024), and tag data is cleaned up.
  - Phase 2: required tags become a filter.
- **Acceptance criteria:**
  - Phase 1: handlers can edit tags.
  - Mismatched assignments are measured.
  - Phase 2 only ships once tag completeness is confirmed.
- **Goal check:** G1 ✅ as originally meant
- **What-if checks:**
  - *Hard filter on incomplete tags excludes capable people and creates gaps* → phase order.

#### DR-21 Overlapping offers · P2, deferred
- **Problem:** When the first responder doesn't answer, the next isn't asked until 60 s.
- **Job to be done:** *When the first responder isn't answering, I want the next lined up, so the callout is covered sooner without taking it from the nearer person.*
- **Requirement:**
  - At 45 s the next responder is pinged. The first keeps priority until their 60 s ends.
  - If the second says yes, they're told "you're next, confirming shortly". If the first says yes before 60 s, the first gets it; otherwise the second is confirmed at 60 s.
  - Each ping still closes ≤ 60 s from its own send.
- **Acceptance criteria:**
  - Only built once delivery and answer times (DR-26) show time is lost to genuine non-answers.
  - A stand-by ping never counts against the second responder.
  - No lining-up during bulk callouts.
- **Goal check:** G1 ✅ first keeps priority · G2 ✅ about 20 s sooner · C1 ✅
- **What-if checks:**
  - *"First yes wins"* → rejected: a further, faster responder beats the nearer one (fails G1).
  - *The second responder starts suiting up and loses* → no penalty, and they're told plainly.
  - *The reserved responder can't take a second callout happening at the same time* → not during bulk callouts; measure.

#### DR-22 Monitor load; no cap · P1
- **Problem:** Neighbours were overloaded (E8).
- **Job to be done:** *As a handler of a busy responder, when their load jumps, I want it noticed, so it isn't left to me to spot burnout.*
- **Requirement:** Report each responder's weekly pings against their own usual (DR-27). No cap on load.
- **Acceptance criteria:** Weekly report flags any responder more than 30% above their usual.
- **Goal check:** G1 ✅ (a cap would fail it)
- **What-if checks:**
  - *Cap the load* → rejected: pushes callouts away from the nearest responder. The Gale is the nearest in Eastgate. The overload came from Meteor Mite's freeze-out, which DR-01 to DR-08 fix.

### E. Handlers and responders

#### DR-23 Tell the handler when their responder is pinged · P1
- **Problem:** Handlers don't know a callout is live (E10). Dot: "I'm not relying on hearing a buzz through a ceiling."
- **Job to be done:** *When a callout goes to my responder, I want to know at the same moment, so I can get them to the phone in time.*
- **Requirement:**
  - The handler is notified when the ping is sent.
  - Each responder gets a different sound (Kip's request).
  - Notification only: no accept button.
  - Minimal content, per C2.
- **Acceptance criteria:**
  - The handler notification goes out within 2 s of the ping.
  - The handler can't accept on the responder's behalf.
- **Goal check:** G1 ✅ · G2 ✅ fewer timeouts · C1 ✅ · C2 ✅
- **What-if checks:**
  - *Alert fatigue for busy responders' handlers* → per-responder sounds; handler can mute per responder.
  - *Handler accepts for an unready responder, who then doesn't show* → no accept button.
  - *Incident details on the handler's lock screen* → minimal content.

#### DR-24 Standing in plain words · P1
- **Problem:** Handlers see "available" and can't see why their responder is quiet (E10). Kip: "I just want it to look less like a coincidence." Responders ask whether they're "still even in the system". Availability Confidence (committed for 4.2) didn't ship.
- **Job to be done:** *When my responder (or I, as the responder) has gone quiet, I want to see why and when it ends, so I know nothing is broken and what gets them back.*
- **Requirement:**
  - Show the responder **and their handler only** a plain-language status, for example "Lower priority: 3 recent misses. Back to normal in about a week of normal work, or by 21 Nov."
  - No number is shown.
  - This replaces Availability Confidence on the roadmap.
- **Acceptance criteria:**
  - Status is shown only to the responder and their handler.
  - It updates within an hour of any change.
  - It never shows other responders' standing.
- **Goal check:** G1 ➖ · G2 ➖ · trust ✅ · C2 ✅
- **What-if checks:**
  - *A visible number becomes a target and handlers push yeses* → words, not numbers; DR-07 makes fake yeses costly.
  - *Seeing others' standing* → own responder only.

#### DR-25 Finish filter persistence safely · P0 (safety rule), P1 (rest)
- **Problem:** Filter persistence brought new bugs (E11), and a filter can hide a live callout from the handler.
- **Job to be done:** *When I open the console, I want my own filters, and I want to be sure they're not hiding anything about my responder, so I can trust what I see.*
- **Requirement:**
  - **P0:** a filter never hides a callout or ping involving the handler's own responder.
  - Warn when filters reset, and fix why updates wipe them.
  - Separate sign-ins for covering handlers (tickets 3053, 3141), and filters per person, stored on the server across computers.
  - "Clear all".
  - A prominent "filter on" badge.
- **Acceptance criteria:**
  - No filter hides the handler's own responder.
  - No silent resets.
  - Two people sharing a computer see their own filters.
  - Filter tickets fall to zero within a month.
- **Goal check:** G3 ✅
- **What-if checks:**
  - *Per-user filters don't help two people sharing one sign-in* → separate sign-ins first or together.
  - *Warnings fire constantly* → fix the reset cause; the warning is the safety net.
  - *"Clear all" pressed by accident* → minor; one tap to restore last set.

### F. Measurement and release safety

#### DR-26 Record what happens to each ping · P0
- **Problem:** No delivery, answer, arrival or release data (E18), so several requirements can't be tested and nobody can say how long a yes takes.
- **Job to be done:** *As a data analyst, when we change routing, I want to see delivery, answer and arrival times, so I can prove whether it worked.*
- **Requirement:** Store `delivered_at`, `answered_at`, `on_scene_at`, release events with excuse reason, and travel-time estimate at ping time.
- **Acceptance criteria:**
  - Fields populated for ≥ 99% of pings.
  - Ravi can report the measures in DR-27 weekly.
- **Goal check:** measures G1 and G2.

#### DR-27 New headline measures and guardrails · P0
- **Problem:** Acceptance rate hid the freeze-out (E13). DR-19 and DR-21 add pings that aren't taken, so acceptance rate **will fall even as outcomes improve**.
- **Job to be done:** *As the Director, when I read the weekly numbers, I want them to show whether callouts are covered fast and fairly, so a good number can't hide harm.*
- **Requirement:**
  - Headline: **callouts filled** and **time to fill a callout**.
  - Guardrails: home-area share (G1), time lost to unanswered pings (G2), unfilled rate, each responder's weekly load against their usual, time-to-scene.
  - Acceptance rate becomes a diagnostic.
- **Acceptance criteria:**
  - Definitions agreed with Ravi.
  - Each guardrail has an alert threshold.
  - Helen signs off on the headline change.
- **Goal check:** G1 ✅ G2 ✅ measurable

#### DR-28 Replay, shadow, switches · P0
- **Problem:** 4.2's routing change shipped with no replay, no guardrails and no way to switch one value back.
- **Job to be done:** *As an engineering manager, when routing rules change, I want to test them on real history and turn each one off on its own, so we never repeat 4.2.*
- **Requirement:**
  - Replay the 29 Jun – 6 Sep pings (plus anything since) through the new rules as a release gate.
  - Run the new ranking in shadow beside the live one before switching on.
  - Put each rule behind its own switch.
- **Acceptance criteria (release gate):**
  - Old Town, Uptown and Harborside local share ≥ 76%.
  - The four each at or above 10 pings/week.
  - Unfilled ≤ 5.5%.
  - No responder's load more than 30% above their pre-4.2 usual.
- **Goal check:** protects G1, G2
- **What-if checks:**
  - *The replay assumes old behaviour, but cheaper "no"s will change behaviour* → shadow run plus switches; watch guardrails for 2 weeks after switch-on.

#### DR-29 Supply sign-off on availability changes · P0
- **Problem:** Supply schedules maintenance from the availability record (C3). Two "maintenance booked on marathon day" tickets came after 4.2 (3054, 3109).
- **Job to be done:** *As a Supply lead, when Dispatch changes how availability works, I want to know first, so maintenance isn't booked into busy windows.*
- **Requirement:** Any change to what the availability record holds (including DR-10 and DR-11 states) needs Supply sign-off before release.
- **Acceptance criteria:** Written sign-off from Supply.
- **Goal check:** C3 ✅

### G. Operations

#### DR-30 Answer the people already affected · P0, this week, no code
- **Problem:** 45 ping tickets since 4.2, all open (E14). The worst-hit responders' handlers (Vesper, Meteor Mite) filed none.
- **Job to be done:** *As a handler whose responder went quiet, I want an honest explanation, so I stop wondering whether they've been dropped.*
- **Requirement:**
  - Interim reply to all 45 tickets.
  - Direct contact with the handlers of the four (Aunt Dot, Kip, Linda Pruitt, Desmond Okafor), and advance notice to neighbours' handlers before DR-08.
- **Acceptance criteria:** Every open ping ticket has a reply; all four handlers contacted.

#### DR-31 Find out why fewer callouts come in · P1
- **Problem:** Callouts coming in fell about 15% from release day, in 14 of 15 areas (E15).
- **Job to be done:** *As a PM, when demand drops on release day, I want to know whether we caused it, so we don't miss a second 4.2 side effect.*
- **Requirement:** Establish where callouts are entered (Marcus) and whether filter persistence or anything else in 4.2 reduced them.
- **Acceptance criteria:** A written answer, with a fix logged if 4.2 caused it.

#### DR-32 Roadmap clean-up · P1
- **Problem:** Every Q3 item still lists Priya as owner; Availability Confidence was dropped without a word.
- **Job to be done:** *As the Director, I want the roadmap to say who owns what and what's still committed, so commitments are real.*
- **Requirement:**
  - Reassign owners.
  - Record Availability Confidence as replaced by DR-24.
  - Hold the Q3 commitments conversation with Helen.
- **Acceptance criteria:** Roadmap updated and reviewed with Helen.

## 7. What-if register (all scenarios in one place)

| # | What if… | Risk to | Handled by |
|---|---|---|---|
| W1 | A miss and a "no" cost the same | G2: no reason to decline | DR-01 |
| W2 | The miss penalty is raised to make the gap | G1: history overrides proximity more | DR-01 (lower the "no" instead) |
| W3 | Misses stop counting at all | G2: ignoring is free | Rejected (section 8) |
| W4 | Responders tap yes to avoid penalties, then don't go | G1, G2 | DR-07 |
| W5 | A fake yes is boosted 3× | G1 | DR-07 removes boosted credit |
| W6 | A responder never shows after accepting, and no one records it | G2 | DR-07 on-scene + handler reassignment counts as release |
| W7 | A good-faith responder has to drop out | Fairness | DR-07 excused release |
| W8 | A habitual decliner keeps first place | G2 | DR-10 |
| W9 | A chronic non-answerer is kept up by the floor | G2 | DR-10 |
| W10 | Neighbours are penalised for declining out-of-area calls | G1 | DR-05 |
| W11 | Responders switch off delivery to dodge misses | G2 | DR-11 |
| W12 | A ping arrives after it has moved on | Trust | DR-11 |
| W13 | Older phones report delivery unreliably | Fairness | DR-06 criteria |
| W14 | The window is by count, not time | G1 | DR-02 |
| W15 | Switching formulas shocks rankings like 4.2 | G1, G2 | DR-08, DR-28 |
| W16 | The four are reset by hand | Fairness; doesn't last | DR-08 recompute |
| W17 | Scores persisted before recovery exists | G1 | DR-09 ships only with DR-02 |
| W18 | A pause is written to Supply's record | C3 | DR-10, DR-29 |
| W19 | Lock-screen text reveals someone is a responder | C2 | DR-13 |
| W20 | A bystander accepts on someone's phone | C2, G2 | DR-13 biometric |
| W21 | A loud alert exposes a responder | C2 | DR-14 opt-in |
| W22 | Undo lets people erase every "no" | G2 | DR-17 undo only converts to accept |
| W23 | A hold before passing on a "no" | G2 | DR-17 passes immediately |
| W24 | The wait is extended for anyone | C1 | DR-12 |
| W25 | First yes wins in overlap | G1 | DR-21 first keeps priority |
| W26 | A lined-up responder loses the race | Fairness | DR-21 no penalty |
| W27 | Overlap ties up a responder needed elsewhere | G2 | DR-21 deferred, not in bulk callouts |
| W28 | A load cap moves callouts away from the nearest | G1 | DR-22 monitor only |
| W29 | Callouts cycle through far responders | G2 | DR-19 escalation |
| W30 | Nearest-first sends someone without the skill | Outcome | DR-20 |
| W31 | A hard tag filter on incomplete tags | Coverage | DR-20 phase order |
| W32 | Handler notifications cause alert fatigue | Adoption | DR-23 sounds, mute |
| W33 | A handler accepts for an unready responder | G2 | DR-23 notify only |
| W34 | A standing number becomes a target | Fake yeses | DR-24 words, DR-07 |
| W35 | Per-user filters on a shared sign-in | G3 | DR-25 separate sign-ins |
| W36 | A filter hides the handler's own responder | Safety | DR-25 P0 rule |
| W37 | Acceptance rate falls as things improve | Wrong decisions | DR-27 |
| W38 | The replay can't predict new behaviour | G1, G2 | DR-28 shadow and switches |

## 8. Options considered and rejected

| Option | Why rejected |
|---|---|
| Restore the 90-second wait | Reverts half of 4.2 (fails G2, breaks C1). Dead time actually went up at 60 s only because of the scoring, which this fixes. |
| Start the countdown when the ping arrives | Can hold a ping past 60 s from send (breaks C1). Replaced by DR-06, DR-11, DR-13–DR-16. |
| Stop scoring misses | Makes ignoring a ping free (fails G2). |
| Score a miss the same as a "no" (today) | No reason to decline (fails G2); honest locals sink (fails G1). |
| Raise the miss penalty | History overrides proximity more (fails G1). |
| Raise accept credit for everyone | Narrows the reliability gap for all (weakens G2); strengthens fake yeses. |
| Reset four named responders by hand | Special case; under today's rules they'd sink again within days. |
| Count-based window | Never moves for a responder who isn't pinged. |
| "First yes wins" overlap | Further, faster responder beats the nearer one (fails G1). |
| Weekly load cap | Moves callouts away from the nearest responder (fails G1). |
| 5-second hold on every "no" | Slows every hand-off (fails G2). |
| Revert the 4.2 weights | Brings back the original complaint (fails G1); weights aren't the cause. |
| Ship the one-line penalty change alone | Stops the burying, but leaves unfilled callouts, "gone before I could answer", no handler visibility and no safety net. Helen asked not to "quietly change a number". |

## 9. Release plan

| Release | Contents | Gate |
|---|---|---|
| **Now (no code)** | DR-30 ticket replies and handler contact; DR-31 investigation starts; DR-32 roadmap; Security Policy 4.1 obtained | – |
| **Release A: fair scoring** (ship together) | DR-01 – DR-11, DR-12 check, DR-18, DR-19, DR-25 P0 rule, DR-26, DR-27, DR-28, DR-29 | DR-28 replay gate passes; shadow run ≥ 1 week; Supply sign-off |
| **Release B: answering in time** | DR-13 – DR-17, DR-22 – DR-24, rest of DR-25, DR-20 phase 1 | Security sign-off for DR-13/DR-14; Sofia's prototype tested with 2+ handlers |
| **Later** | DR-20 phase 2, DR-21 overlap | Tag completeness; delivery/answer data shows the benefit |

If phones can't report delivery (DR-06/DR-11 dependency), Release A ships with
every miss counted and the floor and boost doing the protecting; DR-06 and DR-11
follow when receipts exist.

## 10. Expected outcomes (estimates, to be confirmed by the replay)

| Measure | Before 4.2 | Now | Target after Release A + B |
|---|---|---|---|
| Local responder's share of pings in Old Town / Uptown / Harborside | 76–83% | 11–20% | ≥ 76% |
| Pings a week for the four | 11–14 | 3–5 | ≥ 10 |
| Longest a ping stays open | 90 s | 60 s | 60 s (15 s if undelivered) |
| Unfilled callouts | 5.5% | 11.1% | ≤ 5.5% |
| Time to get back to the middle after a bad stretch | – | never | about 1 normal week (7–8 accepts) |
| Most a bad record can cost in travel time | up to about 40 min (old weights) | up to about 19 min | about 3 min |
| Load on The Gale / Nightwell / Stormwrack / Falkirk | 10–15 a week | 14–19 a week | within 30% of their pre-4.2 usual |
| Open ping tickets | – | 45 | all answered this week |
| Missed pings | about 4 a week | about 30 a week | fewer, and only real misses count |

## 11. Decisions and open questions

| Owner | Question |
|---|---|
| **Helen** | Floor (minutes a bad record can cost: proposed about 3). Window length (3, 14 or 30 days; no requirement exists). Boost multiple (proposed 3×). Headline measures (DR-27). Approve the package over the one-line fix. |
| **Wen** | Can phones confirm delivery? Why do callouts stop after one ping? Where are scores kept, and do deploys reset them? Does 4.2's duplicate fix stop resends? Streak thresholds (3 misses / 5 "no"s). |
| **Security** | Security Policy 4.1 review for DR-13, DR-14, DR-23. |
| **Supply** | Sign-off on DR-10 / DR-11 availability states. |
| **Marcus** | Where are callouts entered (DR-31)? Escalation thresholds for DR-19. |
| **Ravi** | Definitions for DR-27 measures. |
| **Nadia** | Ticket replies and handler contact (DR-30). |
| **Sofia** | Prototype for DR-13 – DR-15, DR-23, DR-24. |

## 12. Backlog: handler pain not caused by 4.2

From the interviews and tickets; not part of this package. Supply items go to the
Supply team.

- **Console:** dark mode; larger status text; logout after about 20 minutes idle; screen-reader button labels; incident feed jumping to top; detail panel covering the map; handover notes; keyboard shortcuts; sort order; slow Monday mornings; out-of-date map; notes field limit; profile photo; phone number format; availability times in the handler's time zone when the responder travels; leave status; export responder history; training material; billing duplicates; password reset email slow.
- **Supply (second-biggest ticket group):** requisitions stuck 9–11 days and the priority field ignored; field failure reports get no reply; catalog search; wrong sizes and wrong office deliveries; back orders; maintenance reminders arriving late.

## 13. Sources

- **rook-wiki:** About Rook, Glossary, Rook Dispatch, Rook Supply, Team directory, Releases (4.0, 4.1, 4.2 with comments), Q3 roadmap and item pages, Product briefs, Customer interviews (Aunt Dot, Mr. Ambrose, Halloran, Kip).
- **rook-database:** pings, callouts, responders, handlers, support_tickets.
- **Code:** `00-rook/code/dispatch-routing/` (`config.py`, `routing.py`, `offer.py`, `history.py`, `availability.py`, README, CHANGELOG).
- **Notes:** `00-rook/company/notes/handoff-from-priya.docx`; `05-super-speed/director-request.txt`.
