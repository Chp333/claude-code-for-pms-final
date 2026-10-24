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
