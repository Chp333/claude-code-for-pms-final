"""Ping simulation: what happens to callouts and responders under different
scoring rules and ping waits.

Mirrors the real timeline: 44 days on 4.1 rules (29 Jun - 11 Aug), then
26 days on the rules being tested (12 Aug - 6 Sep). Everything is averaged
over many runs with different random seeds.

Calibrated to the rook-database pings table (see CALIBRATION below). It is a
model, not a replay: there's no travel-time, tag or answer-time data, so those
parts are assumptions, listed at the top.

How well it fits: under 4.1 rules it matches the real callout numbers
(nobody went, misses, pings per callout). Under 4.2 it gets the direction
right but overshoots "nobody went" (about 16% vs 11.1% real) and only
reproduces part of the four responders' drop in pings (about -14% vs -69%
real). So read its fairness numbers as conservative, and compare policies
with each other rather than reading any number as a forecast. The
conclusions hold at neighbour travel times of 8-24, 10-30 and 15-40 minutes.

Run:  python ping_sim.py
"""

import math
import random
import statistics

# ---------------------------------------------------------------------------
# Assumptions and calibration (from the pings, callouts and responders tables)
# ---------------------------------------------------------------------------

AREAS = [  # area, home responders, callouts over the 70 days
    ("Eastgate", ["Meteor Mite", "The Gale"], 175),
    ("Foundry Row", ["Sgt. Bulwark"], 66),
    ("Greenway", ["The Drift"], 52),
    ("Harborside", ["The Undertow"], 95),
    ("Hillcrest", ["Captain Vantage"], 89),
    ("Kingsbridge", ["Sgt. Falkirk"], 82),
    ("Lakeshore", ["The Longcast"], 54),
    ("Midtown", ["Nightwell"], 114),
    ("Mill District", ["Cindermark"], 68),
    ("Northfield", ["Corporal Ashgrove"], 73),
    ("Old Town", ["Vesper"], 110),
    ("Riverside", ["Ironvale"], 64),
    ("Southport", ["Stormwrack"], 108),
    ("Uptown", ["Farlight"], 90),
    ("Westbury", ["Halfmoon"], 79),
]
DAYS_BEFORE, DAYS_AFTER = 44, 26
CALLOUTS_PER_DAY = 20.0            # 879 in 44 days before 4.2

# Each callout's list: available responders in its area and the two
# neighbouring areas. Gives lists of 1-4, like the real chains.
AVAILABLE_PROB = 0.80
BUSY_MINUTES = (45, 120)           # out of action after taking a callout

# How people answer. No's are quick: every turn-down in the data took
# 5-40 s (median 22), before and after 4.2. Yeses take longer. Two speed
# profiles, each fitted to its group's real misses at 90 s (before 4.2) and
# at 60 s (after):
#   steady: of the yeses, 3.8% came after 90 s but 72% after 60 s, so a
#           median yes of about 66 s with little spread. Reliable at 90 s.
#           (Fitted on only 56 post-4.2 pings.)
#   quick:  2.6% after 90 s, 17% after 60 s; median yes about 40 s.
P_NO = 0.215
NO_SECONDS = (5, 40)
STEADY = ("The Undertow", "Farlight", "Vesper", "Meteor Mite")
SPEED = {"steady": (math.log(66.0), 0.172), "quick": (math.log(40.0), 0.413)}
SPEED_SPREAD = 0.05                # small person-to-person variation

# Travel time: home area 3-12 min, a neighbouring area 10-30 min.
HOME_MINUTES, NEIGHBOUR_MINUTES = (3, 12), (10, 30)
OUTER_MINUTES = (25, 44)           # two areas away, only asked if "widen" is on
PROXIMITY_HORIZON = 45

CALIBRATION = {  # real numbers, for comparison
    "4.1 as it was (real, before 12 Aug)": dict(nobody=5.5, miss=2.3, ppc=1.23, first=73.2, home=80.0, steady=0.0),
    "4.2 as shipped (real, after 12 Aug)": dict(nobody=11.1, miss=18.0, ppc=1.39, first=58.4, home=61.0, steady=-69.0),
}

