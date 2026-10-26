# Research: GTK4 / libadwaita / GJS / WebKitGTK 6.0 on macOS

Ticket: `.scratch/macos-port/issues/01-gtk-stack-on-macos.md`
Researched: 2026-10-25. Nothing was installed. Every fact below comes from formula or port files, upstream source, bug trackers or official docs, and each one cites its source. Lines marked **Inference** are my own reading, not something a source says.

## Answer

Three of the four components are packaged for macOS today: GTK4, libadwaita and GJS. They are current and meet Foliate's minimum versions. **WebKitGTK 6.0, the GTK4 API, has no working macOS build anywhere.** Homebrew's `webkitgtk` is Linux-only and built for GTK3. MacPorts' `webkit2-gtk` builds the GTK3 4.1 API and needs about 35 Darwin patches. nixpkgs' `webkitgtk_6_0` lists Darwin as a platform but marks it `broken`. gtk-osx stopped at WebKitGTK 2.32 on GTK3.

Upstream WebKit still has a Quartz target option in the GTK port, but nobody tests it. The macOS tracker bug has been dormant since 2017. So "port the GTK Shell as-is" can only work if we first get WebKitGTK 6.0 building and running on macOS ourselves.

A from-source attempt is **plausible as a time-boxed experiment**, starting from MacPorts' recent 2.52.4 patch set. The GTK4 delta has never been attempted in public, and hardware acceleration and WebGL will be off.

## 1. Component status by package manager

| Component (Foliate min) | Homebrew (homebrew-core) | MacPorts |
|---|---|---|
| GTK4 (≥ 4.12) | `gtk4` 4.24.1; bottles arm64 only (Sequoia 15, Tahoe 26, Golden Gate 27) [1] | `gtk4` 4.22.4; variants `quartz` / `x11` / `broadway`. The default `+x11` "cannot build", so use `+quartz` [2] |
| libadwaita (≥ 1.8) | `libadwaita` 1.10.0; arm64 bottles only [3] | `libadwaita` 1.9.3 (updated 2026-08-08 from 1.5.5) [4][5] |
| GJS (≥ 1.82) | `gjs` 1.90.1 (spidermonkey@140); arm64 bottles only [6] | `gjs` 1.80.1 (**too old**), `gjs-devel` 1.82.1 (just meets the minimum) [7][5] |
| WebKitGTK 6.0 (≥ 2.40.1) | `webkitgtk` 2.54.2 is **`depends_on :linux`** ("Use JavaScriptCore.Framework on macOS"), built with `-DUSE_GTK4=OFF` (GTK3 / 4.1 API). Linux bottles only [8][9] | `webkit2-gtk` / `webkit2-gtk-devel` 2.52.4 built with **`-DUSE_GTK4=OFF`** against gtk3. No GTK4 / webkitgtk-6.0 port exists [10][11][12] |

Notes:

- **Intel Macs.** Homebrew moved Intel x86_64 to Tier 3 in September 2026: no CI and no new bottles. Support is to be removed in or after September 2027. Tier 1 is Apple Silicon on macOS 15, 26 and 27. macOS 14 is no longer in Tier 1 [13][14]. On Intel, and on macOS 14, every Homebrew formula above therefore builds from source.
- **Apple Silicon.** macOS 14 on Apple Silicon also gets no Homebrew bottles any more [1][3][6][13].
- **Search across both trees.** Code search for `USE_GTK4` in macports-ports finds only the two `webkit2-gtk*` Portfiles, both set to `OFF`. Searching homebrew-core for `webkitgtk-6.0` finds only the Linux formula [12].
- **nixpkgs.** `webkitgtk_6_0` has Darwin code paths (`-DENABLE_QUARTZ_TARGET=ON`, `-DENABLE_X11_TARGET=OFF`, `-DUSE_OPENGL_OR_ES=OFF`, MiniBrowser off), but it sets `meta.broken = clangStdenv.hostPlatform.isDarwin` [15].

## 2. Upstream WebKitGTK and macOS

