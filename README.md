# Focus

Block distracting websites on macOS by pointing them at `127.0.0.1` in `/etc/hosts`.

**Website:** [kunstefix.github.io/focus](https://kunstefix.github.io/focus/)

Sites stay blocked by default. They're blocked again at every boot. You can take a short break from the menu bar (or with `unfocus`), and the block comes back on its own when the time is up. The menu bar shows how much time you've spent on breaks today.

## Why it works

Checking a site is usually a habit, not a decision. Focus puts a little friction in the way: to get through, you have to start a break and type your password. That small pause is often enough to notice the urge and skip it. The break also ends on its own, so a quick check can't turn into an hour of scrolling. And since blocking is the default, you don't have to rely on willpower to switch it back on. Seeing today's break total makes the habit visible.

## The app

### Install

1. Download Focus from [Gumroad](https://kunstek5.gumroad.com/l/focus) (pay what you want, from €0) or from the [releases](../../releases), and drag Focus to Applications.
2. Open it. The app isn't signed with an Apple Developer ID, so macOS blocks it the first time. Go to **System Settings → Privacy & Security** and click **Open Anyway**. Or run `xattr -dr com.apple.quarantine /Applications/Focus.app` once.
3. Click the ring in the menu bar, then **Install**, and enter your password. This blocks the sites in your list now and at every boot.

### Use

- **Take a break:** pick 5, 10 or 15 minutes, or set your own. macOS asks for your password every time, on purpose.
- **End break now:** blocks again right away, without a password. Your browser restarts, as it does when a break runs out.
- **Edit sites…:** one domain per line, without `www.`. Both `example.com` and `www.example.com` get blocked. Lines starting with `#` are comments. Saving applies the list right away; during a break it applies when the break ends. The list lives in `~/Library/Application Support/Focus/sites.txt`.
- **Open at login** keeps the menu bar icon around. Blocking doesn't depend on it: that runs at boot whether the app is open or not.
- **Today on breaks** adds up every break since midnight, including breaks started from the command line. A break you end early only counts until you ended it.

During a break the icon shows the time left.

### Build it yourself

```bash
scripts/build-app.sh            # dist/Focus.app and dist/Focus.dmg
swift test --package-path app   # unit tests for the break total
```

Pushing a `v*` tag builds the DMG on GitHub Actions and attaches it to a release.

## Command line

The scripts in `src/` do all the root work and also work without the app.

```bash
cp sites.example.txt sites.txt   # then edit sites.txt with your own sites
sudo ./src/install.sh            # block now and at every boot (uses sites.txt in the repo)
./src/unfocus.sh                 # unblock for 5 minutes
./src/unfocus.sh -m 15           # unblock for 15 minutes
./src/focus.sh                   # block again right away (cancels a running break)
sudo ./src/uninstall.sh          # remove the boot job and unblock
```

`install.sh` takes an optional path to a sites file. The app passes its own. Whichever ran `install.sh` last decides which list is blocked at boot, so use either the app or the CLI to install, not both.

`unfocus` always asks for your password, even if you've used sudo recently. Don't run it with `sudo` in front, because a cached sudo login would skip the prompt. `focus` never needs a password once installed. Time the Mac spends asleep counts toward the break, and a reboot ends it.

To run `focus` and `unfocus` from anywhere, add aliases to your shell config from the project folder:

```bash
echo "alias focus='$PWD/src/focus.sh'" >> ~/.zshrc
echo "alias unfocus='$PWD/src/unfocus.sh'" >> ~/.zshrc
source ~/.zshrc
```

## Notes

- Focus only touches the lines between `# BEGIN focus` and `# END focus` in `/etc/hosts`. Your own entries outside that block are kept.
- Install puts root-owned copies of the scripts in `/Library/PrivilegedHelperTools/io.github.kunstefix.focus/`, adds a LaunchDaemon that blocks at boot and ends breaks on time, and adds `/etc/sudoers.d/focus` so ending a break needs no password. Re-run install after changing the scripts.
- The break history is in `/var/db/focus/breaks.log`. Uninstall keeps it.
- Blocking only affects new connections. A tab that's already open on a blocked site (e.g. Instagram or X) keeps working over its existing connection. To close that gap, **your default browser restarts when a break ends**, and the blocked tabs fail to reconnect. This also happens when you end a break early. If a page shows a "Leave site?" dialog, the restart is skipped. Chrome, Arc, Brave, Edge, Vivaldi and Opera always restore your tabs. Safari and Firefox reopen them only if they're set to; otherwise use History → Reopen All Windows from Last Session (Safari) or Restore Previous Session (Firefox). Browsers other than the default aren't restarted.
- The sites list is yours to edit, so emptying it unblocks everything without a password. Focus adds friction; it isn't a lock you can't open.