# ---------------------------------------------------------------------------
# Policies: the scoring rules and wait being tested
# ---------------------------------------------------------------------------

POLICIES = {
    "4.1 as it was": dict(
        wait=90, w_prox=0.45, w_score=0.40, yes=0.08, no=-0.12, miss=-0.12,
        half_life_days=None, grace=0),
    "4.2 as shipped": dict(
        wait=60, w_prox=0.60, w_score=0.25, yes=0.08, no=-0.12, miss=-0.12,
        half_life_days=None, grace=0),
    "A. Fix misses only (R1+R2)": dict(
        wait=60, w_prox=0.60, w_score=0.25, yes=0.08, no=-0.04, miss=-0.06,
        half_life_days=3, grace=0),
    "B. Reward answering in time": dict(
        wait=60, w_prox=0.60, w_score=0.25, yes=0.06, no=0.06, miss=-0.06,
        half_life_days=3, grace=0),
    "C. B + late yes still counts (30 s)": dict(
        wait=60, w_prox=0.60, w_score=0.25, yes=0.06, no=0.06, miss=-0.06,
        half_life_days=3, grace=30),
    "D. B with a 90 s wait": dict(
        wait=90, w_prox=0.60, w_score=0.25, yes=0.06, no=0.06, miss=-0.06,
        half_life_days=3, grace=0),
    # Designs that keep a strict 60 s for everyone (nothing counts after it).
    "E. B + offer again to anyone who missed": dict(
        wait=60, w_prox=0.60, w_score=0.25, yes=0.06, no=0.06, miss=-0.06,
        half_life_days=3, reoffer=True),
    "F. B + heads-up to next in line": dict(
        wait=60, w_prox=0.60, w_score=0.25, yes=0.06, no=0.06, miss=-0.06,
        half_life_days=3, headsup=0.5),
    "G. B + ask two at once": dict(
        wait=60, w_prox=0.60, w_score=0.25, yes=0.06, no=0.06, miss=-0.06,
        half_life_days=3, pair=True),
    "H. B + one-tap yes (10 s quicker)": dict(
        wait=60, w_prox=0.60, w_score=0.25, yes=0.06, no=0.06, miss=-0.06,
        half_life_days=3, faster=10),
    "I. B + E + F": dict(
        wait=60, w_prox=0.60, w_score=0.25, yes=0.06, no=0.06, miss=-0.06,
        half_life_days=3, reoffer=True, headsup=0.5),
    "J. B + E + F + H": dict(
        wait=60, w_prox=0.60, w_score=0.25, yes=0.06, no=0.06, miss=-0.06,
        half_life_days=3, reoffer=True, headsup=0.5, faster=10),
}
BEFORE_POLICY = POLICIES["4.1 as it was"]


# ---------------------------------------------------------------------------
# The model
# ---------------------------------------------------------------------------

class Responder:
    def __init__(self, name, area_index, rng):
        self.name = name
        self.area = area_index
        self.steady = name in STEADY
        self.yes_mu, self.yes_sigma = SPEED["steady" if self.steady else "quick"]
        self.speed = math.exp(rng.gauss(0, SPEED_SPREAD))
        self.score = 0.5
        self.score_time = 0.0      # minutes; when score was last updated
        self.busy_until = -1.0
        self.pings_before = 0
        self.pings_after = 0
        self.last_ping = None
        self.longest_gap_after = 0.0

    def current_score(self, now, policy):
        """Score now, easing back toward 0.5 if the policy has recovery."""
        hl = policy["half_life_days"]
        if hl:
            elapsed_days = (now - self.score_time) / 1440.0
            keep = 0.5 ** (elapsed_days / hl)
            self.score = 0.5 + (self.score - 0.5) * keep
        self.score_time = now
        return self.score

    def adjust(self, delta, now, policy):
        self.current_score(now, policy)
        self.score = max(0.0, min(1.0, self.score + delta))


def answer(responder, rng):
    """('no' or 'yes', seconds to answer) if they had all the time they need."""
    if rng.random() < P_NO:
        return "no", rng.uniform(*NO_SECONDS)
    secs = math.exp(rng.gauss(responder.yes_mu, responder.yes_sigma)) * responder.speed
    return "yes", secs


