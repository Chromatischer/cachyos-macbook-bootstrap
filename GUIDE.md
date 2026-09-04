# CachyOS on an Intel MacBook Pro: install and bootstrap guide

Last reviewed: 2026-09-04

This is the operator's runbook for installing CachyOS beside macOS and then
applying the portable desktop/development setup in this repository. The disk
and firmware steps stay manual; everything after the first successful CachyOS
boot is automated by `install.sh`.

The source machine is ARM/Asahi and uses a customized Omarchy fork. This target
is Intel x86_64 and CachyOS. We copy the useful experience—Hyprland, the
dark/orange Quickshell island, terminals, shell tools, development packages, and reviewed Codex
configuration—without copying the source machine's kernel, firmware, account
state, or personal integrations.

## Five facts to collect first

Do not pick Wi-Fi, graphics, camera, Touch Bar, or fan fixes until these are
known:

1. Exact model identifier, such as `MacBookPro11,3` or `MacBookPro15,1`.
2. Whether `has_t2=yes`.
3. Whether the final layout is macOS + CachyOS or CachyOS only.
4. How much storage to give CachyOS. Use 80–120 GiB for a comfortable
   development machine; the official minimum is much smaller.
5. The physical keyboard's XKB layout, such as `us`, `de`, or `gb`.

On the friend's Mac, open Terminal in macOS, copy this repository there, and
run:

```bash
./scripts/macos-hardware-report.sh
cat hardware-report-macos.txt
```

The report omits serial numbers and account identifiers. Put its
`model_identifier` into `profile.env`. If the machine is already unable to
boot macOS, photograph the model number on the underside and look up the exact
model before proceeding.

## What you need

- A verified current CachyOS Desktop ISO.
- An 8 GiB or larger USB stick that may be completely erased.
- A second USB stick for this repository and emergency files, or a reachable
  Git repository containing this bundle.
- A full backup of macOS. Verify that a file can actually be restored.
- Ethernet, a compatible USB network adapter, or phone USB tethering. Treat
  working Wi-Fi in the live ISO as a bonus, not a prerequisite.
- The macOS recovery key/account access needed to enter Recovery Mode.
- For a T2 Mac, keep a usable macOS partition. CachyOS explicitly recommends
  it for firmware updates and recovery.

Official references:

