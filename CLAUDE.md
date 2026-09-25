# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

macOS bash scripts that block distracting websites by rewriting `/etc/hosts`. Blocking is the default state: sites are blocked at every boot, and `unfocus` only lifts the block temporarily. There is no build, lint, or test tooling.

## Commands

```bash
cp sites.example.txt sites.txt       # first-time setup; sites.txt is gitignored
sudo ./src/install.sh                # install the boot LaunchDaemon and block now
sudo ./src/focus.sh [sites-file]     # block now (default: sites.txt in the repo root), cancels any unfocus timer
sudo ./src/unfocus.sh [-m minutes]   # unblock for N minutes (default 5), then re-block automatically
sudo ./src/uninstall.sh              # remove the LaunchDaemon and unblock
```

All scripts live in `src/` and refuse to run without root. `focus.sh` and `install.sh` find `sites.txt` in the parent of `src/`. To test, recreate that layout in a scratch folder with `HOSTS_FILE` / `PID_FILE` in `common.sh` pointed at scratch files. Stub out the root check and `flush_dns`.

## How it works

- `src/hosts.base` holds the base `/etc/hosts` content: the macOS defaults, the Docker Desktop entry, and the local `*.wtx` / `*.wundertax.green` dev hostnames. Change the base hosts content there and nowhere else. Neither script edits `/etc/hosts` in place: `focus.sh` writes `hosts.base` plus the blocked entries, and `unfocus.sh` writes `hosts.base` alone. Entries the user adds to `/etc/hosts` by hand are lost on every run.
- `sites.txt` (repo root, next to `sites.example.txt`) holds one bare domain per line (`#` comments and blank lines are skipped). Each domain becomes two `127.0.0.1` entries, `www.<domain>` and `<domain>`.
- `common.sh` is sourced by both `focus.sh` and `unfocus.sh`. It holds the file paths, the root check, the timer cancel and the DNS cache flush.
- **Timer:** `unfocus.sh` starts a detached `nohup bash -c` loop and stores its PID in `/var/run/focus.pid`. The loop polls a wall-clock deadline, so time the Mac spends asleep counts toward the break. The loop inherits root from the sudo'd parent, so re-blocking needs no password. It removes the PID file before `exec`ing `focus.sh`, so `focus.sh` doesn't kill it. `focus.sh` and a repeated `unfocus.sh` kill any existing timer.
- **Boot:** `install.sh` copies `focus.sh`, `common.sh` and `hosts.base` into root-owned `/usr/local/lib/focus/` and loads `/Library/LaunchDaemons/com.klemen.focus.plist` (`RunAtLoad`). That runs the copied `focus.sh` with the repo's absolute `sites.txt` path.
  - Editing `sites.txt` needs no reinstall.
  - After changing `focus.sh`, `common.sh` or `hosts.base`, re-run `sudo ./src/install.sh` so the boot copy is refreshed.
  - Moving the repo breaks the daemon's sites path, and so does renaming it; re-run `install.sh` afterwards.
