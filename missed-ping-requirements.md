# Requirements: Getting pings to responders, and keeping handlers in the loop

Rook Dispatch · Draft v0.6 (adds severity and a ranked priority order) · Owner: Dispatch PM · September 2026
Reviewers: Helen Achebe (Product), Marcus Oyelaran and Wen Li (Engineering),
Nadia Hoffmann (Support), Ravi Menon (Data), Sofia Marino (Design)

## Problem

Since 4.2 (12 Aug), responders are losing callouts in two ways:

- **Quiet weeks.** A missed ping lowers a responder's routing score exactly as
  much as a turn-down, and the score never recovers unless they take a ping.
  4.2 cut the ping wait from 90 to 60 seconds, so misses rose sharply. Some
  responders dropped so far down the ranking that they're almost never pinged,
  so they can't take a ping and recover. Their work has moved onto others.
- **Gone before they could answer.** 60 seconds may not be long enough for a
  real person to reach the phone. The countdown also starts when the ping is
  *sent*, not when it reaches the phone (`offer.py`), so late delivery may eat
  into the window. Neither is measured yet.

Handlers are often the first to notice a ping, but the console doesn't tell
them clearly when one is live, so they can't help their responder reach it.

## Root cause

Dispatch treats "didn't answer in time" as "refused", penalises it more than
it rewards a yes, and never lets the score recover. When 4.2 shortened the
window, normal misses demoted responders permanently.

| Part | Where | What happens |
|---|---|---|
| A miss is scored as a refusal | `offer.py` `dispatch()` | `record_declined()` is called for both turned down and missed ("Same either way"). |
| The penalty is bigger than the reward | `config.py` | A miss costs −0.12 and a taken ping earns +0.08, so one miss takes 1.5 yeses to undo. |
| Scores never recover | `history.py` | Scores change only when a ping happens; there is no decay (2019 TODO). Offers stop at the first yes, so a low-ranked responder is rarely pinged and can't climb back. |
| **Trigger** | `config.py` | `OFFER_TIMEOUT_SECONDS` cut from 90 to 60 in 4.2, so ordinary responders started missing. |

**Contributing:** the countdown starts when the ping is sent, not delivered
(`offer_to()`). **Not the cause:** the 4.2 ranking weights (acceptance weight
went *down*, 0.40 to 0.25), availability, or seasonality.

Confirmed from the code and consistent with the data. The replay in R1 and R2
is the proof.

## Evidence

**Data** (pings, callouts and support_tickets, 29 Jun – 6 Sep 2026)
- Missed pings went from 2–6 a week to 38 in the week of release.
- Callouts where nobody went doubled, from **5.5% to 11.1%**. Unfilled callouts
  involving a missed ping went from 3 to 27.
- Six responders are pinged less since 4.2: Farlight −74%, The Undertow −67%,
  Vesper −65%, Meteor Mite −65%, Corporal Ashgrove −19%, Halfmoon −16%. The
  other ten went *up* 21–48% (The Gale +48%).
- The four worst-hit responders aren't slow. Before 4.2 their declines took a
  normal 19–30 seconds (median), and each had missed only 1–3 pings in six
  weeks. Each missed 2–3 pings in the first two days after release and never
  recovered.
- A turn-down passes the callout on in a median of **22 seconds**. A miss holds
  it for the full wait (62 seconds now, 92 before). There is no data on how
  long a *yes* takes.
- Code: `history.record_declined()` treats missed and turned down the same
  (−0.12; a taken ping is +0.08). A 2019 TODO left score recovery unbuilt.

