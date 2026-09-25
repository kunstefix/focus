# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A pair of macOS bash scripts that block distracting websites by rewriting `/etc/hosts`. There is no build, lint, or test tooling.

## Commands

```bash
sudo ./blocker.sh sites.txt   # block every domain listed in sites.txt
sudo ./unblocker.sh           # restore /etc/hosts without the blocked domains
```

Both scripts refuse to run without root. Test changes against a copy of the hosts file rather than the real `/etc/hosts` (e.g. temporarily point the final redirect at a scratch file).

## How it works

- `hosts.base` holds the base `/etc/hosts` content: the macOS defaults (localhost, broadcasthost, `::1`), the Docker Desktop `kubernetes.docker.internal` entry, and the local `*.wtx` / `*.wundertax.green` dev hostnames. Change the base hosts content there and nowhere else. The scripts find it next to themselves via `dirname "$0"`.
- `sites.txt` holds one bare domain per line (blank lines are skipped). For each one, `blocker.sh` appends two `127.0.0.1` entries, `www.<domain>` and `<domain>`, under a `# Blocked sites` header.
- Neither script edits `/etc/hosts` in place. `blocker.sh` writes `hosts.base` plus the blocked entries, and `unblocker.sh` writes `hosts.base` alone. Entries the user adds to `/etc/hosts` by hand are lost on every run unless they're also added to `hosts.base`.