def record_ping(r, t, after, stats):
    if after:
        r.pings_after += 1
        if r.last_ping is not None:
            r.longest_gap_after = max(r.longest_gap_after, t - r.last_ping)
        r.last_ping = t
        stats["pings"] += 1
    else:
        r.pings_before += 1


def offer_callout(queue, pol, t, rng, after, stats):
    """Offer one callout down the ranked queue. Returns (winner, seconds from
    the first ping to the yes), or (None, seconds) if nobody took it.

    Options a policy can switch on, all keeping the ping wait itself:
      grace:   a yes up to this many seconds after the wait still counts
      pair:    offer to two people at once; first yes wins, the other is
               withdrawn with no penalty
      headsup: the next person in line is warned when the person ahead is
               pinged; this share of their head start comes off their time
               to say yes
      reoffer: before giving up, offer the callout again, with a fresh wait,
               to anyone who missed it
      faster:  seconds a quicker way to say yes (one tap from the lock
               screen) takes off every yes
    """
    wait = pol["wait"]
    group = 2 if pol.get("pair") else 1
    clock = 0.0                # seconds since the first ping
    prev_start = None          # when the previous ping went out
    late = None                # (responder, when their late yes lands)
    missed = []                # (responder, when their yes would have landed)
    for i in range(0, len(queue), group):
        batch = queue[i:i + group]
        answers = []
        for r in batch:
            record_ping(r, t, after, stats)
            kind, secs = answer(r, rng)
            if kind == "yes":
                secs = max(5.0, secs - pol.get("faster", 0))
                if pol.get("headsup") and prev_start is not None:
                    secs = max(5.0, secs - pol["headsup"] * (clock - prev_start))
            answers.append((r, kind, secs))
        in_time = [(clock + s, r, k) for r, k, s in answers if s <= wait]
        first_answer = min((a[0] for a in in_time), default=None)
        if late and (first_answer is None or late[1] < first_answer):
            late[0].adjust(pol["yes"], t, pol)
            return late[0], late[1]
        yeses = sorted((a for a in in_time if a[2] == "yes"), key=lambda a: a[0])
        if yeses:
            when, winner, _ = yeses[0]
            for r, k, s in answers:   # anyone who said no before the yes
                if r is not winner and k == "no" and clock + s < when:
                    r.adjust(pol["no"], t, pol)
            winner.adjust(pol["yes"], t, pol)
            if after and i == 0:
                stats["first_taken"] += 1
            return winner, when
        late = None
        for r, k, s in answers:
            if s <= wait:
                r.adjust(pol["no"], t, pol)
                continue
            r.adjust(pol["miss"], t, pol)
            if after:
                stats["missed"] += 1
            if k == "yes":
                missed.append((r, clock + s))
                if s <= wait + pol.get("grace", 0):
                    late = (r, clock + s)
        prev_start = clock
        clock += max(s if s <= wait else wait for _, _, s in answers)
    if late:  # nobody left to ask, but the late yes still lands
        late[0].adjust(pol["yes"], t, pol)
        return late[0], late[1]
    if pol.get("reoffer"):
        for r, lands in missed:
            record_ping(r, t, after, stats)
            if lands <= clock + wait:   # ready now, or answers within the wait
                when = max(lands, clock + rng.uniform(5, 15))
                if when <= clock + wait:
                    r.adjust(pol["yes"], t, pol)
                    return r, when
            r.adjust(pol["miss"], t, pol)
            if after:
                stats["missed"] += 1
            clock += wait
    return None, clock


