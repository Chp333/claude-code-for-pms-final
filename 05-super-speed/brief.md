# Second-Round Pings: a strict 60 seconds, without losing people to it

One-pager · Product, Dispatch · 7 November 2026 · For: Helen Achebe
Detail behind every line: `missed-ping-requirements.md` (v0.7) and
`04-x-ray-vision/ping_sim.py`.

## The decision I'm asking for
Approve **Second-Round Pings**. Every responder gets exactly 60 seconds per
offer, and nothing counts after that. Instead of a longer wait, we help
people answer inside 60 seconds. Before a callout is marked "nobody went",
it goes back to anyone who missed it, with a fresh 60 seconds.

Don't approve Engineering's one-line fix on its own. Changing the penalty
number stops responders being buried, but callouts where nobody goes stay
about three times the pre-4.2 level (see "What we tested").

## What it's like today
**Kip** looks after two responders. In his interview he describes their two
coverage cards, side by side, as looking like two different products:

- **Meteor Mite** went from about 11 pings a week to about 4. Mite has been
  texting Kip asking if something's broken. All Kip can say is "hang in
  there, it'll pick up".
- **The Gale**, in the same city in the same weeks, gets 42% more pings and
  is exhausted.
- Both cards make the same "bing", so at 2am Kip has to look to see which
  responder it is.

**Why it happens:**
- 4.2 cut the wait from 90 to 60 seconds. Every turn-down in our data takes
  40 seconds or less, so anyone still deciding at 60 seconds was about to say
  yes. The cut threw away roughly **1 in 5 yeses**.
- The code scores that missed yes exactly like a no (−0.12, against +0.08 for
  a yes). The score never recovers on its own, which is the question Wen left
  in a note next to the code in 2019.
- Four responders (Meteor Mite, Vesper, Farlight and The Undertow) missed 3%
  of pings with 90 seconds but about 60% with 60. By our estimate they take
  about a minute to say yes. They sank to the bottom of the list, stayed
  there, and their work moved to people like The Gale.

## What we'd build

| Who | What they notice |
|---|---|
| **Responder, phone** | **A heads-up** when they're next in line: *"You may be next for a callout near you."* They can reach their phone before their 60 seconds start. **One-tap Take or Decline** on a full-screen alert, without unlocking. Tickets say "by the time i unlocked it, gone". A missed ping says *"Missed this one. If nobody else can go, it'll come back to you."* instead of silently disappearing. |
| **Handler, console** | A live alert the moment their responder is pinged, with time left (R12), and a different sound for each responder (R13). The console doesn't sign them out while they're watching (R22). After 3 misses in a row, a nudge to check the phone (R4). Each card shows *"pings this week vs usual"* (R14), so a quiet week looks like a pattern, not a coincidence. |
| **Under the hood** | **Second round:** before a callout is marked "nobody went", it's offered again, in ranked order, to anyone who missed it, with a fresh 60 seconds each. A miss counts less than a no (R2). Answering in time earns a little, and a yes earns more. Scores drift back to the middle over a few days, so anyone can build back up (R1, Wen's 2019 question answered). The four stuck responders are reset on release day (R5). Dispatch records when each ping reaches the phone and when it's answered (R6). |

## What we tested
A simulation calibrated to the real ping data. **Every design uses a strict
60 seconds** except the 4.1 reference row.

| Design | Callouts where nobody went | Time to a yes (typical / slowest 10%) | The four's pings | Longest gap for any of the four |
|---|---|---|---|---|
| 4.1 reference (90 s wait) | 5.5% | 51 / 83 s | +3% | 4.6 days |
| 4.2 as shipped | 16.7% | 44 / 96 s | −14% | 4.5 days |
| Fix the scoring only | 16.5% | 46 / 102 s | +6% | 3.6 days |
| Ask two people at once | 16.6% | 37 / 57 s | +67% | 2.5 days |
| Second round only | 4.8% | 50 / 114 s | +28% | 3.7 days |
| **Second-Round Pings** (second round, heads-up, one-tap) | **4.9%** | **40 / 73 s** | **+15%** | **3.4 days** |

- **The second round does most of the work.** It brings "nobody went" back
  below the pre-4.2 level, even if the heads-up and one-tap yes help only half
  as much as I assumed (4.5%).
- **The heads-up and one-tap yes are what make it fast.** On their own, the
  second rounds make the slowest callouts slower. With them, Dispatch places
  callouts faster than 4.1 did with 90 seconds.
- **Asking two people at once is fast but doesn't help.** It doubles the
  pings and leaves "nobody went" where it is.

The model shows direction, not a forecast. It understates how badly the
four were hit, and the size of the heads-up and one-tap effects needs real
answer times (R6) to confirm.

## Does it fix all the bugs?

| Problem | Fixed by this? |
|---|---|
| Missed pings scored as refusals | ✅ R2 |
| Scores never recover; four responders stuck at the bottom | ✅ R1 + R5 |
| Yeses lost because 60 seconds is tight for some people | ✅ heads-up, one-tap yes and the second round, all within 60 seconds |
| Handler doesn't know a callout is live; same sound for every responder | ✅ R12, R13, R22 |
| No record of delivery or answer times | ✅ R6 |
| Countdown starts when the ping is sent, not when it arrives | ⚠️ R8, only if R6 shows a real delivery delay |
| 46 open ping tickets with no reply | ⚠️ separate: R9, Support can start this week |
| Callouts coming in fell 12% from 12 Aug | ❌ cause unknown. Asking Marcus where callouts come from; may be the 4.2 filter change (R16) |
| People without the needed skills can be asked first | ❌ open question for Wen |
| Phone numbers that won't save; filters resetting | ❌ separate, lower-priority fixes (R19, R16) |

## Ruled out
- **A longer wait, or extra time after 60 seconds.** Breaks the 60-second rule.
- **Asking two people at once.** Fast, but doubles pings and doesn't fix
  "nobody went".
- **The one-line scoring fix alone.** Stops the burying but not the lost
  callouts.

## Not in scope
- **Undoing the 4.2 proximity change.** Responders across wide areas asked
  for it, and Priya was right that reverting it trades one unhappy group for
  another.
- The Handler Phone App, dark mode and the Supply issues.

## How we'll know it worked (4 weeks after release)
- Callouts where nobody went at or below **5.5% for 4 weeks in a row** (11.1% now).
- Missed pings below **12%** of all pings (18% now).
- **9 in 10 callouts placed within 90 seconds** of the first ping.
- **No responder's share of pings more than 10% below their usual**, unless
  their availability changed.
- Repeat "my responder has gone quiet" tickets fall to **zero**, and
  acceptance rate is back to **76% or more**.

## Who and what it needs
- **Wen:** the second round and the scoring changes. Confirm where scores are
  stored, since they sit in the program's memory today.
- **Sofia:** heads-up, one-tap alert and console screens.
- **Ravi:** weekly metrics (R7).
- **Nadia:** the interim reply (R9).
- **Before release:** a Security Policy 4.1 review for the live handler alert
  and the new timing data, and replaying June–September pings through the new
  rules (release gate).

## Decisions for you
1. Approve Second-Round Pings in place of the one-line fix.
2. Is this 4.3 scope, and does it push back Requisition Approval Chains?
3. Heads-ups go to people who may not end up getting the callout. Is that
   acceptable noise, or should they only go out when the next person is very
   likely to be asked?
