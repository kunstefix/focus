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

- `sites.txt` holds one bare domain per line. For each line, `blocker.sh` emits two `127.0.0.1` entries: `www.<domain>` and `<domain>`.
- Neither script edits `/etc/hosts` in place. Each one **overwrites the whole file** with a hardcoded template. The template contains the macOS defaults (localhost, broadcasthost, `::1`), the Docker Desktop `kubernetes.docker.internal` entry, and a line of local `*.wtx` / `*.wundertax.green` dev hostnames.
- `blocker.sh` and `unblocker.sh` each carry their own copy of that template. **Any change to the base hosts content has to be made in both files.** The copies have already drifted: `blocker.sh` has `wundertax--de.local.wundertax.green`, and `unblocker.sh` has `germantaxes--de…` twice instead. So unblocking silently drops that dev host.
- Entries the user adds to `/etc/hosts` by hand are lost on every run of either script.
- `blocker..sh.old` is an earlier version with the site list hardcoded into the template. It's kept only for reference.

## Known issue

`blocker.sh` builds `updated_content` with literal `\n` sequences and writes it with a plain `echo "$new_hosts_content"`. Bash's `echo` doesn't expand `\n` (checked on this machine), so all blocked entries end up on one malformed line when the script runs under `bash`. Fixing it means using `printf '%b'` or `echo -e`, or appending real newlines with `$'\n'`.
