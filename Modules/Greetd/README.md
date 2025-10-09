# Dank (dms) Greeter

A greeter for [greetd](https://github.com/kennylevinsen/greetd) that follows the aesthetics of the dms lock screen.

## Features

- **Multi user**: Login with any system user
- **dms sync**: Sync settings with dms for consistent styling between shell and greeter
- **niri or Hyprland**: Use either niri or Hyprland for the greeter's compositor.
- **Custom PAM**: Supports custom PAM configuration in `/etc/pam.d/dankshell`
- **Session Memory**: Remembers last selected session and user

## Installation

### Automatic

The easiest thing is to run `dms greeter install` or `dms` for interactive installation.

### Manual

1. Install `greetd` (in most distro's standard repositories) and `quickshell`
2. Clone the dms project to `/etc/xdg/quickshell/dms-greeter`
```bash
sudo git clone https://github.com/AvengeMedia/DankMaterialShell.git /etc/xdg/quickshell/dms-greeter
```
3. Copy `assets/dms-greeter` to `/usr/local/bin/dms-greeter`:
```bash
sudo cp assets/dms-greeter /usr/local/bin/dms-greeter
sudo chmod +x /usr/local/bin/dms-greeter
```
4. Create greeter cache directory with proper permissions:
```bash
sudo mkdir -p /var/cache/dmsgreeter
sudo chown greeter:greeter /var/cache/dmsgreeter
sudo chmod 770 /var/cache/dmsgreeter
```
6. Edit or create `/etc/greetd/config.toml`:
```toml
[terminal]
vt = 1

[default_session]
user = "greeter"
# Change compositor to sway or hyprland if preferred
command = "/usr/local/bin/dms-greeter --command niri"
```

Enable the greeter with `sudo systemctl enable greetd`

#### Legacy installation (deprecated)

If you prefer the old method with separate shell scripts and config files:
1. Copy `assets/dms-niri.kdl` or `assets/dms-hypr.conf` to `/etc/greetd`
2. Copy `assets/greet-niri.sh` or `assets/greet-hyprland.sh` to `/usr/local/bin/start-dms-greetd.sh`
3. Edit the config file and replace `_DMS_PATH_` with your DMS installation path
4. Configure greetd to use `/usr/local/bin/start-dms-greetd.sh`

### NixOS

To install the greeter on NixOS add the repo to your flake inputs as described in the readme. Then somewhere in your NixOS config add this to imports:
```nix
imports = [
  inputs.dankMaterialShell.nixosModules.greeter
]
```

Enable the greeter with this in your NixOS config:
```nix
programs.dankMaterialShell.greeter = {
  enable = true;
  compositor.name = "niri"; # or set to hyprland
  configHome = "/home/user"; # optionally copyies that users DMS settings (and wallpaper if set) to the greeters data directory as root before greeter starts
};
```

## Usage

### Using dms-greeter wrapper (recommended)

The `dms-greeter` wrapper simplifies running the greeter with any compositor:

```bash
dms-greeter --command niri
dms-greeter --command hyprland
dms-greeter --command sway
dms-greeter --command niri -C /path/to/custom-niri.kdl
```

Configure greetd to use it in `/etc/greetd/config.toml`:
```toml
[terminal]
vt = 1

[default_session]
user = "greeter"
command = "/usr/local/bin/dms-greeter --command niri"
```

### Manual usage

To run dms in greeter mode you can also manually set environment variables:

```bash
DMS_RUN_GREETER=1 qs -p /path/to/dms
```

### Configuration

#### Compositor

You can configure compositor specific settings such as outputs/displays the same as you would in niri or Hyprland.

Simply edit `/etc/greetd/dms-niri.kdl` or `/etc/greetd/dms-hypr.conf` to change compositor settings for the greeter

#### Personalization

Wallpapers and themes and weather and clock formats and things are a TODO on the documentation, but it's configured exactly the same as dms.

You can synchronize those configurations with a specific user if you want greeter settings to always mirror the shell.

The greeter uses the `dms-greeter` group for file access permissions, so ensure your user and the greeter user are both members of this group.

```bash
# For core settings (theme, clock formats, etc)
sudo ln -sf ~/.config/DankMaterialShell/settings.json /var/cache/dms-greeter/settings.json
# For state (mainly you would configure wallpaper in this file)
sudo ln -sf ~/.local/state/DankMaterialShell/session.json /var/cache/dms-greeter/session.json
# For wallpaper based theming
sudo ln -sf ~/.cache/quickshell/dankshell/dms-colors.json /var/cache/dms-greeter/dms-colors.json
```

You can override the configuration path with the `DMS_GREET_CFG_DIR` environment variable or the `--cache-dir` flag when using `dms-greeter`. The default is `/var/cache/dmsgreeter`.

The cache directory should be owned by `greeter:greeter` with `770` permissions.