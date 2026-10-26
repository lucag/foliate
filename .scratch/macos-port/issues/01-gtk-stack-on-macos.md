# Research: Can GTK4, libadwaita, GJS and WebKitGTK 6.0 run on macOS?

Type: research
Status: resolved
Map: ../map.md

## Question

Can the current Linux stack (GJS ≥ 1.82, GTK4 ≥ 4.12, libadwaita ≥ 1.8, WebKitGTK 6.0 ≥ 2.40.1) build and run on macOS 14+, on both Apple Silicon and Intel? What is the state of each component in Homebrew and MacPorts? Does upstream WebKitGTK support macOS, and what are the known breakages? Has anyone bundled such an app into a `.app` (gtk-mac-bundler, gtk-osx), and what do GTK4 apps look and feel like on macOS? The answer decides whether option (a) is viable and whether the from-source build task is worth attempting.

## Context

Findings: branch `research/gtk-stack-on-macos`, file `.scratch/macos-port/research/gtk-stack-on-macos.md`.

## Answer

**GTK4, libadwaita and GJS are fine on macOS. WebKitGTK 6.0 has no working macOS build anywhere.**

- **Homebrew:** `gtk4` 4.24.1, `libadwaita` 1.10.0, `gjs` 1.90.1. Bottles exist for Apple Silicon on macOS 15+ only; macOS 14 and Intel build from source. Homebrew moved Intel to its lowest support tier in Sept 2026 and plans to drop it in or after Sept 2027.
- **MacPorts:** `gtk4` 4.22.4 `+quartz`, `libadwaita` 1.9.3, `gjs-devel` 1.82.1. The plain `gjs` port (1.80.1) is too old.
- **WebKitGTK 6.0 (GTK4 API):**
  - Homebrew's `webkitgtk` is Linux-only and GTK3.
  - MacPorts' `webkit2-gtk` 2.52.4 is GTK3-only, with about 35 Darwin patches: stubbed EGL (no GPU compositing or WebGL), socket and bmalloc workarounds, and no universal build.
  - nixpkgs `webkitgtk_6_0` is marked broken on Darwin.
  - gtk-osx is frozen at WebKitGTK 2.32 for GTK3.
  - Upstream keeps `ENABLE_QUARTZ_TARGET`, but macOS is unsupported. The tracker bug (126492) has been dormant since 2017.
- **Bundling:** GTK3 + WebKitGTK apps ship as `.app` bundles (GnuCash, via gtk-mac-bundler, with separate arm64 and x86_64 builds). GTK4 + libadwaita apps ship too (Pinta 3, Gaphor), but none was found embedding WebKitGTK 6.0, and none uses GJS. GTK4 looks like Adwaita, not AppKit, though it gets native window buttons, dark-mode and accent following, and macOS keybindings.
- **Verdict:** option (a) requires us to get WebKitGTK 6.0 building on macOS ourselves. The from-source build is **plausible only as a strictly time-boxed experiment**. Its result would be an untested web view without GPU acceleration, with a patch set to re-apply on every WebKit release.
- **Unverified:** MacPorts buildbot results for `+quartz` (pages returned 403).

The full findings, with 33 sources, are on branch `research/gtk-stack-on-macos`, commit `8697552`.
