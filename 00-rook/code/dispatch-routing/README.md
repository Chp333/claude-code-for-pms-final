# dispatch-routing

The part of Dispatch that decides who gets asked to take a callout,
puts the offer on their phone, and waits for an answer.

- `config.py` — the tuning values. Timeout, weights, points.
- `routing.py` — ranks the available responders for one callout.
- `offer.py` — pushes the offer and waits; walks down the list.
- `history.py` — the recent-acceptance score.
- `availability.py` — who's free, where they are, travel time.

Nothing in here decides *whether* somebody gets asked. It decides the
order. Everyone available is on the list.

Owner: the staff engineer who built it. Ask the engineering manager if
she's out.
