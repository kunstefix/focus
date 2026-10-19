# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A macOS menu bar app plus bash scripts that block distracting websites by editing `/etc/hosts`. Blocking is the default state: sites are blocked at every boot, and a break ("unfocus") only lifts the block temporarily. The menu bar shows today's total break time.

The bash scripts in `src/` do all the root work. The SwiftUI app in `app/` only reads state files and runs those scripts. The CLI keeps working without the app.

## Commands

```bash
swift build --package-path app       # debug build; `swift run --package-path app` runs it against the repo's src/
swift test --package-path app        # BreakLog unit tests (the only tests)
scripts/build-app.sh [version]       # dist/Focus.app + dist/Focus.dmg, universal, ad-hoc signed
cp sites.example.txt sites.txt       # CLI setup; sites.txt is gitignored
sudo ./src/install.sh [sites-file]   # install scripts, sudoers rule and boot LaunchDaemon, block now
./src/focus.sh [sites-file]          # block now, cancels any break
./src/unfocus.sh [-m minutes]        # unblock for N minutes (default 5), then re-block automatically
sudo ./src/uninstall.sh              # remove everything installed and unblock
```

`focus.sh` and `unfocus.sh` re-exec themselves through sudo when not root. `unfocus.sh` uses `sudo -k`, so it always asks for the password even when sudo credentials are cached. The app gets the same friction by running it through a fresh `osascript … with administrator privileges` process each time (`app/Sources/Focus/Privileged.swift`). That's deliberate, so don't remove it, don't add a password-free path to unfocus, and don't tell users to prefix `unfocus` with `sudo`.

To test the scripts, copy `src/` into a scratch folder and point the paths in `common.sh` (`HOSTS_FILE`, `DEADLINE_FILE`, `LIB_DIR`, `LOG_DIR`) at scratch files. Delete the `exec sudo` lines, stub `flush_dns` and `restart-browser.sh`, and put a `focusd.sh` in the scratch `LIB_DIR` (`unfocus.sh` refuses to run without it). To test natural break ends, run `focusd.sh` in the background with a shorter `sleep` and shorten `minutes * 60`.

## How it works

- **`/etc/hosts`:** scripts only touch the block between `# BEGIN focus` and `# END focus`; everything else in the file is the user's and is kept. `hosts_without_block` / `replace_hosts` in `common.sh` do this. `focus.sh` appends a fresh block, `unfocus.sh` removes it. `install.sh` also migrates the pre-marker format once, by cutting a legacy `# Blocked sites` section.
- **Sites file:** one bare domain per line (`#` comments and blank lines skipped, anything but `[A-Za-z0-9.-]` rejected). Each domain becomes `127.0.0.1` and `::1` entries for both `www.<domain>` and `<domain>`. The `::1` entries matter: without them the real IPv6 address still resolves. `focus.sh` uses its argument, else `SITES_FILE` from `$LIB_DIR/config` (written by `install.sh`), else the repo's `sites.txt`. The app keeps its list in `~/Library/Application Support/Focus/sites.txt`.
- **Install:** `install.sh` copies `focus.sh`, `focusd.sh`, `unfocus.sh`, `restart-browser.sh` and `common.sh` into root-owned `/Library/PrivilegedHelperTools/io.github.kunstefix.focus/`. It also writes `/etc/sudoers.d/focus`, allowing `focus.sh` with no arguments as root without a password; that's how the app ends breaks and applies edited lists. It then loads `/Library/LaunchDaemons/io.github.kunstefix.focus.plist` (`RunAtLoad` + `KeepAlive`), which keeps the installed `focusd.sh` running.
  - The lib dir must stay under root-only parents: the sudoers rule would otherwise be a root escalation. `/usr/local/lib` is user-writable with Intel Homebrew, which is why it moved from there.
  - After changing a script, re-run install so the root copies are refreshed. The app bundles `src/*.sh` in `Contents/Resources/scripts` and runs the bundled `install.sh`.
  - Paths are duplicated in `common.sh` and `Paths` in `app/Sources/Focus/FocusStatus.swift`. Keep them in sync.
- **Breaks:** `unfocus.sh` writes `<start> <deadline> <user>` to `/var/run/focus.deadline`, then unblocks. The user is `$SUDO_USER`, or `$FOCUS_USER` when the app ran it via osascript. The break is ended by `focusd.sh`, the daemon, which runs `focus.sh` at start (boot) and then polls the deadline file every 5 s against the wall clock, so time the Mac spends asleep counts toward the break.
  - Don't go back to a timer process started by `unfocus.sh`. Under the app's `osascript … with administrator privileges`, such a background timer died, so breaks never ended. launchd owning the timer avoids that.
  - `focus.sh` ends a running break through `end_break` in `common.sh`, whoever calls it: the daemon, the app's "End break now" or the CLI. It then runs `restart-browser.sh` for that user in the background. Hosts changes don't affect a browser's existing connections, so the script looks up the user's default browser (the app that opens `https` links, via JXA `NSWorkspace`), quits it in the user's GUI session (`launchctl asuser` + `osascript`) and relaunches it. Chromium-based browsers get `--restore-last-session`; Safari and Firefox restore tabs only per their own settings.
- **Break log:** `/var/db/focus/breaks.log` gets `start <epoch> <deadline>` from `unfocus.sh` and `end <epoch>` from `end_break`. `app/Sources/FocusCore/BreakLog.swift` turns it into today's total. Uninstall keeps the log.
- **Landing page:** `docs/index.html` is a single self-contained page served by GitHub Pages from `/docs`. Its download buttons link to the Gumroad product (`kunstek5.gumroad.com/l/kgrrkg`, pay what you want from €0), and Gumroad's `gumroad.js` opens the checkout as an overlay on the page. The fine print under the hero links straight to `releases/latest/download/Focus.dmg`, so the release asset must keep that name. The Gumroad product's file is uploaded by hand, so update it with each release.
- **App:** `MenuBarExtra` with `FocusStatus` polling the deadline file, the log, and whether the lib dir is installed, once a second. "Open at login" writes a LaunchAgent in `~/Library/LaunchAgents`, since `SMAppService` isn't reliable for ad-hoc signed apps. Releases are built by `.github/workflows/release.yml` on `v*` tags.
