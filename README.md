# website-blocker

Block distracting websites on macOS by pointing them at `127.0.0.1` in `/etc/hosts`.

Sites stay blocked by default. They're blocked again at every boot. You can take a short break with `unfocus`, and the block comes back on its own when the time is up.

## Setup

```bash
cp sites.example.txt sites.txt   # then edit sites.txt with your own sites
sudo ./install.sh                # block now and at every boot
```

In `sites.txt`, put one domain per line without `www.`. Both `example.com` and `www.example.com` get blocked. Lines starting with `#` are comments. `sites.txt` isn't tracked by git.

## Usage

```bash
sudo ./unfocus.sh          # unblock for 5 minutes
sudo ./unfocus.sh -m 15    # unblock for 15 minutes
sudo ./focus.sh            # block again right away (cancels a running break)
```

When the break is over, sites are blocked again in the background with no password prompt. Time the Mac spends asleep counts toward the break, and a reboot ends it.

Changes to `sites.txt` take effect the next time `focus.sh` runs. That happens at the end of a break, at boot, or when you run it yourself.

## Uninstall

```bash
sudo ./uninstall.sh
```

This removes the boot job and unblocks all sites.

## Notes

- `/etc/hosts` is **overwritten** each time. It's rebuilt from `hosts.base` plus your blocked sites, so put any permanent custom host entries in `hosts.base`.
- `install.sh` copies `focus.sh`, `common.sh` and `hosts.base` to `/usr/local/lib/website-blocker/` for the boot job. It reads `sites.txt` from this folder. Re-run `sudo ./install.sh` after editing those scripts or `hosts.base`, and after moving this folder.
- Browsers keep their own DNS cache, so a tab that's already open may need a reload, or a browser restart, before the change shows.