- [CachyOS requirements and USB preparation](https://wiki.cachyos.org/installation/installation_prepare/)
- [CachyOS desktop/laptop installation](https://wiki.cachyos.org/installation/installation_on_root/)
- [CachyOS T2 MacBook guide](https://wiki.cachyos.org/installation/installation_t2macbook/)
- [CachyOS boot-manager comparison](https://wiki.cachyos.org/installation/boot_managers/)
- [CachyOS Hyprland post-install guide](https://wiki.cachyos.org/configuration/desktop_environments/hyprland/)
- [Hyprland Lua configuration](https://wiki.hypr.land/Configuring/Start/)

The exact screens and package versions can change on a rolling distribution.
If these sources disagree with this file, stop and follow the current CachyOS
documentation.

## Phase 1: prepare macOS

### 1. Update and back up

Install pending macOS and firmware updates first. Make a full backup. For a T2
Mac, also create macOS recovery/install media if practical. Do not erase the
recovery environment.

### 2. Create a real Linux partition

Use Disk Utility from macOS:

1. Select the internal physical disk/APFS container.
2. Choose **Partition**.
3. Press `+` and choose **Add Partition**, not **Add Volume**.
4. Name it `CachyOS` and allocate the intended size. Its temporary format does
   not matter; Calamares will replace it.
5. Apply the change and let Disk Utility finish without interruption.

Do not shrink APFS from the Linux live environment. Do not touch the Apple EFI,
Recovery, or APFS partitions in Calamares.

### 3. T2 branch only

If the report says `has_t2=yes`, follow the current
[CachyOS T2 guide](https://wiki.cachyos.org/installation/installation_t2macbook/)
before booting the ISO:

1. In macOS Recovery, use Startup Security Utility to select **No Security**
   and allow external/removable boot media.
2. Prepare the proprietary Apple Wi-Fi firmware as documented by CachyOS, or
   plan to use Ethernet/USB tethering.
3. Keep macOS. Audio, webcam, Touch Bar, and Wi-Fi on T2 systems are a distinct
   support path.

Do not perform these Startup Security changes on a pre-T2 Mac; that utility and
hardware path do not apply.

### 4. Create and verify the USB

Download the ISO only from CachyOS, verify its published checksum/signature,
then flash it with balenaEtcher. Etcher is the least error-prone choice for the
install day. If using `dd`, identify the whole USB disk twice; selecting the
internal disk is unrecoverably destructive.

Keep the ISO or a second CachyOS USB available. The official guide recommends
this because a live system plus `cachy-chroot` is the recovery path for a
broken boot.

## Phase 2: install CachyOS

### 1. Boot the USB in UEFI mode

1. Shut down fully.
2. Power on while holding Option (`⌥`).
3. Choose the orange **EFI Boot** entry for the CachyOS USB.
4. In the live desktop, connect to the network.
5. Before opening the installer, run:

   ```bash
   efibootmgr -v
   ```

If it says EFI variables are unsupported, reboot and select the UEFI USB entry.
CachyOS notes that seeing only GRUB and Limine in the boot-manager list is also
a sign that the installer was started in legacy/BIOS mode.

### 2. Use manual partitioning

CachyOS warns that **Install alongside** and **Replace partition** are not
fully reliable. Choose **Manual partitioning**.

Recommended layout inside only the placeholder partition created in macOS:

| Size | Format | Mount | Flags | Purpose |
|---:|---|---|---|---|
| 4 GiB | FAT32 | `/boot` | boot | New CachyOS ESP for rEFInd and kernels |
| remainder | Btrfs | `/` | none | CachyOS root/home/snapshots |

Select **Limine** as the boot manager. CachyOS currently requires a 4 GiB FAT32
`/boot` partition for Limine; this is separate from Apple's small EFI
partition. Do not format or mount the Apple EFI partition.

Encryption is a separate choice. Root encryption is sensible for a laptop,
but it adds another recovery dependency. If the priority is the easiest first
debug session, complete and test the unencrypted dual boot first. Never put a
disk passphrase in `profile.env` or this repository.

At the final summary, stop and verify all of the following:

- Only the partition named `CachyOS` was subdivided/reformatted.
- The Apple APFS container, Recovery partition, and original Apple EFI are
  untouched.
- The new 4 GiB FAT32 partition is `/boot`.
- The remaining new Btrfs partition is `/`.
- The boot manager is Limine and the target disk is the internal disk.
- The selected environment is Hyprland. Installing one environment during
  Calamares avoids cross-desktop daemon conflicts.

Then install and reboot. Hold Option on the first reboot. Confirm that both
macOS and the Linux/Limine entry boot before changing the default startup disk.

## Phase 3: first CachyOS boot

Transfer this repository to the new user's home directory. Then:

```bash
cd cachyos-macbook-bootstrap
cp profile.example.env profile.env
$EDITOR profile.env
./scripts/verify.sh
./install.sh --dry-run
./install.sh
```

Set `MAC_MODEL` and `HAS_T2` from the macOS report. Set `KEYBOARD_LAYOUT` to
the keyboard's XKB layout (`us`, `de`, or `gb`, for example). Optional desktop
and AUR applications are enabled by default; set either app flag to `0` for a
shorter first pass. The default run performs a full package upgrade, installs
the desktop/development/application groups, deploys the rice, installs Codex
from OpenAI's official installer, and enables NetworkManager/Bluetooth. Every replaced
config is copied to:

```text
~/.local/state/cachyos-macbook-bootstrap/backups/<UTC timestamp>-<process ID>/
```

CachyOS's current Hyprland edition includes a Noctalia-based default. This
bundle replaces its `hyprland.lua` entry point with the portable dark/orange
Hyprland + Quickshell island setup. Noctalia may remain installed, but this
configuration does not start it. The original CachyOS config is in the backup
path above and can be restored file by file.

The bundle does not change partitions, boot entries, kernel parameters,
firmware, or model-specific drivers.

Log out. At the login manager choose **Hyprland (UWSM)**. The generic monitor
rule asks Hyprland to use the preferred mode and automatic scale. After login:

```bash
hyprctl monitors
./scripts/linux-hardware-report.sh
```

Review the report before sharing it. It is designed to omit network addresses,
SSIDs, serial numbers, and disk UUIDs.

### Wallpaper

The source wallpapers were not bundled because their licenses and sharing
intent are not established. Put a reviewed image here:

```text
~/Pictures/Wallpapers/default.jpg
```

Then log in again or run `friend-wallpaper`. Without an image, the desktop uses
a plain dark base color.

## Phase 4: Mac hardware triage

Do one subsystem at a time and reboot between kernel/firmware changes. Keep the
default CachyOS kernel and add an LTS kernel through CachyOS Kernel Manager so
there is always a second bootable choice.

### Wi-Fi

Run:

```bash
lspci -nnk | sed -n '/Network controller/,+4p'
rfkill list
```

- T2: use the firmware procedure in the current CachyOS T2 guide.
- Pre-T2 Broadcom: choose `brcmfmac`, `brcmsmac`, `b43`, or
  `broadcom-wl-dkms` from the exact PCI ID and kernel support, not merely from
  the word “Broadcom”. A DKMS driver also needs matching headers for every
  installed kernel.
- If uncertain, keep using USB tethering and send the PCI block for review.

Never install several competing Broadcom drivers at once.

### Graphics

Run:

```bash
lspci -nnk | sed -n '/VGA\|3D controller/,+5p'
```

An Intel-only model should normally use the in-kernel `i915` driver. Models
with an AMD or NVIDIA discrete GPU need model-specific power and mux decisions;
do not paste generic PRIME or blacklisting snippets before identifying both
GPUs and the active kernel driver. Keep the Hyprland automatic monitor rule
until the internal connector name is known.

### Keyboard and trackpad

The rice assumes the Command key arrives as `SUPER`, uses natural scrolling,
tap-to-click, and click-finger right click. If the function row behavior is
wrong, inspect the loaded `hid_apple` parameters before adding a modprobe
option. Do not copy the source machine's Apple Silicon lid/backlight device
names; they are not portable to Intel Macs.

### Camera, audio, Touch Bar, suspend, and fans

These vary by model. First capture:

```bash
journalctl -b -p warning..alert
systemctl --failed
wpctl status
```

For T2 models, use the t2linux guidance linked by CachyOS. For pre-T2 models,
send the model identifier and relevant PCI/USB lines before installing
proprietary camera firmware, fan daemons, or out-of-tree modules. A working
temperature sensor must be confirmed before enabling a fan daemon.

#### T2 lid and suspend safety

On T2 machines, the bootstrap installs a logind policy that locks instead of
suspending when the lid closes. The shared Hypridle config locks after five
minutes and blanks the display after 5.5 minutes, but does not automatically
suspend. This avoids a known failure mode where `apple_bce` crashes during
resume and leaves the internal display and system unresponsive. The
`q-trigger-sleep` helper also refuses hardware suspend when that driver is
active. Reboot after the bootstrap installs the lid policy; until then, do not
close the lid.

This restriction is conditional: on a non-T2 Mac without `apple_bce`,
`q-trigger-sleep` still performs a normal suspend. Re-test T2 suspend only after
the model's upstream kernel issue is confirmed fixed.

## Codex and skills migration

The bootstrap follows the current
[official Codex CLI install guide](https://learn.chatgpt.com/docs/codex/cli):
it downloads the standalone installer from `chatgpt.com`, then the friend runs
`codex` and signs in with their own account.

Only these reviewed files are deployed:

- `~/.codex/config.toml`: model/reasoning and terminal UI preferences.
- `~/.codex/AGENTS.md`: generic working rules with no project paths.
- `~/.codex/skills/frontend-skill/`: a self-contained portable skill.

OpenAI's [skills documentation](https://learn.chatgpt.com/docs/build-skills)
describes skills as folders containing instructions, resources, and optional
scripts. That is why the whole reviewed skill folder is copied, while Codex
runtime state is not.

Never copy `~/.codex` wholesale. In particular, do not transfer `auth.json`,
session/history files, memories, logs, SQLite databases, project trust entries,
installation IDs, caches, plugins, connectors, or shell snapshots. System
skills are installed/managed with Codex itself and are not vendored here.

## Recovery and rollback

### Rice/config problem

Switch to a TTY with `Ctrl`+`Alt`+`F3`, sign in, and inspect the newest backup:

```bash
ls -1dt ~/.local/state/cachyos-macbook-bootstrap/backups/* | head -1
```

Restore only the affected file from the matching path under that directory.
For example, a backed-up home config is stored below `home/<user>/.config/`.
Do not recursively overwrite the entire home directory.

### Black screen but system boots

Use a TTY, run `systemctl --user --failed`, and validate the Hyprland config
with the installed Hyprland tools. Temporarily move only the new
`~/.config/hypr/hyprland.lua` aside and restore its backup. Keep the display
manager and CachyOS kernel unchanged while isolating the config issue.

### Boot entry missing

Boot the CachyOS USB in UEFI mode and use CachyOS's documented `cachy-chroot`
recovery flow. Do not reformat any partition. Photograph `lsblk -f` and
`efibootmgr -v` first, but redact filesystem UUIDs before posting publicly.

macOS remains bootable by holding Option even if the Linux default entry needs
repair. On T2 hardware, retaining macOS is part of the recovery strategy.

## Success checklist

- macOS boots and can still enter Recovery.
- CachyOS boots through Limine and has a second known-good kernel.
- Wi-Fi/Ethernet, audio, keyboard, trackpad, brightness, battery reporting,
  lid close/open behavior, and external display output have each been tested.
- Suspend/resume has been tested on non-T2 hardware; on affected T2 models,
  lid-close safely locks instead of suspending.
- Hyprland starts from UWSM; Quickshell, Fuzzel, lock, clipboard, and screenshots
  work.
- `./scripts/verify.sh` passes before this repository is shared.
- The friend signs into every application themselves; no source-machine
  account state appears on the target.
