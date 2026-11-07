# Acceptance criteria: Dispatch 4.2 recovery prototype

QA run · 7 November 2026 · **Approved by the PM on 7 Nov, not yet run.**

- **Totals:** 108 criteria. 96 to test, 12 not testable here, 12 inferred.

**Decisions recorded at approval:**
- **DR-07:** an excused release gets no credit for the accept and no penalty.
- **DR-19:** both handler-alert triggers are required: 3 pings, or 3 minutes.
- **DR-06:** merged into DR-11. AC-06-1 and AC-06-2 are removed; AC-06-3 is now AC-11-5. AC-11-4 and AC-11-6 were added to cover the merged rule.

- **Briefs:** `dispatch-recovery-requirements.md` (v1.1, DR-01 to DR-32; DR-06 merged into DR-11) and
  `05-super-speed/Quiet-Responders-Director-Brief.docx` (Helen's brief, 13 promises, H-01 to H-13).
- **Build under test:** `05-super-speed/prototype/index.html`, standing in for staging.
- **How to read this:** each criterion is written as Given / When / Then, so anyone can run it
  and get the same answer.
  - **Priority:** **Must** means the requirement fails without it; **Should** means it's
    important but not a blocker.
  - **Method:** **UI** means clicking through it like a user; **Scripted** means using page
    scripting to set up or read state; **Visual** means checking the layout; **Not testable**
    means it can't be seen in this build.
  - **Inferred = yes** means I added it; the brief doesn't say it directly.
- **Rules that apply to everything** (from section 2 of the requirements):
  - **G1:** ask the nearest responder first.
  - **G2:** fast hand-off when nobody answers.
  - **G3:** saved filters work.
  - **C1:** no ping open more than 60 seconds after it was sent.
  - **C2:** nothing reveals that someone is a responder.
  - **C3:** Supply only reads the availability record.

---

## A. Scoring

### DR-01 · A "no" costs less than a miss
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-01-1 | Given the fixes are on, when a responder declines, then their standing drops by half a point's weight (0.5), and when they miss a delivered ping it drops by a full point (1.0). | Must | Scripted | |
| AC-01-2 | Given a responder declines, then the next responder is asked immediately (within 1 second), not after 60 seconds. | Must | UI | |
| AC-01-3 | Given two responders identical except one has 10 "no"s and the other 10 misses, then the one with the "no"s ranks higher. | Must | Scripted | |
| AC-01-4 | The weights shown satisfy: release (1.5) ≥ miss (1.0) > "no" (0.5) > 0, and the miss weight is no heavier than a "no" was under 4.2. | Must | Scripted | |

### DR-02 · Score recovers over a time window
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-02-1 | Given Vesper's August record, when time moves past the window with no new pings, then her score returns to 0.75. | Must | Scripted | |
| AC-02-2 | Given the window is changed between 3, 14 and 30 days, then the score is recalculated using only outcomes inside that window. | Must | UI | |
| AC-02-3 | Given a responder with very few pings, when they miss one, then their score does not drop to 0.5 or below (it is blended toward 0.75). | Should | Scripted | |
| AC-02-4 | The window is measured in days, not in a number of pings: a responder who gets no pings still recovers. | Must | Scripted | |

### DR-03 · Floor on the score
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-03-1 | Given any responder's raw score is below 0.6, then the score used for ranking is 0.6. | Must | Scripted | |
| AC-03-2 | Given an Old Town callout, then Vesper (2 minutes away) is ranked first, and the ranking shows her record costs her no more than about 3.5 minutes of travel. | Must | UI | |
| AC-03-3 | Given the fixes are switched off (4.2 as shipped), then Vesper ranks last and her record costs about 19 minutes. This proves the before/after comparison is real. | Should | UI | yes |

### DR-04 · Recovery boost
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-04-1 | Given each of Vesper, Farlight, The Undertow and Meteor Mite, then 7 to 8 accepts in a row bring them to the middle score. | Must | Scripted | |
| AC-04-2 | Given a responder at or above the middle, then an accept counts once, not three times. | Must | Scripted | |
| AC-04-3 | Given the boost is on, then misses and "no"s still cost exactly the same as without it. | Must | Scripted | |

### DR-05 · No penalty for out-of-area declines
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-05-1 | Given Nightwell (Midtown) is asked about an Old Town callout, when she declines, then her score is unchanged and her phone says it doesn't affect her standing. | Must | UI | |
| AC-05-2 | Given the same out-of-area ping, when she misses it instead, then the miss does count. | Must | Scripted | |

### DR-06 · Merged into DR-11
The PM decided on 7 Nov to merge this into DR-11 (requirements v1.1).
- AC-06-1 and AC-06-2 (the "arrived with under 45 seconds left" rule) are removed. With DR-11 on, that case can't happen.
- AC-06-3 moves to DR-11 as AC-11-5.

### DR-07 · Release after accepting is the costliest outcome
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-07-1 | Given a responder has accepted, when they tap "Can't make it", then the callout immediately goes to the next responder. | Must | UI | |
| AC-07-2 | When the handler marks the release as not excused, then the responder's score ends lower than if they had simply said "no", including while the boost is active. | Must | Scripted | |
| AC-07-3 | When the handler marks the release excused (with a reason), then no penalty is applied, the accept no longer counts toward their score, and the reason is stored. | Must | UI | |
| AC-07-4 | Given a responder has accepted, when they tap "I'm on scene", then the arrival time is recorded. | Must | UI | |
| AC-07-5 | Given a callout has been taken, when the handler reassigns it to someone else, then it counts as a release for the original responder. | Must | UI | |

### DR-08 · Recompute everyone at switch-on (scores part only)
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-08-1 | Given the fixes are switched on, then every responder has a score calculated with the new rules, and none of the four quiet responders is ranked below 0.6. | Must | Scripted | |
| AC-08-2 | Advance notice to handlers before switch-on. | Must | Not testable: an operational step, not a build feature | |

### DR-09 · Scores survive a deploy
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-09-1 | Scores are identical before and after a restart. | Must | Not testable: needs a real server and database; the prototype only illustrates it | |

## B. Availability and reachability

### DR-10 · Streak check → confirm availability
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-10-1 | Given 3 delivered misses in a row, then the responder is paused, their phone asks "Still available?", and the handler's console shows why. | Must | UI | |
| AC-10-2 | Given 5 "no"s in a row, then the responder is paused in the same way. | Must | Scripted | |
| AC-10-3 | When the responder (or handler) taps once, then they are available again and their score was not lowered by the pause. | Must | UI | |
| AC-10-4 | While paused, the responder is not asked about new callouts. | Must | Scripted | yes |
| AC-10-5 | The pause is not written to the record Supply reads. | Must | Not testable: no Supply system in the build | |

### DR-11 · Undelivered pings move on early and never count against the responder (includes former DR-06)
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-11-1 | Given the phone has no signal, then after 15 seconds without a delivery receipt the callout goes to the next responder. | Must | UI | |
| AC-11-2 | Given 2 undelivered pings in a row, then the responder is marked unreachable, routing skips them, and the handler sees why. | Must | UI | |
| AC-11-3 | When the phone gets signal again, then the responder becomes reachable, and the old request never appears as live; it shows as "already covered". | Must | UI | |
| AC-11-4 | Given a ping the phone never confirmed, then the responder's score is exactly the same before and after it. | Must | Scripted | |
| AC-11-5 | Every ping in the timeline shows when it was sent and when it reached the phone (moved from AC-06-3). | Must | UI | |
| AC-11-6 | Given a ping is delivered promptly (within 15 seconds) and then missed, then the miss does count. This makes sure the rule only protects pings that genuinely never arrived. | Must | Scripted | yes |

## C. Answering inside 60 seconds

### DR-12 · Hard 60-second limit (also constraint C1)
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-12-1 | Across every scenario run in this test, no ping is open for more than 60 seconds after it was sent. | Must | Scripted | |
| AC-12-2 | With every fix switched on at once (including overlap), no responder's ping stays open beyond 60 seconds from its own send. | Must | Scripted | yes |

### DR-13 · Answer from the lock screen without exposing anyone
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-13-1 | Given the phone is locked, then the lock screen shows only "New request": no area, no incident text, no cover name, no "Rook". | Must | UI | |
| AC-13-2 | When the responder accepts from the lock screen, then a fingerprint or face check is required first. | Must | UI | |
| AC-13-3 | The responder can decline from the lock screen without unlocking. | Should | UI | |

### DR-14 · Hard-to-miss alert
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-14-1 | Given a ping arrives, then it takes over the whole phone screen. | Must | UI | |
| AC-14-2 | Given the responder has a watch, then the watch shows the request with the same generic text as the lock screen. | Should | UI | |
| AC-14-3 | The responder can turn "break through silent mode" on or off, and schedule it; it is off by default. | Must | UI | |

### DR-15 · Countdown on the alert
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-15-1 | The countdown on the phone matches the real time left to within 2 seconds. | Must | Scripted | |
| AC-15-2 | The countdown changes colour as time runs low. | Should | Visual | yes |

### DR-16 · Reliable, fast delivery
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-16-1 | Given the first send fails, then it is retried automatically and reaches the phone. | Must | UI | |
| AC-16-2 | The retried ping appears on the phone once, not twice. | Must | UI | |

### DR-17 · Change a "no" to accept within 5 seconds
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-17-1 | When a responder declines, then the next responder is asked immediately (no 5-second hold). | Must | UI | |
| AC-17-2 | Within 5 seconds, "Change to accept" gives them the callout and the next responder's ping is withdrawn at no cost to that responder. | Must | UI | |
| AC-17-3 | After 5 seconds the option disappears. | Must | UI | |
| AC-17-4 | Undo can only turn a "no" into an accept; it can't erase a "no" and leave the callout with someone else. | Must | Scripted | |
| AC-17-5 | Decline is physically separated from Accept, or is a swipe, as the brief says. | Must | UI | |

## D. Routing

### DR-18 · Keep 4.2's ranking weights
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-18-1 | The ranking uses proximity 0.60, recent acceptance 0.25, capability 0.15. | Must | Scripted | |
| AC-18-2 | A responder 5 minutes away is always ranked above one 40 minutes away, whatever their records. | Must | Scripted | yes |

### DR-19 · Keep working down the list; escalate to the handler
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-19-1 | Given the first responder declines, then the next available responder is asked, and so on, until someone accepts or nobody is left. | Must | UI | |
| AC-19-2 | After 3 pings without a yes, then the handler is alerted and can assign someone directly. | Must | UI | |
| AC-19-3 | After 3 minutes without a yes (even with fewer than 3 pings), then the handler is alerted. | Must | Scripted | |
| AC-19-4 | An assignment by the handler is logged as an override. | Must | UI | |

### DR-20 · Nearest capable responder
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-20-1 | A handler can edit their responder's skill tags from the console. | Must | UI | |
| AC-20-2 | With the skills filter switched on, a responder without the needed skill is not asked. | Must | UI | |

### DR-21 · Overlapping offers (deferred)
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-21-1 | At 45 seconds the next responder is put on standby, and the first keeps priority until their 60 seconds end. | Must | UI | |
| AC-21-2 | If the first says yes before 60 seconds, they get it, and the standby is told it's covered at no cost. | Must | UI | |
| AC-21-3 | If the first doesn't answer, the standby who said yes gets it at the 60-second mark. | Must | Scripted | |
| AC-21-4 | No standby during bulk callouts. | Should | Not testable: the build has no bulk callouts | |

### DR-22 · Monitor load; no cap
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-22-1 | When a responder's pings this week are more than 30% above their usual, then their handler sees a flag. | Must | UI | |
| AC-22-2 | There is no cap: a busy responder who is nearest is still asked first. | Must | Scripted | |

## E. Handlers and responders

### DR-23 · Tell the handler when their responder is pinged
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-23-1 | When a responder is pinged, then their handler's console shows it within 2 seconds, with the time left. | Must | UI | |
| AC-23-2 | The handler's alert has no accept button. | Must | UI | |
| AC-23-3 | Each responder has their own sound. | Should | UI | |
| AC-23-4 | The handler can mute alerts for one responder. | Should | UI | |
| AC-23-5 | The alert never covers other controls on the console. | Must | Visual | yes |

### DR-24 · Standing in plain words
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-24-1 | A responder below normal sees, on their phone, why and what gets them back, in words with no score numbers. | Must | UI | |
| AC-24-2 | Their handler sees the same words on that responder's card. | Must | UI | |
| AC-24-3 | A handler's console shows standing only for their own responders. | Must | UI | |
| AC-24-4 | The message updates straight after the responder's next accept. | Should | Scripted | |

### DR-25 · Finish filter persistence safely (also G3)
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-25-1 | Given a callout involves the handler's own responder, then no filter hides it. | Must | UI | |
| AC-25-2 | When an update resets filters, then the handler is told and can restore them in one click. | Must | UI | |
| AC-25-3 | Two people signed in on the same computer each see their own filters. | Must | UI | |
| AC-25-4 | "Clear all" removes all filters, and the "filter on" badge is clearly visible while any filter is on. | Must | UI | |
| AC-25-5 | After "Clear all", one tap restores the last set. | Should | UI | |
| AC-25-6 | Filters follow the handler to another computer. | Should | Not testable: needs real accounts | |

## F. Measurement and safety

### DR-26 · Record what happens to each ping
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-26-1 | For a ping that is accepted and reaches the scene, the timeline shows sent, delivered, answered and on-scene times. | Must | UI | |
| AC-26-2 | These fields are stored for at least 99% of pings. | Must | Not testable: needs the real database | |

### DR-27 · New headline measures and guardrails
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-27-1 | Definitions agreed with Ravi; guardrail alert thresholds set; Helen signs off. | Must | Not testable: decisions, not build features | |

### DR-28 · Replay, shadow run, per-rule switches (switches part only)
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-28-1 | Each rule has its own switch, and turning one off changes only that behaviour. | Must | UI | |
| AC-28-2 | Replay of real pings passes the release gate; shadow run done. | Must | Not testable: needs real data and a live system | |

### DR-29 to DR-32 · Operations
| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-29-1 | Supply signs off on availability changes. | Must | Not testable: a sign-off, not a build feature | |
| AC-30-1 | All 45 open ping tickets answered; the four handlers phoned. | Must | Not testable: support work | |
| AC-31-1 | Written answer on why fewer callouts came in. | Should | Not testable: an investigation | |
| AC-32-1 | Roadmap owners reassigned and reviewed with Helen. | Should | Not testable: a roadmap task | |

## H. Promises in Helen's brief

| ID | Promise (from the director brief) | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-H-01 | Vesper is first in line for Old Town from day one; a bad record costs at most about 3 minutes, not 19. | Must | UI | |
| AC-H-02 | Her app and Dot's console show a plain message like "Lower priority: 3 recent misses. Back to normal in about a week of normal work." | Must | UI | |
| AC-H-03 | About 7–8 accepts bring her back to the middle. | Must | Scripted | |
| AC-H-04 | Meteor Mite's card on Kip's console says why it's quiet and when that ends. | Must | UI | |
| AC-H-05 | The Gale's load drops back toward normal once Eastgate is shared by distance. | Should | Scripted | |
| AC-H-06 | A different sound per responder, and a flag when load runs 30% above usual. | Must | UI | |
| AC-H-07 | Accept from the lock screen with a fingerprint; the lock screen shows only "New request". | Must | UI | |
| AC-H-08 | A full-screen alert with a countdown. | Must | UI | |
| AC-H-09 | Mr. Ambrose is notified the moment the ping goes out; a mis-tapped "no" can become a yes within 5 seconds. | Must | UI | |
| AC-H-10 | After 3 misses in a row: "still available?", the handler is told, and one tap brings them back. | Must | UI | |
| AC-H-11 | Nearest first is kept (weights unchanged); 60 seconds is a hard limit; undelivered pings move on at 15 seconds. | Must | Scripted | |
| AC-H-12 | Saved filters stay, with no silent resets, separate sign-ins, and never hiding your own responder. | Must | UI | |
| AC-H-13 | There is something to click through showing the responder lock screen, the standing message and Kip's card. | Must | UI | |

## W. Whole-build checks

| ID | Criterion | Priority | Method | Inferred |
|---|---|---|---|---|
| AC-W-1 | No errors in the browser console during any test. | Must | Scripted | yes |
| AC-W-2 | Usable at phone width with no sideways scrolling. | Should | Visual | yes |
| AC-W-3 | Text and buttons are readable in both light and dark mode. | Should | Visual | yes |
| AC-W-4 | Nothing covers the buttons people need (notifications, highlights, captions). | Must | Visual | yes |
| AC-W-5 | Every one of the 34 walkthrough steps plays to the end without an error, and Pause stops it. | Must | Scripted | yes |
