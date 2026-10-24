# Requirements: Missed pings shouldn't stop a responder's phone ringing

Rook Dispatch · Draft v0.2 (adds support ticket findings) · Owner: Dispatch PM · September 2026
Reviewers: Helen Achebe (Product), Marcus Oyelaran and Wen Li (Engineering),
Nadia Hoffmann (Support), Ravi Menon (Data), Sofia Marino (Design)

## Problem

Since 4.2 (12 Aug), a missed ping lowers a responder's routing score exactly as
much as a turn-down. The score never recovers unless the responder takes a ping.
Because 4.2 also cut the ping wait from 90 to 60 seconds, misses rose sharply.
Some responders dropped so far down the ranking that they are almost never
pinged, so they can't take a ping and recover.

A second, unconfirmed factor: the countdown starts when the ping is *sent*,
not when it reaches the phone (`offer.py`). If pushes arrive late, part of
the 60 seconds is gone before the phone buzzes.

## Evidence (pings, callouts and support_tickets, 29 Jun – 6 Sep 2026)

- Missed pings went from 2–6 a week to 38 in the week of release.
- Callouts where nobody went doubled, from **5.5% to 11.1%**. Unfilled callouts
  involving a missed ping went from 3 to 27.
- Six responders are being pinged less since 4.2. Four collapsed (Farlight
  −74%, The Undertow −67%, Vesper −65%, Meteor Mite −65%) and two are partly
  demoted (Corporal Ashgrove −19%, Halfmoon −16%). The other ten went *up*
  21–48%, so the work moved onto them.
- The four stuck responders aren't slow: before 4.2 their declines took a
  normal 19–30 seconds (median), and each had missed only 1–3 pings in six
  weeks. Each missed 2–3 pings in the first two days after release and never
  recovered.
- Tickets saying "phone never goes off" are about two thirds of the callout
  tickets since release. Handlers now ask "Is The Undertow still on the list?"
- A turn-down passes the callout on in a median of **22 seconds**. A miss holds
  it for the full wait (62 seconds now, 92 before).
- Code: `history.record_declined()` treats missed and turned down the same
  (−0.12; a taken ping is +0.08). A 2019 TODO left score recovery unbuilt.

**From support tickets (12 Aug – 7 Sep)**
- **Handlers have ruled out their side.** Nearly every "quiet" ticket says
  availability and tags are set correctly. Most ask Rook to check, and handlers
  keep filing near-identical tickets every few days, which suggests nobody has
  answered.
- **The trap, in handlers' words:** "First one in 9 days and he missed it."
  The rare ping that does arrive gets missed, and the score sinks further.
- **Retention risk.** A responder, quoted by their handler: "starting to wonder
  if im still even in the system." Rook bills per active responder.
- **Possible late delivery.** Nine responders report "phone buzzed, by the
  time i unlocked it, gone" or "thumb on the screen and it switched." That
  takes seconds, not a minute. Before 4.2, a 4 Aug ticket said Ironvale's older
  phone gets notifications "late or not at all". No table records when a ping
  reached the phone, so this can't be measured yet.
- **Also raised:** handlers sharing one sign-in with the colleague who covers
  nights (2 tickets), and an accidental decline with a request for a short undo
  (4 Aug).

## Goals

1. No responder drops out of rotation permanently because of a short run of
   misses.
2. Reduce callouts where nobody goes back to the pre-4.2 level (≤ 5.5%) or
   better.
3. Never make it cheaper to let a ping time out than to turn it down.

## Non-goals

- Reverting the 4.2 proximity weighting. It stays.
- Changing the ping wait in this release. (R6 gathers the data to decide it.)
- Building the Handler Phone App. (R4 uses existing channels.)
- Mutual aid or cross-area cover.

## Requirements