def run(policy, seed):
    rng = random.Random(seed)
    responders = []
    for i, (_, names, _) in enumerate(AREAS):
        responders += [Responder(n, i, rng) for n in names]
    weights = [c for _, _, c in AREAS]
    n_areas = len(AREAS)

    stats = dict(callouts=0, nobody=0, pings=0, missed=0, first_taken=0,
                 home_first=0, secs_to_yes=[])
    t = 0.0
    end = (DAYS_BEFORE + DAYS_AFTER) * 1440.0
    while True:
        t += rng.expovariate(CALLOUTS_PER_DAY / 1440.0)
        if t >= end:
            break
        after = t >= DAYS_BEFORE * 1440.0
        pol = policy if after else BEFORE_POLICY
        area = rng.choices(range(n_areas), weights=weights)[0]
        region = {area, (area - 1) % n_areas, (area + 1) % n_areas}

        if pol.get("widen"):   # also ask the next ring of areas out
            region |= {(area - 2) % n_areas, (area + 2) % n_areas}

        candidates = []
        for r in responders:
            if r.area in region and r.busy_until <= t and rng.random() < AVAILABLE_PROB:
                ring = min((r.area - area) % n_areas, (area - r.area) % n_areas)
                lo, hi = (HOME_MINUTES, NEIGHBOUR_MINUTES, OUTER_MINUTES)[ring]
                minutes = rng.uniform(lo, hi)
                prox = max(0.0, 1.0 - minutes / PROXIMITY_HORIZON)
                s = pol["w_prox"] * prox + pol["w_score"] * r.current_score(t, pol) + 0.15
                candidates.append((s, r))
        if not candidates:
            continue  # real data only has callouts that got at least one ping
        candidates.sort(key=lambda c: c[0], reverse=True)

        if after:
            stats["callouts"] += 1
            stats["home_first"] += candidates[0][1].area == area
        winner, clock = offer_callout([r for _, r in candidates], pol, t, rng, after, stats)
        if winner is None:
            if after:
                stats["nobody"] += 1
        else:
            winner.busy_until = t + rng.uniform(*BUSY_MINUTES)
            if after:
                stats["secs_to_yes"].append(clock)

    shares = []
    for r in responders:
        before_rate = r.pings_before / DAYS_BEFORE
        after_rate = r.pings_after / DAYS_AFTER
        shares.append((r.name, before_rate, after_rate, r.longest_gap_after / 1440.0))
    return stats, shares


def summarise(policy, runs=40):
    rows = []
    for seed in range(runs):
        s, shares = run(policy, seed)
        yes_times = sorted(s["secs_to_yes"])
        steady = [100 * (a - b) / b for n, b, a, _ in shares if n in STEADY and b > 0]
        rows.append(dict(
            nobody=100 * s["nobody"] / s["callouts"],
            miss=100 * s["missed"] / s["pings"],
            ppc=s["pings"] / s["callouts"],
            first=100 * s["first_taken"] / s["callouts"],
            home=100 * s["home_first"] / s["callouts"],
            steady=statistics.mean(steady),
            median_yes=statistics.median(yes_times),
            p90_yes=yes_times[int(0.9 * len(yes_times))],
            gap=max(g for n, _, _, g in shares if n in STEADY),
        ))
    return {k: statistics.mean(r[k] for r in rows) for k in rows[0]}


HEADER = (f"{'':38} {'nobody':>7} {'missed':>7} {'pings/':>7} {'taken':>6} {'local':>6} "
          f"{'the four':>9} {'secs to yes':>12} {'four: longest':>14}\n"
          f"{'':38} {'went':>7} {'':>7} {'callout':>7} {'by 1st':>6} {'asked':>6} "
          f"{'pings':>9} {'median/90%':>12} {'gap (days)':>14}")


def main():
    print("Real data\n" + HEADER)
    for name, r in CALIBRATION.items():
        print(f"{name:38} {r['nobody']:>6.1f}% {r['miss']:>6.1f}% {r['ppc']:>7.2f} "
              f"{r['first']:>5.0f}% {r['home']:>5.0f}% {r['steady']:>8.0f}%")
    print("\nModel, 12 Aug - 6 Sep under each policy (average of 40 runs)\n" + HEADER)
    for name, p in POLICIES.items():
        r = summarise(p)
        print(f"{name:38} {r['nobody']:>6.1f}% {r['miss']:>6.1f}% {r['ppc']:>7.2f} "
              f"{r['first']:>5.0f}% {r['home']:>5.0f}% {r['steady']:>8.0f}% "
              f"{r['median_yes']:>5.0f} / {r['p90_yes']:>3.0f}s {r['gap']:>14.1f}")


if __name__ == "__main__":
    main()
