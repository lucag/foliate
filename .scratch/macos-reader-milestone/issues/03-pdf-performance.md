# PDF performance

Status: needs-info
Blocked by: 01
Condition: run only if 01's timings miss the targets (first page < 2 s, page turn < 300 ms). Otherwise close it as `wontfix`. Nothing else waits on it.
Spec: ../spec.md

## What to do

Find where the time goes, using Web Inspector timelines: the worker (main thread or not), canvas size and Retina scaling (`devicePixelRatio`), and pre-rendering of neighbouring pages. Fix it in the Shell if possible. Any foliate-js change follows the decision in `.scratch/macos-port/issues/11-foliate-js-upstream-or-fork.md`.

## Done when

- [ ] Timings measured again on the user's Intel Mac meet the targets, and are recorded in this ticket.
