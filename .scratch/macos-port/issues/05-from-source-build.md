# Task: Try a from-source build of the GTK app on Intel macOS

Type: task
Status: wontfix
Blocked by: 01
Map: ../map.md

## Question

If the GTK stack research says a build is plausible, try building and running the current app from source on the user's Intel Mac (Homebrew/MacPorts dependencies, `meson`/`ninja`). Record exactly which dependencies installed, which steps failed and with what errors, and whether a book opens and renders. Confirm with the user before installing system packages. If the research says it is not plausible, rule this ticket out of scope instead.

## Context

The GTK stack research says this is plausible only as a **strictly time-boxed experiment**. GTK4, libadwaita and GJS come from Homebrew or MacPorts. The real question is whether WebKitGTK 6.0 (GTK4 API, `ENABLE_QUARTZ_TARGET`) can be built at all; the MacPorts `webkit2-gtk` Darwin patch set and the nixpkgs Darwin flags are the starting points. Agree on the time box with the user before starting. Record the outcome as risk evidence for choosing the approach.

## Comments

Ruled out of scope by the user, after the GTK stack research found no working WebKitGTK 6.0 build on macOS. The porting decision will rest on research alone.