**Support tickets** (107 since 12 Aug; 42% are ping problems)
- Handlers have ruled out their side ("availability is set correctly and her
  tags are all there") and keep refiling. The trap in their words: "First one
  in 9 days and he missed it."
- Retention risk, from a responder via their handler: "starting to wonder if
  im still even in the system." Rook bills per active responder.
- Nine responders report "phone buzzed, by the time i unlocked it, gone."
- Console: 8 tickets about saved filters resetting or saving wrongly since 4.2.
  Small status-badge text, a single alert sound for everything, dark mode and
  the tag legend have each been raised both before and after 4.2.

**Full ticket review** (all 147, 29 Jun – 7 Sep; 40 before 4.2, 107 after)
- **None of the 46 ping tickets is closed.** Handlers refile every few days.
  Most other issues appear as near-identical tickets from two handlers.
- **Phone numbers won't save** (2): "it says the format is wrong, but it is a
  normal number." Pings may be going to old phones.
- **Availability is wrong** (4): hours use the handler's time zone when the
  responder travels, and there's no leave status ("looks the same as being
  busy"). Supply reads the same record. 4 more tickets report maintenance
  booked on a busy day or reminders arriving after the date.
- **Handlers can't stay on watch** (6): signed out after about 20 minutes idle
  ("I am watching it, not clicking it"), password resets take up to an hour,
  and covering colleagues share one login. 2 more ask for handover notes.
- **Screen reader** (2): buttons are read out as "button" with no name.
- **Fixed in 4.2 and not seen since:** duplicate pings, wrong times on the
  coverage export, tags changing order.

**Handler interviews** (4, run by Sofia Marino, 2–5 Sep 2026)

| What they raised | How many | In their words |
|---|---|---|
| Callout gone before the responder could answer | 3 of 4 | "by the time he's actually got a thumb on the screen — it's gone." (Dot) |
| Handler not told clearly that a callout is live | 3 of 4 | "so I'm not relying on hearing a buzz through a ceiling." (Dot) |
| Quiet weeks, with work piling onto others | 2 of 4 | "Mite thinks Mite's been forgotten. Gale's exhausted." (Kip) |
| Status text too small to read at a glance | 2 of 4 | "I sometimes cannot tell engaged from available without leaning in." (Ambrose) |
| Dark mode | 1 of 4 | "the console is just this wall of white light in the middle of my face." (Kip) |
| Saved filters reset without warning | 1 of 4 | "I'd rather it warned me the filter had reset than simply reset it." (Ambrose) |
| Tag legend hard to find | 1 of 4 | "It sits in a drawer off the responder detail panel." (Ambrose) |

The interviews describe the physical time it takes to answer, not slow phones:
Vesper running downstairs, Captain Vantage with "coat on, one boot on". Losing
callouts also affects responders whose pings went *up* (Captain Vantage +37%,
Sgt. Bulwark +21%), so it isn't only the demoted six.

## Goals

1. No responder drops out of rotation permanently because of a short run of
   misses.
2. Reduce callouts where nobody goes back to the pre-4.2 level (≤ 5.5%) or
   better.
3. Never make it cheaper to let a ping time out than to turn it down.
4. Give responders a realistic window to answer, set from data.
5. Let a handler see, at a glance, when their responder has a live callout.

## Non-goals

- Reverting the 4.2 proximity weighting. It stays.
- Building the Handler Phone App. R12 uses the existing console.
- Mutual aid or cross-area cover.
- Supply issues raised in interviews (see "Passed to Supply" below).

## Requirement types

| Type | Meaning |
|---|---|
| **Fix: 4.2** | Repairs damage caused by a 4.2 change. |
| **Fix: pre-4.2** | An older defect or gap that 4.2 exposed or that predates it. |
| **New** | Functionality that doesn't exist today. |

## Severity and priority

**Severity** is what happens to someone needing help if the issue isn't fixed:

| Severity | Meaning |
|---|---|
| **S1** | Callouts go unanswered: a responder is starved of pings, or nobody goes. |
| **S2** | Slower response, or a handler can't help: wrong pings, missed alerts, no visibility. |
| **S3** | Trust and workflow friction: costs time or confidence, but no callout. |
| **S4** | Comfort and cosmetics. |

**Priority** is shipping order. It starts from severity, then adjusts for
dependencies, effort and how strong the evidence is.

| Priority | Meaning |
|---|---|
| **P0** | Tier 1, first release: fixes the root cause. |
| **P1** | Tier 2, next release: the trigger (ping wait) and the handler's view. |
| **P2** | Tier 3, when capacity allows: trust and usability. |
| **P3** | Backlog: console redesign. |

Ticket volume is not used to rank severity. The worst-hit handlers file
few or no tickets: Vesper and Meteor Mite are down 65% with zero tickets.

### Ranking

| Rank | Req | Sev | Pri | Why here |
|---|---|---|---|---|
| — | R9 Interim support reply | S3 | P0 | **Start this week; no engineering.** 46 ping tickets are waiting for an answer. |
| 1 | R2 Score a miss as "didn't reach them" | S1 | P0 | Root cause: misses scored as refusals and penalised more than a yes. |
| 2 | R1 Recovery over time | S1 | P0 | Root cause: without it, demoted responders never come back. |
| 3 | R26 No responder starved of pings | S1 | P0 | The pass/fail test that the trap is gone. |
| 4 | R5 Reset the six | S1 | P0 | Immediate relief. Ships with R1 and R2, never before. |
| 5 | R19 Phone numbers can be updated | S1* | P0 | Cheap, and could directly silence a phone. *Drops to S3/P2 if Wen confirms pings go to a signed-in device, not the number. |
| 6 | R6 Record delivered and answered times | Enabler | P0 | **Ship first in the release** so data builds up; R8 and R10 depend on it. |
| 7 | R3 Keep missed and turned down separate | Guardrail | P0 | No extra work; comes with R2. |
| 8 | R10 Set the ping wait from data | S1 | P1 | The trigger. Interviews say 60 seconds is too short. Waits only for R6 data. |
| 9 | R8 Countdown from delivery | S1* | P1 | *Only if R6 shows a real delivery delay; otherwise drop it. |
| 10 | R12 Live-callout alert for the handler | S2 | P1 | 3 of 4 interviews; zero tickets ask, so it's easy to underrate. **Ship with R22.** |
| 11 | R22 Stay signed in while watching | S2 | P1 | A logged-out handler can't see R12's alert. Mostly configuration. |
| 12 | R20 Availability in the responder's time zone | S2 | P1 | Wrong-hour pings cause misses and break Supply's maintenance scheduling. |
| 13 | R21 Leave status | S2 | P1 | Same as R20; leave days shouldn't count against the score. |
| 14 | R7 Weekly health metrics | Enabler | P1 | Catches the next regression in a week, not three. Monitors R26. |
| 15 | R11 Overload watch | S2 | P1 | Ten responders are carrying extra work, and no channel reports it. |
| 16 | R13 Different alert sounds | S2 | P1 | Small effort; helps a handler react to the right responder. |
| 17 | R4 Alert after 3 misses | S2 | P1 | Less urgent once R1 and R2 stop misses trapping people. |
| 18 | R24 Support closes the loop | S3 | P1 | How 4.2 would have been caught in week one. |
| 19 | R16 Reliable saved filters | S3 | P2 | 8 defects; handlers watch the wrong list, but no callouts lost. |
| 20 | R25 Screen reader | S3 (S2 for the affected handler) | P2 | Blocks one handler today; compliance risk; likely cheap. |
| 21 | R15 Status readable at a glance | S3 | P2 | 2 of 4 interviews. Cheap; do it alongside R12 (same screen). |
| 22 | R23 Shift cover without shared logins | S3 | P2 | Biggest build here; needs a Security Policy 4.1 review first. |
| 23 | R17 Dark mode | S4 | P3 | Strong demand from a few handlers; no effect on callouts. |
| 24 | R14 "Pings this week vs usual" on cards | S4 | P3 | Mostly unnecessary once R1 and R26 close the gaps it explains. |
| 25 | R18 Tag legend easier to find | S4 | P3 | A once-a-fortnight annoyance. |

**Changes from v0.5:** R15, R16, R23 and R25 moved from P1 to P2. R14, R17
and R18 moved from P2 to the new P3. R6 now ships first in its release. R12
and R22 ship together. R9 starts this week rather than waiting for a release.

## Requirements

### A. Routing and pings

| # | Type | Pri | Requirement | Acceptance criteria |
|---|---|---|---|---|
| R1 | Fix: pre-4.2 | P0 | **Recovery over time.** A responder's recent-acceptance score eases back toward neutral (0.5) as time passes, whatever their score is. | **Time-based:** the score recovers with elapsed time, including for a responder who gets no pings at all. **Outcome:** a responder demoted by 3 misses in a row is back in normal rotation within a configurable period (proposed: 3 days). Scores above neutral also ease back. The rate is a value in `config.py`. **Release gate:** replaying the 29 Jun – 6 Sep pings through the new scoring shows none of the six affected responders (R5) below their pre-4.2 weekly ping rate, and fewer callouts where nobody went than the 11.1% observed. |
| R2 | Fix: pre-4.2 | P0 | **Score a miss as "didn't reach them", not as a refusal.** Missed and turned down are scored separately. A turn-down never costs more than a miss, and one taken ping fully offsets one miss. | `dispatch()` scores missed and turned-down pings through separate paths; `record_declined()` is no longer called for a miss. Build checks fail if the turn-down penalty is larger than the miss penalty, **or** the miss penalty is larger than the reward for a taken ping. Proposed values: turned down −0.04, missed −0.06, taken +0.08 (Wen to tune using the R1 replay). **Release gate:** the R1 replay passes with these values. |
| R3 | Guardrail (no change) | P0 | **Keep missed and turned down as separate records.** Ranking may weigh them however it likes, but storage and reporting keep the two apart. | Every ping is stored as taken, turned down or missed, as today. No reporting rolls them together. |
| R5 | Fix: 4.2 | P0 | **One-off reset for responders already demoted.** At release, reset the score to neutral for any responder whose weekly pings fell by more than 10% after 4.2. | The reset list is reviewed with Marcus before it runs. On current data it is exactly six: Farlight, The Undertow, Vesper, Meteor Mite, Corporal Ashgrove, Halfmoon. The reset is logged. **Runs in the same release as R1 and R2, or after them, never before:** without them, reset responders fall back into the trap. |
| R6 | New | P0 | **Record when each ping reached the phone and when it was answered.** Each ping stores a delivered time (from the phone) and an answered time (taken or turned down). | 100% of pings from release onward have a delivered time where the phone reports one, and every answered ping has an answered time. Ravi reports the sent-to-delivered gap and time-to-yes weekly. |
| R8 | Fix: pre-4.2 | P1 | **Start the countdown when the ping reaches the phone.** The ping wait is measured from delivery, not from sending. There is a cap so a ping that never arrives still moves on. | Every responder gets the full ping wait on screen. A ping with no delivery confirmation moves on after the ping wait plus a configurable cap (proposed: 15 seconds). *Ship after R6 data confirms the delay is real; drop it if not.* |
| R10 | Fix: 4.2 | P1 | **Set the ping wait from data.** Two weeks after R6 ships, review the ping wait against real answer times and change it if needed. | The wait is set so at least 95% of yeses land inside it (proposed target; Helen to confirm). The decision and the data behind it are recorded. The wait stays one value for everyone. |
| R26 | Fix: pre-4.2 | P0 | **No responder is starved of pings.** The pass/fail test that the trap is gone. | No available responder with the required tags goes more than a configurable period (proposed: 3 days) without a ping while callouts needing those tags happen in their area. It is checked in the R1 replay before release and monitored weekly after (R7). If it's breached, the responder is flagged to Support and the handler, not silently skipped. |
| R11 | New | P1 | **Watch for overload.** Track whether work is piling onto some responders as others are demoted. | Ravi's weekly report shows the spread of pings across responders and flags anyone more than 30% above their 6-week average. Today that would flag several, including The Gale (+48%). Any routing cap is a separate decision. |

### B. Handler visibility

| # | Type | Pri | Requirement | Acceptance criteria |
|---|---|---|---|---|
| R12 | New | P1 | **Live-callout alert for the handler.** Whenever one of a handler's responders is pinged, the handler's console shows it as live, with time left. | The alert appears within 2 seconds of the ping being sent, shows which responder and the time remaining, and clears when the ping is taken, turned down or missed. It is visible from across a room (size agreed with Sofia). |
| R13 | New | P1 | **Different alert sounds.** A handler can tell by sound which responder has a callout, and a callout from other alerts. | Each responder on a handler's roster can have their own sound. Callout alerts sound different from other console alerts. Defaults are distinct without any setup. |
| R4 | New | P1 | **Tell the handler about repeated misses.** After 3 missed pings in a row, Dispatch alerts that responder's handler in the console, and by email or push if the handler has turned that on. | The alert names the responder and the misses, and suggests checking their phone and availability window. One alert per run of misses. It clears when the responder answers a ping (taken or turned down). |
| R14 | New | P3 | **"Pings this week vs usual" on each responder's card.** | Each coverage card shows this week's pings next to the 6-week average. It uses the same numbers as R7. |
| R9 | Fix: 4.2 | P0 | **Interim reply to handlers.** Until this ships, Support has an agreed answer for "quiet" and "gone before I could answer" tickets, and replies to the open ones. | Every open ticket of these two kinds gets a reply within 2 business days of sign-off. The reply confirms the responder is still in rotation and that a fix is planned. It does not explain scoring in detail. |

### C. Console usability

| # | Type | Pri | Requirement | Acceptance criteria |
|---|---|---|---|---|
| R15 | Fix: pre-4.2 | P2 | **Status readable at a glance.** Make the status badge (engaged / available) larger and higher-contrast. | In testing with handlers, status reads correctly from a standing distance (about 1.5 m) on a laptop. Badge text meets WCAG AA contrast. |
| R16 | Fix: 4.2 | P2 | **Saved filters are reliable.** Fix the 4.2 filter defects, and warn the handler if their saved filter has been reset. | Saved filters survive console updates. They are per handler, not per computer. If a reset does happen, the console shows a visible notice until it's dismissed. Filter-defect tickets fall to zero. |
| R7 | New | P1 | **New health metrics.** Add to Ravi's weekly report: % of callouts where nobody went, pings per responder per week, miss rate per responder, sent-to-delivered gap and time-to-yes. | Flag any responder whose weekly pings are more than 10% below their 6-week average with no change in availability. (A 50% week-on-week rule would have missed Ashgrove and Halfmoon.) |
| R17 | New | P3 | **Dark mode.** | A built-in dark theme the handler can turn on. All text and status colours meet WCAG AA in both themes. |
| R18 | Fix: pre-4.2 | P3 | **Capability tag legend easy to find.** | The legend opens from wherever tags appear, in one click. |

*R7 sits under internal reporting rather than the console, but it is listed
here to keep the R-numbers stable from v0.2.*

### D. Availability, access and support

| # | Type | Pri | Requirement | Acceptance criteria |
|---|---|---|---|---|
| R19 | Fix: pre-4.2 | P0 | **Phone numbers can be updated.** The responder profile accepts any valid phone number, and pings follow the change. | Valid numbers in local and international formats save without error. After a change, the next ping reaches the new number or device. Responders whose number change was rejected are found and fixed (at least Stormwrack and The Drift). |
| R20 | Fix: pre-4.2 | P1 | **Availability uses the responder's time zone.** A handler can set where the responder is, and availability windows follow it. | Availability is stored and checked in the responder's time zone. The console shows both the responder's local time and the handler's. A responder working in another city is pinged only inside their own hours. |
| R21 | New | P1 | **Leave status.** A handler can mark a responder as on leave for a date range, separately from busy or unavailable. | Responders on leave aren't pinged. Leave shows differently from busy in the console. Supply's maintenance scheduling can read it. Days on leave don't lower the acceptance score and don't trigger the R7 "fewer pings" flag. |
| R22 | Fix: pre-4.2 | P1 | **Handlers stay signed in while watching.** The console doesn't sign out a handler who is watching a live view, and a locked-out handler gets back in fast. | A visible coverage view stays signed in for a full shift (proposed: up to 12 hours; Security to approve). Password reset emails arrive within 5 minutes for 95% of requests. |
| R23 | New | P2 | **Shift cover without shared logins.** A responder can have more than one handler, each with their own sign-in, plus a handover note between shifts. | A covering handler has their own sign-in for the same responder. Filters (R16) and alerts (R12, R4) are per sign-in. The outgoing handler can leave a note that the next one sees on sign-in. Shared logins can be retired. Security Policy 4.1 review done. |
| R24 | New | P1 | **Support closes the loop.** Duplicate tickets are linked to one known issue, handlers are told when it's fixed, and Product gets a weekly theme count. | Every ticket is tagged with a theme. Tickets about the same issue link to one known issue. When it's fixed, every linked handler gets a reply. Weekly theme counts go to the Dispatch PM, and a theme that doubles week on week is flagged. |
| R25 | Fix: pre-4.2 | P2 | **Screen reader support.** Every console control has a name a screen reader can read. | Every button and control has an accessible name. An automated accessibility check finds no critical issues. A screen reader user confirms the main views work. |

### Summary by type

| Type | Requirements |
|---|---|
| Fix: 4.2 | R5, R9, R10, R16 |
| Fix: pre-4.2 | R1, R2, R8, R15, R18, R19, R20, R22, R25, R26 |
| New | R4, R6, R7, R11, R12, R13, R14, R17, R21, R23, R24 |
| Guardrail (no change) | R3 |

## Passed to Supply (not in this scope)

From Halloran's interview and 26 Supply tickets (10 before 4.2, 16 after).

- **Safety first:** cracked vest plates waiting in the normal queue, a
  grapple line slowing below freezing, and spare gear "not rated for the
  cold" while repairs or back orders drag. These mean a responder is in the
  field with degraded equipment.
- **Requisition approvals:** one queue for everything, and the priority field
  has no effect ("doesn't matter if it's laces or plate"). Add to the 4.3
  Requisition approval chains work.
- **Field failure reports:** no response once filed ("goes into a void").
- **Catalog search:** needs exact item names; asks for category filters.
- **Deliveries and maintenance:** wrong sizes, a delivery to the wrong office,
  and maintenance booked on busy days or reminded too late. The last two may
  be fixed by R20 and R21.

## Passed to Finance

- **Duplicate billing** (2 tickets): invoices list one responder twice. Rook
  bills per active responder, so this may be overcharging. Check other
  invoices for the same error.

## Success metrics

| Metric | Now (post-4.2) | Target, 4 weeks after release |
|---|---|---|
| Callouts where nobody went | 11.1% | ≤ 5.5% |
| Responders getting < 25% of their pre-4.2 weekly pings | 4 | 0 |
| Responders whose weekly pings fell > 10% with no change in availability | 6 | 0 |
| Responders more than 30% above their 6-week average | Several (e.g. The Gale +48%) | Agreed once R11 baseline is set |
| Time-to-yes (95th percentile) vs ping wait | Not measured | 95% of yeses inside the wait |
| Gap between ping sent and delivered (median / slowest 10%) | Not measured | Baseline set; target agreed once known |
| "Phone never goes off" tickets | ~2/3 of callout tickets | Back to pre-4.2 levels (baseline from Nadia) |
| Filter-defect tickets | 8 since 4.2 | 0 |
| Rejected phone-number changes | At least 2 responders | 0 |
| Open ping tickets with no reply | 46 | 0 within 2 business days (R9, R24) |
| Acceptance rate | 72.7% (latest week) | ≥ 76% (pre-4.2 range) |

Acceptance rate alone isn't enough. It was recovering while the worst-hit
responders were still being skipped.

## Open questions

1. **Recovery rate and penalty values.** The R1 replay is now a release gate.
   Open: what recovery period and penalty values pass it, and is 3 days the
   right limit for R1 and R26? *Owner: Wen.*
2. **Ping wait.** Is 95% of yeses inside the wait the right bar for R10? Should
   the wait go back to 90 seconds as a stopgap before the data arrives?
   *Owner: Helen.*
3. **Unfilled callouts.** What happens after a callout ends with nobody going?
   *Owner: Nadia.*
4. **Commitment.** Is this 4.3 scope, or does it displace Requisition approval
   chains? Is Availability Confidence (missing from 4.2) affected?
   *Owner: Helen.*
5. **Contract impact.** Do R4, R12 or R6 need a Security Policy 4.1 review?
   They touch responder records and show live status to handlers.
   *Owner: PM.*
6. **Late delivery.** Does the push service already log when a ping reaches
   the phone? Is it worse on older phones (Ironvale's 4 Aug ticket)?
   *Owner: Wen.*
7. **Shared handler sign-ins.** Handlers lend their login to the colleague who
   covers nights. Should R4 and R12 alerts reach a covering handler, and is the
   shared login a Security Policy 4.1 issue? *Owner: PM with Nadia.*
8. **Accidental declines.** Should a turn-down get a short undo window,
   especially if R2 makes declines cheaper? *Owner: Sofia.*
9. **R12 and the Handler Phone App.** Is the live alert in the console enough,
   or does it need the phone app to work for handlers away from the desk, like
   Dot? *Owner: Sofia.*
10. **How pings find a phone.** Are pings sent to the number on the profile,
    or to a signed-in device? If it's the number, R19 may explain some
    "phone never goes off" cases. *Owner: Wen.*
11. **Out-of-date map.** The incident map still shows the old road layout by
    the ferry terminal (2 tickets). Does routing's travel-time estimate use
    the same map data? If so, proximity scores there are wrong.
    *Owner: Wen.*
12. **Ticket duplicates.** Most non-ping issues appear as two near-identical
    tickets. Is that two handlers with the same problem, or a filing
    template? It changes how big those issues really are. *Owner: Nadia.*
13. **Idle sign-out.** Is a 12-hour signed-in session acceptable under
    Security Policy 4.1 (R22)? *Owner: PM.*
