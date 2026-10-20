# Design kit update — Oct 6, 2026

Unzip over your existing `design/` folder. Only the files below are included; everything else in the kit is unchanged.

## Added

| File | What it is |
|---|---|
| `source/DocRenewal.dc.html` | 3.14 · Upload a renewal: three ways to add it, then the "reading your renewal" state with the keystone loader |
| `source/DocRenewalReview.dc.html` | 3.15 · What changed: old vs new for term, premium, coverage, deductible and policy number; save options; saved state |
| `screens/s01-docs/10b-DocRenewal.png` | Upload screen |
| `screens/s01-docs/10c-DocRenewal-reading.png` | Same screen, reading state |
| `screens/s01-docs/10d-DocRenewalReview.png` | What changed, before saving |
| `screens/s01-docs/10e-DocRenewalReview-saved.png` | After saving (lime "Renewed through Oct 13, 2027" + Undo) |

## Changed

| File | What changed |
|---|---|
| `source/DocsExpiring.dc.html` | The homeowners policy's "Upload renewal" button now opens `DocRenewal` (it used to open the generic Add from… sheet) |
| `screens/s01-docs/10-DocsExpiring.png` | Re-rendered; looks the same |
| `BUILD_ORDER.md` | Chunk 1.5 is now "Expiring + renewals" with a new commit `1.5b`; Sprint 1 is 14 screens / 13 commits; totals 121 / 108 |

## Behaviour to build (1.5b)

- Saving a renewal creates a new document version; the previous policy moves to "Already ended · kept for claims history" when the switch is on (default on).
- "Update Insurance in Emergency" (default on) writes the new premium, coverage and dates to the policy record used offline.
- The renewal reminder resets from the new end date: 60 / 30 / 14 days before (default 30 → Sep 13, 2027).
- Undo is available after saving (5 s snackbar pattern applies everywhere else; here the lime card holds Undo until you leave the screen).
- Every value read by Smart Scan can be tapped and corrected before saving.
