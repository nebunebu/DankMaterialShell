<div align="center">
  <a href="https://danklinux.com">
    <img src="assets/danklogo.svg" alt="Dank Linux" width="200">
  </a>

  ### dms CLI & Backend + dankinstall

[![Documentation](https://img.shields.io/badge/docs-danklinux.com-9ccbfb?style=for-the-badge&labelColor=101418)](https://danklinux.com/docs)
[![GitHub release](https://img.shields.io/github/v/release/AvengeMedia/danklinux?style=for-the-badge&labelColor=101418&color=9ccbfb)](https://github.com/AvengeMedia/DankMaterialShell/backend/releases)
[![GitHub License](https://img.shields.io/badge/license-MIT-b9c8da?style=for-the-badge&labelColor=101418)](https://github.com/AvengeMedia/DankMaterialShell/backend/blob/master/LICENSE)

</div>

---

A monorepo for dankinstall and dms (cli+go backend), a modern desktop suite for Wayland compositors.

**[Full documentation →](https://danklinux.com/docs)**

- **dms** DankMaterialShell (cli + go backend)
  - The backend side of dms, provides APIs for the desktop and a management CLI.
  - Shared dbus connection for networking (NetworkManager, iwd), loginctl, accountsservice, cups, and other interfaces.
  - Implements wayland protocols
    - wlr-gamma-control-unstable-v1 (for night mode/gamma control)
    - dwl-ipc-unstable-v2 (for dwl/MangoWC integration)
    - ext-workspace-v1 (for workspace integrations)
    - wlr-output-management-unstable-v1
  - Exposes a json API over unix socket for interaction with these interfaces
  - Provides plugin management APIs for the shell
  - CUPS integration for printer management
  - ddc/ci protocol implementation
    - Allows controlling brightness of external monitors, like `ddcutil`
  - backlight + led control integration
    - Allows controlling backlight of integrated displays, or LED devices
    - Uses `login1` when available, else falls back to sysfs writes.
  - Optionally provides `update` interface - depending on build inputs.
    - This is intended to be disabled when packaged as part of distribution packages.
- **dankinstall** Installs the Dank Linux suite for [niri](https://github.com/YaLTeR/niri) and/or [Hyprland](https://hypr.land)
  - Features the [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
    - Which features a complete desktop experience with wallpapers, auto theming, notifications, lock screen, etc.
  - Offers up solid out of the box configurations as usable, featured starting points.
  - Can be installed if you already have niri/Hyprland configured
    - Will allow you to keep your existing config, or replace with Dank ones (existing configs always backed up though)

# dms cli & backend

Written in Go, provides a suite of APIs over unix socket via [godbus](https://github.com/godbus/dbus) and Wayland protocols. All features listed above are exposed over the socket API.

*Run `dms debug-srv` to start the socket service in standalone mode and see available APIs*

**CLI Commands:**
- `dms run [-d]` - Start shell (optionally as daemon)
- `dms restart` / `dms kill` - Manage running processes
- `dms ipc <command>` - Send IPC commands (toggle launcher, notifications, etc.)
- `dms plugins [install|browse|search]` - Plugin management
- `dms brightness [list|set]` - Control display/monitor brightness
- `dms update` - Update DMS and dependencies (disabled in distro packages)
- `dms greeter install` - Install greetd greeter (disabled in distro packages)

## Build & Install

To build the dms CLI (Requires Go 1.24+):

### For distribution package maintainers

This produces a build without the `update` or `greeter` functionality, which are intended for manual installation.

```bash
make dist
```

Produces `bin/dms-linux-amd64` and  `bin/dms-linux-arm64`

### Manual Install

```bash
# Installs to /usr/local/bin/dms
make && sudo make install
```

### Wayland Protocol Bindings

The gamma control functionality uses Wayland protocol bindings generated from the protocol XML definition. To regenerate the Go bindings from `internal/proto/xml/wlr-gamma-control-unstable-v1.xml`:

```bash
go install github.com/rajveermalviya/go-wayland/cmd/go-wayland-scanner@latest
go-wayland-scanner -i internal/proto/xml/wlr-gamma-control-unstable-v1.xml \
  -pkg wlr_gamma_control -o internal/proto/wlr_gamma_control/gamma_control.go
```

This is only needed if modifying the protocol or updating to a newer version.

# Dank Linux/dankinstall

Installs compositor, dms, terminal, and some optional dependencies - along with a default compositor & terminal configuration.

## Quickstart

```bash
curl -fsSL https://install.danklinux.com | sh
```

*Alternatively, download the latest [release](https://github.com/AvengeMedia/DankMaterialShell/backend/releases)*

## Supported Distributions

**Note on Greeter**: dankinstall does not install a greeter automatically.
- To install the dms greeter, run `dms greeter install` after installation.
- Then you can disable any existing greeter, if present, and run `sudo systemctl enable --now greetd`

### Arch Linux & Derivatives

**Supported:** Arch, ArchARM, Archcraft, CachyOS, EndeavourOS, Manjaro

**Special Notes:**
- Uses native `pacman` for system packages
- AUR packages are built manually using `makepkg` (no AUR helper dependency)
- **Recommendations**
  - Use NetworkManager to manage networking
  - If using archinstall, you can choose `minimal` for profile, and `NetworkManager` under networking.

**Package Sources:**
| Package | Source | Notes |
|---------|---------|-------|
| System packages (git, jq, etc.) | Official repos | Via `pacman` |
| quickshell | AUR | Built from source |
| matugen | AUR (`matugen-bin`) | Pre-compiled binary |
| dgop | Official repos | Available in Extra repository |
| niri | Official repos (`niri`) | Latest niri |
| hyprland | Official repos | Available in Extra repository |
| DankMaterialShell | Manual | Git clone to `~/.config/quickshell/dms` |

### Fedora & Derivatives

**Supported:** Fedora, Nobara, Fedora Asahi Remix

**Special Notes:**
- Requires `dnf-plugins-core` for COPR repository support
- Automatically enables required COPR repositories
- All COPR repos are enabled with automatic acceptance
- **Editions** dankinstall is tested on "Workstation Edition", but probably works fine on any fedora flavor. Report issues if anything doesn't work.
- [Fedora Asahi Remix](https://asahilinux.org/fedora/) hasn't been tested, but presumably it should work fine as all of the dependencies should provide arm64 variants.

**Package Sources:**
| Package | Source | Notes |
|---------|---------|-------|
| System packages | Official repos | Via `dnf` |
| quickshell | COPR | `avengemedia/danklinux` |
| matugen | COPR | `avengemedia/danklinux` |
| dgop | Manual | Built from source with Go |
| cliphist | COPR | `avengemedia/danklinux` |
| ghostty | COPR | `avengemedia/danklinux` |
| hyprland | COPR | `solopasha/hyprland` |
| niri | COPR | `yalter/niri` |
| DankMaterialShell | COPR | `avengemedia/dms` |

### Ubuntu

**Supported:** Ubuntu 25.04+

**Special Notes:**
- Requires PPA support via `software-properties-common`
- Go installed from PPA for building manual packages
- Most packages require manual building due to limited repository availability
  - This means the install can be quite slow, as many need to be compiled from source.
  - niri is packages as a `.deb` so it can be managed via `apt`
- Automatic PPA repository addition and package list updates

**Package Sources:**
| Package | Source | Notes |
|---------|---------|-------|
| System packages | Official repos | Via `apt` |
| quickshell | Manual | Built from source with cmake |
| matugen | Manual | Built from source with Go |
| dgop | Manual | Built from source with Go |
| hyprland | PPA | `ppa:cppiber/hyprland` |
| hyprpicker | PPA | `ppa:cppiber/hyprland` |
| niri | Manual | Built from source with Rust |
| Go compiler | PPA | `ppa:longsleep/golang-backports` |
| DankMaterialShell | Manual | Git clone to `~/.config/quickshell/dms` |

### Debian

**Supported:** Debian 13+ (Trixie)

**Special Notes:**
- **niri only** - Debian does not support Hyprland currently, only niri.
- Most packages require manual building due to limited repository availability
  - This means the install can be quite slow, as many need to be compiled from source.
  - niri is packages as a `.deb` so it can be managed via `apt`

**Package Sources:**
| Package | Source | Notes |
|---------|---------|-------|
| System packages | Official repos | Via `apt` |
| quickshell | Manual | Built from source with cmake |
| matugen | Manual | Built from source with Go |
| dgop | Manual | Built from source with Go |
| niri | Manual | Built from source with Rust |
| DankMaterialShell | Manual | Git clone to `~/.config/quickshell/dms` |

### openSUSE Tumbleweed

**Special Notes:**
- Most packages available in standard repos, minimal manual building required
- quickshell and matugen require building from source

**Package Sources:**
| Package | Source | Notes |
|---------|---------|-------|
| System packages (git, jq, etc.) | Official repos | Via `zypper` |
| hyprland | Official repos | Available in standard repos |
| niri | Official repos | Available in standard repos |
| xwayland-satellite | Official repos | For niri X11 app support |
| ghostty | Official repos | Latest terminal emulator |
| kitty, alacritty | Official repos | Alternative terminals |
| grim, slurp, hyprpicker | Official repos | Wayland screenshot utilities |
| wl-clipboard | Official repos | Via `wl-clipboard` package |
| cliphist | Official repos | Clipboard manager |
| quickshell | Manual | Built from source with cmake + openSUSE flags |
| matugen | Manual | Built from source with Rust |
| dgop | Manual | Built from source with Go |
| DankMaterialShell | Manual | Git clone to `~/.config/quickshell/dms` |

### Gentoo

**Special Notes:**
- Gentoo installs are **highly variable** and user-specific, success is not guaranteed.
  - `dankinstall` is most likely to succeed on a fresh stage3/systemd system
- Uses Portage package manager with GURU overlay for additional packages
- Automatically configures global USE flags in `/etc/portage/make.conf`
  - Will create or append to your existing USE flags.
- Automatically configures package-specific USE flags in `/etc/portage/package.use/danklinux`
- Unmasks packages as-needed with architecture keywords in `/etc/portage/package.accept_keywords/danklinux`
- Supports both `amd64` and `arm64` architectures dynamically
- If not using bin packages, prepare for long compilation times
- **Ghostty** is removed from the options, due to extremely long compilation time of its

**Package Sources:**
| Package | Source | Notes |
|---------|---------|-------|
| System packages (git, etc.) | Official repos | Via `emerge` |
| niri | GURU overlay | With dbus and screencast USE flags |
| hyprland | Official repos (GURU for -git) | Depends on variant selection, with X USE flag |
| quickshell | GURU overlay | Always uses live ebuild (`**` keywords), full feature set |
| matugen | GURU overlay | Color generation tool |
| cliphist | GURU overlay | Clipboard manager |
| hyprpicker | GURU overlay | Color picker for Hyprland |
| xdg-desktop-portal-gtk | Official repos | With wayland and X USE flags |
| mate-polkit | Official repos | PolicyKit authentication agent |
| accountsservice | Official repos | User account management |
| dgop | Manual | Built from source with Go |
| xwayland-satellite | Manual | For niri X11 app support |
| grimblast | Manual | For Hyprland screenshot utility |
| DankMaterialShell | Manual | Git clone to `~/.config/quickshell/dms` |

**Global USE Flags:**
`X dbus udev alsa policykit jpeg png webp gif tiff svg brotli gdbm accessibility gtk qt6 egl gbm`

**Package-Specific USE Flags:**
- `sys-apps/xdg-desktop-portal-gtk`: wayland X
- `gui-wm/niri`: dbus screencast
- `gui-wm/hyprland`: X
- `dev-qt/qtbase`: wayland opengl vulkan widgets
- `dev-qt/qtdeclarative`: opengl vulkan
- `media-libs/mesa`: opengl vulkan
- `gui-apps/quickshell`: breakpad jemalloc sockets wayland layer-shell session-lock toplevel-management screencopy X pipewire tray mpris pam hyprland hyprland-global-shortcuts hyprland-focus-grab i3 i3-ipc bluetooth

### NixOS (Not supported by Dank Linux, but with Flake)

NixOS users should use the [dms flake](https://github.com/AvengeMedia/DankMaterialShell/tree/master?tab=readme-ov-file#nixos---via-home-manager)

## Manual Package Building

The installer handles manual package building for packages not available in repositories:

### quickshell (Ubuntu, Debian, openSUSE)
- Built from source using cmake
- Requires Qt6 development libraries
- Automatically handles build dependencies
- **openSUSE:** Uses special CFLAGS with rpm optflags and wayland include path

### matugen (Ubuntu, Debian, Fedora, openSUSE)
- Built from Rust source
- Requires cargo and rust toolchain
- Installed to `/usr/local/bin`

### dgop (All distros)
- Built from Go source
- Simple dependency-free build
- Installed to `/usr/local/bin`

### niri (Ubuntu, Debian)
- Built from Rust source
- Requires cargo and rust toolchain
- Complex build with multiple dependencies

## Commands

### dankinstall
Main installer with interactive TUI for initial setup

### dms
Management interface for DankMaterialShell:
- `dms` - Interactive management TUI
- `dms run` - Start interactive shell
- `dms run -d` - Start shell as daemon
- `dms restart` - Restart running DMS shell
- `dms kill` - Kill running DMS shell processes
- `dms ipc <command>` - Send IPC commands to running shell