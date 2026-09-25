# Focus

Block distracting websites on macOS by pointing them at `127.0.0.1` in `/etc/hosts`.

Sites stay blocked by default. They're blocked again at every boot. You can take a short break with `unfocus`, and the block comes back on its own when the time is up.

## Why it works

Checking a site is usually a habit, not a decision. Focus puts a little friction in the way: to get through, you have to type a command and your password. That small pause is often enough to notice the urge and skip it. The break also ends on its own, so a quick check can't turn into an hour of scrolling. And since blocking is the default, you don't have to rely on willpower to switch it back on.

## Setup

```bash
cp sites.example.txt sites.txt   # then edit sites.txt with your own sites
sudo ./src/install.sh            # block now and at every boot
```

In `sites.txt`, put one domain per line without `www.`. Both `example.com` and `www.example.com` get blocked. Lines starting with `#` are comments. `sites.txt` isn't tracked by git.

## Usage

```bash
./src/unfocus.sh         # unblock for 5 minutes
./src/unfocus.sh -m 15   # unblock for 15 minutes
./src/focus.sh           # block again right away (cancels a running break)
```

`unfocus` always asks for your password, even if you've used sudo recently. Don't run it with `sudo` in front, because a cached sudo login would skip the prompt. `focus` asks only when sudo needs it. When the break is over, sites are blocked again in the background with no password prompt. Time the Mac spends asleep counts toward the break, and a reboot ends it.

### Adding or removing sites

Edit `sites.txt`. You don't need to reinstall. The change takes effect the next time `focus.sh` runs:

- **Right away:** run `./src/focus.sh` (or `focus` if you set up the alias). Do this if sites are currently blocked.
- **At the end of a break:** if you're in an `unfocus` break, the timer applies the new list when it re-blocks.
- **At the next boot.**

Re-run `sudo ./src/install.sh` only after changing the scripts or `hosts.base`.

## Aliases

To run `focus` and `unfocus` from anywhere, add aliases to your shell config. Run this from the project folder:

```bash
echo "alias focus='$PWD/src/focus.sh'" >> ~/.zshrc
echo "alias unfocus='$PWD/src/unfocus.sh'" >> ~/.zshrc
source ~/.zshrc
```

Then:

```bash
unfocus          # 5-minute break
unfocus -m 15    # 15-minute break
focus            # end the break early
```

Use `~/.bashrc` instead of `~/.zshrc` if you use bash. If you move the project folder, update the paths in the aliases.

## Uninstall

```bash
sudo ./src/uninstall.sh
```

This removes the boot job and unblocks all sites.

## Notes

- `/etc/hosts` is **overwritten** each time. It's rebuilt from `src/hosts.base` plus your blocked sites, so put any permanent custom host entries in `src/hosts.base`.
- `src/install.sh` copies `focus.sh`, `common.sh` and `hosts.base` to `/usr/local/lib/focus/` for the boot job. It reads `sites.txt` from the repo root. Re-run `sudo ./src/install.sh` after editing those scripts or `hosts.base`, and after moving this folder.
- Browsers keep their own DNS cache, so a tab that's already open may need a reload, or a browser restart, before the change shows.

