# Acceptance

Status: ready-for-human
Blocked by: 01, 02, 03, 04, 05, 06, 07, 08
Spec: ../spec.md

## What to do

On the user's Intel Mac, with a clean release build, run the six done criteria in `../spec.md` again and record the results here. That includes the 1,000-book timing and the **Linux round trip**:
1. Add books on Linux, copy the data folder to the Mac, and they appear (covers made by 07) and open when the home layout matches.
2. Add books on the Mac, copy back, and Linux lists them, ignoring the macOS side files.
3. Remove a book on one machine, copy over, and the other stays consistent.

## Done when

- [ ] All six criteria pass, or each failure has its own ticket.