- **The option still exists.** `Source/cmake/OptionsGTK.cmake` on WebKit `main` still defines `ENABLE_QUARTZ_TARGET` ("support for the Quartz windowing target", default ON when GTK has Quartz) [16]. It also has `if (APPLE) set(ENABLE_GTKDOC OFF)` ("gtk-doc does not really work when building on Mac") [16]. `USE_GTK4` defaults to ON, so `-DPORT=GTK` builds webkitgtk-6.0 by default [16][17].
- **Linux-only defaults.** `USE_GBM` and `USE_LIBDRM` default to ON and fail hard if missing [16]. A macOS build must turn them off. `libepoxy` ≥ 1.5.4 is REQUIRED [16].
- **No official support.** webkitgtk.org lists no supported platforms and never mentions macOS [18].
  - The meta bug "[Meta] Tracker for webkit-gtk on OS X" (bug 126492) is still NEW and assigned to nobody. It was last modified 2017-03-11 and none of its comments mention GTK4 [19].
  - The last upstream macOS build fix was bug 225850 (r282061, September 2021), contributed by a nixpkgs packager "mostly done for fun". Michael Catanzaro commented: "It's probably been a long time since somebody got WebKitGTK to build on macOS." [20]
- **Breakage MacPorts had to patch in 2.52.4 (GTK3, 2026-04-29)** [10][11][21]. The update commit touches about 35 patch files:
  - ANGLE assumes `ANGLE_PLATFORM_LINUX` for GTK, so it is patched to `ANGLE_PLATFORM_APPLE`.
  - IPC: macOS lacks `SOCK_SEQPACKET`, so it uses `SOCK_DGRAM` with larger buffers, and Unix file descriptors are preferred over Mach messages.
  - The GTK tarball omits Apple-only WTF/Cocoa files that the code still includes, so empty stub headers are added.
  - bmalloc: TZONE is disabled, ProcessCheck is stubbed, and a private `pthread` call is replaced.
  - A Darwin SQLite init path deadlocks and is skipped.
  - **No EGL on macOS**: no-op EGL headers are added only so WebCore and Skia compile. The EGL paths "will never be taken at runtime" because there is no EGL display. WebGL is disabled.
  - **Universal (fat) builds are impossible**: "no success at building universal after considerable attempts" (trac #56792). Build each architecture separately.
  - Needs C++23 and Clang ≥ 1600.
  - The default variant is `+x11`. `+quartz` is opt-in and needs gtk3 `+quartz`.
- **Inference.** On macOS, WebKitGTK renders without GPU compositing and without WebGL, through Skia's CPU path. That should be acceptable for e-book HTML and CSS, but expect slower scrolling and animation. I could not verify, because ports.macports.org build pages returned 403 and trac was behind a bot wall, whether `+quartz` builds on the buildbots or runs correctly.

## 3. GTK4 and libadwaita on macOS: look and feel

- **Backend.** GTK4 has its own GDK macOS backend, a greenfield rewrite in 2020. It renders with Cairo (image surface) or the same OpenGL renderer as Linux, and its frame clock is driven by CVDisplayLink [22]. Vulkan goes through MoltenVK [23].
- **Window controls.** Since GTK 4.18, `GtkHeaderBar:use-native-controls` shows real macOS "traffic light" buttons, drawn by the OS. It is opt-in and only for toplevels. Only the leftmost header bar in a split layout should use it [23][24]. libadwaita 1.8 added the same for `AdwHeaderBar`, and 1.9 fixed title buttons [25].
- **Other libadwaita macOS work** [25]:
  - It follows the system color scheme (1.1) and partly supports the system accent color (1.6).
  - It supports high contrast (1.8).
  - It uses macOS keybindings in preferences and tab views (1.6) and shows macOS key labels (1.10).
- **Menus.** Standard edit and app shortcuts are registered automatically, and the Window menu needs `gtk-macos-special=window-submenu` [23].
- **Known gaps.** In early 2025, fractional scaling was broken with the GL renderer on macOS and the workaround was the Cairo renderer. A GdkKeymap fix shipped in 4.18.6 (via release-notes summary, not checked in GTK NEWS).
- **Overall feel.** The app still looks like Adwaita/GNOME, not AppKit. There are no native widgets, sheets, toolbars or vibrancy. **Inference** from the above: the result is "GNOME app with Mac window buttons and shortcuts".

## 4. Bundling into a `.app`

- **Official route.** gtk.org's macOS page recommends gtk-osx (jhbuild modulesets) to build and gtk-mac-bundler to make the `.app`. gtk-mac-bundler copies dependent libraries into the bundle and rewrites their install names [26]. GTK itself does not make bundles [23]. gtk-osx supports macOS releases up to five years old and needs at least 10.15 [27].
- **gtk-osx's WebKit module is stale.** It is still `webkit2gtk3` **2.32.0** (2021, GTK3), built with `-DENABLE_QUARTZ_TARGET=ON -DENABLE_X11_TARGET=OFF`, video, Web Audio and GL off, and six Darwin patches. There is no GTK4 WebKit module [28].
- **Shipped precedent (GTK3 + WebKitGTK).** GnuCash ships macOS bundles for Apple Silicon (macOS 11+) and Intel (10.13+). It builds WebKit2GTK through gtk-osx/jhbuild and bundles with gtk-mac-bundler. It notes the GTK stack "has never been cross-compiled", so each architecture needs a native build or Rosetta [29]. A July 2025 gnucash-devel thread shows someone on Sonoma 14.7.6 failing to get webkit2gtk from jhbuild. The maintainer's advice was to rebuild it and keep Homebrew out of the environment [30].
- **Shipped precedents (GTK4 + libadwaita, no WebKit):**
  - Pinta 3.x ships macOS DMGs for arm64 and x86_64. The Homebrew cask requires macOS ≥ 11 [31][32].
  - Gaphor bundles GTK4 and libadwaita from Homebrew with PyInstaller [33].
  - I found no public GJS-based `.app`. GJS bundling means shipping the `gjs` binary, SpiderMonkey, typelibs and `GI_TYPELIB_PATH` / `XDG_DATA_DIRS` fix-ups inside the bundle. **Inference**: gtk-mac-bundler can do this, as it does for PyGObject apps.
- **No precedent for the full stack.** I found no public example of a bundled GTK4 app that embeds WebKitGTK 6.0 on macOS.

## 5. Implications for option (a): port the GTK Shell as-is

1. Everything except WebKitGTK 6.0 is available on Apple Silicon (macOS 15+ bottles, or source builds on 14), and from source on Intel.
2. **The blocker is WebKitGTK 6.0.** The closest working baseline is MacPorts' `webkit2-gtk` 2.52.4: GTK3, about 35 patches, no EGL or WebGL, no universal build. A from-source attempt means:
   - forward-porting those patches to a 2.50 or later tarball with `-DUSE_GTK4=ON -DENABLE_QUARTZ_TARGET=ON -DENABLE_X11_TARGET=OFF -DENABLE_WAYLAND_TARGET=OFF -DUSE_GBM=OFF -DUSE_LIBDRM=OFF -DENABLE_WEBGL=OFF -DENABLE_BUBBLEWRAP_SANDBOX=OFF`;
   - linking against MacPorts or Homebrew `gtk4` built with Quartz;
   - then fixing whatever GTK4-specific code (the `WebKitWebViewBase` GTK4 paths and the display / backing-store code) assumes Wayland or X11.
3. **Maintenance cost.** Upstream does not test this. Every WebKit stable bump (roughly every six months, plus security releases) will need the patch set re-applied. We would also carry two native builds, arm64 and x86_64, because universal builds fail. On top of that, Intel loses Homebrew support in September 2027.

**Verdict on the from-source build ticket.** Yes, it is plausible and worth a **strictly time-boxed** attempt. The evidence for:

- WebKitGTK's GTK3 port was built on current macOS as recently as April 2026, using the same `PORT=GTK` code.
- The Quartz target option still exists upstream.
- nixpkgs already carries Darwin flags for `webkitgtk_6_0`.

The evidence against: no one has published a working GTK4 build on macOS, nixpkgs marks it broken, and success yields an unsupported, GPU-less WebView we would have to carry ourselves. The result should feed ticket 06 as a risk input. It is not a green light for shipping.

## Sources

1. Homebrew `gtk4` formula API: https://formulae.brew.sh/api/formula/gtk4.json
2. MacPorts `gtk4` Portfile: https://github.com/macports/macports-ports/blob/master/gnome/gtk4/Portfile
3. Homebrew `libadwaita` formula API: https://formulae.brew.sh/api/formula/libadwaita.json
4. MacPorts port search, libadwaita: https://ports.macports.org/search/?q=libadwaita&name=on
5. macports-ports commit history (`gh api repos/macports/macports-ports/commits?path=...`), for gnome/libadwaita, gnome/gjs-devel and www/webkit2-gtk
6. Homebrew `gjs` formula API: https://formulae.brew.sh/api/formula/gjs.json
7. MacPorts port search, gjs: https://ports.macports.org/search/?q=gjs&name=on
8. Homebrew `webkitgtk` formula API: https://formulae.brew.sh/api/formula/webkitgtk.json
9. Homebrew `webkitgtk.rb`: https://github.com/Homebrew/homebrew-core/blob/main/Formula/w/webkitgtk.rb (line 58 `depends_on :linux`, line 81 `-DUSE_GTK4=OFF`)
10. MacPorts `webkit2-gtk` Portfile: https://github.com/macports/macports-ports/blob/master/www/webkit2-gtk/Portfile
11. MacPorts `webkit2-gtk-devel` Portfile: https://github.com/macports/macports-ports/blob/master/www/webkit2-gtk-devel/Portfile
12. GitHub code search: `USE_GTK4 repo:macports/macports-ports` and `webkitgtk-6.0 repo:Homebrew/homebrew-core`
13. Homebrew Support Tiers: https://docs.brew.sh/Support-Tiers
14. Homebrew 5.0.0 release notes (Intel moves to Tier 3 in September 2026): https://brew.sh/2025/11/12/homebrew-5.0.0
15. nixpkgs `webkitgtk_6_0`: https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/we/webkitgtk_6_0/package.nix
16. WebKit `Source/cmake/OptionsGTK.cmake`: https://github.com/WebKit/WebKit/blob/main/Source/cmake/OptionsGTK.cmake
17. M. Catanzaro, "WebKitGTK API Versions Demystified" (2025-04-28): https://blogs.gnome.org/mcatanzaro/2025/04/28/webkitgtk-api-versions/
18. https://webkitgtk.org/ (latest stable 2.54.2)
19. WebKit bug 126492: https://bugs.webkit.org/show_bug.cgi?id=126492
20. WebKit bug 225850: https://bugs.webkit.org/show_bug.cgi?id=225850
21. MacPorts commit a64418725, "webkit2-gtk: update to 2.52.4" (fixes trac #65492): https://github.com/macports/macports-ports/commit/a64418725
22. C. Hergert, "GTK 4 got a new macOS backend (now with OpenGL)", December 2020: https://blogs.gnome.org/chergert/2020/12/
23. GTK4 docs, "Using GTK on Apple macOS": https://docs.gtk.org/gtk4/osx.html
24. `GtkHeaderBar:use-native-controls`: https://docs.gtk.org/gtk4/property.HeaderBar.use-native-controls.html
25. libadwaita NEWS: https://gitlab.gnome.org/GNOME/libadwaita/-/blob/main/NEWS
26. gtk.org, "Setting up GTK for macOS": https://www.gtk.org/docs/installations/macos/
27. gtk-osx README: https://gitlab.gnome.org/GNOME/gtk-osx/-/blob/master/README.md
28. gtk-osx `modulesets-stable/gtk-osx-network.modules`: https://gitlab.gnome.org/GNOME/gtk-osx/-/blob/master/modulesets-stable/gtk-osx-network.modules
29. GnuCash wiki, MacOS/Quartz: https://wiki.gnucash.org/wiki/MacOS/Quartz
30. gnucash-devel, July 2025: https://lists.gnucash.org/pipermail/gnucash-devel/2025-July/047095.html
31. Pinta 3.0 release notes: https://www.pinta-project.com/releases/3-0
32. Homebrew cask `pinta`: https://formulae.brew.sh/cask/pinta
33. Gaphor on macOS: https://docs.gaphor.org/en/latest/macos.html

### Not verified

- MacPorts buildbot results for `webkit2-gtk +quartz` and `gtk4 +quartz`: ports.macports.org build pages returned 403 and trac.macports.org was behind a bot wall.
- GTK 4.18-era macOS fixes (the fractional-scaling caveat and the GdkKeymap fix), which came via search-result summaries of release notes, not GTK's own NEWS.