| # | Requirement | Acceptance criteria |
|---|---|---|
| R1 | **Recovery over time.** A responder's recent-acceptance score eases back toward neutral (0.5) when they aren't taking pings, whatever their score is. | A responder at the floor (0.0) who gets no pings returns to neutral within a configurable period (proposed default: 14 days). The rate is a value in `config.py`. Scores above neutral also ease back. |
| R2 | **Turn-down never costs more than a miss.** Scoring keeps two separate values, one for turned down and one for missed, and turned down is never the larger. | The config has separate values for the two outcomes. A check fails the build if the turn-down value is larger than the missed value. Proposed starting values: turned down −0.06, missed −0.12. Engineering to confirm. |
| R3 | **Keep missed and turned down as separate records.** Ranking may weigh them however it likes, but storage and reporting keep the two apart. | Every ping is stored as taken, turned down or missed, as today. No reporting rolls them together. |
| R4 | **Tell the handler about repeated misses.** After 3 missed pings in a row, Dispatch alerts that responder's handler in the console, and by email or push if the handler has turned that on. | The alert names the responder and the misses, and suggests checking their phone and availability window. One alert per run of misses. It clears when the responder answers a ping (taken or turned down). |
| R5 | **One-off reset for responders already demoted.** At release, reset the score to neutral for any responder whose weekly pings fell by more than 10% after 4.2. | The reset list is reviewed with Marcus before it runs. On current data it is exactly six: Farlight, The Undertow, Vesper, Meteor Mite, Corporal Ashgrove, Halfmoon. The reset is logged. |
| R6 | **Record when each ping reached the phone and when it was answered.** Each ping stores a delivered time (from the phone) and an answered time (taken or turned down). | 100% of pings from release onward have a delivered time where the phone reports one, and every answered ping has an answered time. Ravi reports the gap between sent and delivered weekly. |
| R7 | **New health metrics.** Add to Ravi's weekly report: % of callouts where nobody went, pings per responder per week, miss rate per responder, and the sent-to-delivered gap. | Flag any responder whose weekly pings are more than 10% below their 6-week average with no change in availability. (The earlier 50% week-on-week rule would have missed Ashgrove and Halfmoon.) |
| R8 | **Start the countdown when the ping reaches the phone.** The ping wait is measured from delivery, not from sending. There is a cap so a ping that never arrives still moves on. | Every responder gets the full ping wait on screen. A ping with no delivery confirmation moves on after the ping wait plus a configurable cap (proposed: 15 seconds). *Ship after R6 data confirms the delay is real; drop it if not.* |
| R9 | **Interim reply to handlers.** Until this ships, Support has an agreed answer for "quiet" and "gone before I could answer" tickets, and replies to the open ones. | Every open ticket of these two kinds gets a reply within 2 business days of sign-off. The reply confirms the responder is still in rotation and that a fix is planned. It does not explain scoring in detail. |
## Success metrics

| Metric | Now (post-4.2) | Target, 4 weeks after release |
|---|---|---|
| Callouts where nobody went | 11.1% | ≤ 5.5% |
| Responders getting < 25% of their pre-4.2 weekly pings | 4 | 0 |
| Responders whose weekly pings fell > 10% with no change in availability | 6 | 0 |
| Gap between ping sent and delivered (median / slowest 10%) | Not measured | Baseline set; target agreed once known |
| "Phone never goes off" tickets | ~2/3 of callout tickets | Back to pre-4.2 levels (baseline from Nadia) |
| Acceptance rate | 72.7% (latest week) | ≥ 76% (pre-4.2 range) |

Acceptance rate alone isn't enough. It was recovering while the four stuck
responders were still being skipped.

## Open questions

1. **Why do some responders miss at 60 seconds?** Do some handlers relay pings
   to their responder? (Aunt Dot, Vesper's handler: "hearing a buzz through a
   ceiling.") Check Sofia's September interviews. *Owner: Sofia.*
2. **Recovery rate and penalty values.** Are 14 days, −0.06 and −0.12 right?
   Simulate them on the June–September pings before release. *Owner: Wen.*
3. **Unfilled callouts.** What happens after a callout ends with nobody going?
   *Owner: Nadia.*
4. **Commitment.** Is this 4.3 scope, or does it displace Requisition approval
   chains? Is Availability Confidence (missing from 4.2) affected?
   *Owner: Helen.*
5. **Contract impact.** Do R4's alert or R6's delivered and answered times
   need a Security Policy 4.1 review? Both touch responder records.
   *Owner: PM.*
6. **Late delivery.** Does the push service already log when a ping reaches
   the phone? Is late delivery worse on older phones (Ironvale's 4 Aug
   ticket)? *Owner: Wen.*
7. **Shared handler sign-ins.** Handlers lend their login to the colleague
   who covers nights. Should R4 alerts reach a covering handler, and is the
   shared login a Security Policy 4.1 issue? Separate from this fix.
   *Owner: PM with Nadia.*
8. **Accidental declines.** Should a turn-down get a short undo window,
   especially if R2 makes declines cheaper? Separate from this fix.
   *Owner: Sofia.*
