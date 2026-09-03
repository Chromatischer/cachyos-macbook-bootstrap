# Privacy boundary

This bundle is an allow-list, not a home-directory export.

## Included

- Package names, never package caches or application state.
- Standalone Hyprland, Waybar, Fuzzel, terminal, prompt, tmux, and Fastfetch
  configuration.
- A generic wallpaper launcher. The recipient supplies their own image.
- A small, reviewed Codex `config.toml`, generic `AGENTS.md`, and the portable
  `frontend-skill` folder.

## Deliberately excluded

- SSH, GPG, age, VPN, Wi-Fi, browser, mail, calendar, contacts, cloud-sync,
  password-manager, and messenger data.
- Shell histories, editor histories, recent-file lists, caches, logs, crash
  reports, cookies, IndexedDB, and local databases.
- Codex authentication, sessions, history, memories, goals, queues, logs,
  project trust entries, installation identifiers, plugins, connectors, and
  caches.
- Claude/OpenCode authentication and conversation state.
- Git identity and credentials.
- Host names, serial numbers, hardware UUIDs, MAC addresses, IP addresses,
  SSIDs, and absolute links into the source account.
- Asahi Linux packages, kernels, firmware, boot files, and Apple Silicon
  scripts.
- Quickshell account data and private integrations. The installer clones only
  the separately reviewed public `quickshell-redesign` repository.
- Wallpapers from the source account. A wallpaper may have unclear licensing
  or reveal personal taste/context, so add only an image reviewed for sharing.

## Before sharing

Run:

```bash
./scripts/verify.sh
git status --short
git diff --cached
```

If a new config is added later, review its contents and extend
`scripts/privacy-check.sh` before transferring the repository.

Never add a blanket copy command for `.config`, `.local`, `.codex`, `.ssh`, or
the home directory. Application configuration and application account state
often live beside one another.

`q-update publish` uses `scripts/capture-config.sh`, which captures only named
portable files and already-tracked `q-*` helpers, then runs the privacy check
before offering to commit and push.
