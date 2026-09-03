# CachyOS Intel MacBook bootstrap

This repository turns a fresh CachyOS Hyprland installation on an Intel
MacBook Pro into a portable version of the source machine's setup.

Start with [GUIDE.md](GUIDE.md). The short version, after CachyOS is installed,
is:

```bash
cp profile.example.env profile.env
$EDITOR profile.env
./install.sh --dry-run
./install.sh
```

The installer is idempotent, backs up every config file it replaces, and never
copies account state. Run `scripts/privacy-check.sh` before transferring or
publishing the repository.

The setup uses the public `quickshell-redesign` rice plus portable Hyprland and
application configuration from this repository. It replaces CachyOS's Noctalia
entry configuration while preserving the original in a timestamped backup.

## Keeping machines in sync

After installation, use:

```bash
q-update config                 # pull and apply config only
q-update system                 # update CachyOS packages only
q-update                        # do both
q-update publish "config: note" # capture, review, commit, and push
```

`publish` copies only an explicit allow-list. It deliberately skips monitor and
keyboard settings, Codex state, SSH/GitHub credentials, histories, network
profiles, and application account data. Each machine that publishes needs its
own authorized GitHub login or SSH key; credentials are never synchronized.
