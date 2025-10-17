# Spec for DMS Greeter - Git builds using rpkg macros

%global debug_package %{nil}
%global version {{{ git_dir_version }}}
%global pkg_summary DankMaterialShell greeter for greetd

Name:           dms-greeter
Version:        %{version}
Release:        0.git%{?dist}
Summary:        %{pkg_summary}

License:        GPL-3.0-only
URL:            https://github.com/AvengeMedia/DankMaterialShell
VCS:            {{{ git_dir_vcs }}}
Source0:        {{{ git_dir_pack }}}

BuildRequires:  git-core
BuildRequires:  rpkg

Requires:       greetd
Requires:       (quickshell-git or quickshell)
Requires:       material-symbols-fonts
Requires(post): /usr/sbin/useradd
Requires(post): /usr/sbin/groupadd

Recommends:     policycoreutils-python-utils
Suggests:       niri
Suggests:       hyprland
Suggests:       sway

# Provides:       greetd-dms-greeter = %{version}-%{release}
# Conflicts:      greetd-dms-greeter

%description
DankMaterialShell greeter for greetd login manager. A modern, Material Design 3
inspired greeter interface built with Quickshell for Wayland compositors.

Supports multiple compositors including Niri, Hyprland, and Sway with automatic
compositor detection and configuration. Features session selection, user
authentication, and dynamic theming.

%prep
{{{ git_dir_setup_macro }}}

%build
# QML-based application

%install
# Install greeter files to XDG config location
install -dm755 %{buildroot}%{_sysconfdir}/xdg/quickshell/dms-greeter
cp -r * %{buildroot}%{_sysconfdir}/xdg/quickshell/dms-greeter/

# Install launcher script
install -Dm755 Modules/Greetd/assets/dms-greeter %{buildroot}%{_bindir}/dms-greeter

# Install documentation
install -Dm644 Modules/Greetd/README.md %{buildroot}%{_docdir}/dms-greeter/README.md

# Create cache directory for greeter data
install -dm750 %{buildroot}%{_localstatedir}/cache/dms-greeter

# Create greeter home directory
install -dm755 %{buildroot}%{_sharedstatedir}/greeter

# Note: We do NOT install a PAM config here to avoid conflicting with greetd package
# Instead, we verify/fix it in %post if needed

# Remove build and development files
rm -rf %{buildroot}%{_sysconfdir}/xdg/quickshell/dms-greeter/.git*
rm -f %{buildroot}%{_sysconfdir}/xdg/quickshell/dms-greeter/.gitignore
rm -rf %{buildroot}%{_sysconfdir}/xdg/quickshell/dms-greeter/.github
rm -f %{buildroot}%{_sysconfdir}/xdg/quickshell/dms-greeter/*.spec
rm -f %{buildroot}%{_sysconfdir}/xdg/quickshell/dms-greeter/dms.spec
rm -f %{buildroot}%{_sysconfdir}/xdg/quickshell/dms-greeter/dms-greeter.spec

%files
%license LICENSE
%doc %{_docdir}/dms-greeter/README.md
%{_bindir}/dms-greeter
%{_sysconfdir}/xdg/quickshell/dms-greeter/
%dir %attr(0750,greeter,greeter) %{_localstatedir}/cache/dms-greeter
%dir %attr(0755,greeter,greeter) %{_sharedstatedir}/greeter

%pre
# Create greeter user/group if they don't exist (greetd expects this)
getent group greeter >/dev/null || groupadd -r greeter
getent passwd greeter >/dev/null || \
    useradd -r -g greeter -d %{_sharedstatedir}/greeter -s /bin/bash \
    -c "System Greeter" greeter
exit 0

%post

# Set SELinux contexts for greeter files on Fedora systems
if [ -x /usr/sbin/semanage ] && [ -x /usr/sbin/restorecon ]; then
    # Greeter launcher binary
    semanage fcontext -a -t bin_t '%{_bindir}/dms-greeter' 2>/dev/null || true
    restorecon -v %{_bindir}/dms-greeter 2>/dev/null || true
    
    # Greeter home directory
    semanage fcontext -a -t user_home_dir_t '%{_sharedstatedir}/greeter(/.*)?' 2>/dev/null || true
    restorecon -Rv %{_sharedstatedir}/greeter 2>/dev/null || true
    
    # Cache directory for greeter data
    semanage fcontext -a -t cache_home_t '%{_localstatedir}/cache/dms-greeter(/.*)?' 2>/dev/null || true
    restorecon -Rv %{_localstatedir}/cache/dms-greeter 2>/dev/null || true
    
    # Config directory
    semanage fcontext -a -t etc_t '%{_sysconfdir}/xdg/quickshell/dms-greeter(/.*)?' 2>/dev/null || true
    restorecon -Rv %{_sysconfdir}/xdg/quickshell/dms-greeter 2>/dev/null || true
    
    # PAM configuration
    restorecon -v %{_sysconfdir}/pam.d/greetd 2>/dev/null || true
fi

# Ensure proper ownership of greeter directories
chown -R greeter:greeter %{_localstatedir}/cache/dms-greeter 2>/dev/null || true
chown -R greeter:greeter %{_sharedstatedir}/greeter 2>/dev/null || true

# Verify PAM configuration - only fix if insufficient
PAM_CONFIG="/etc/pam.d/greetd"
if [ ! -f "$PAM_CONFIG" ]; then
    # PAM config doesn't exist - create it
    cat > "$PAM_CONFIG" << 'PAM_EOF'
#%PAM-1.0
auth       substack    system-auth
auth       include     postlogin

account    required    pam_nologin.so
account    include     system-auth

password   include     system-auth

session    required    pam_selinux.so close
session    required    pam_loginuid.so
session    required    pam_selinux.so open
session    optional    pam_keyinit.so force revoke
session    include     system-auth
session    include     postlogin
PAM_EOF
    chmod 644 "$PAM_CONFIG"
    echo "Created PAM configuration for greetd"
elif ! grep -q "pam_systemd\|system-auth" "$PAM_CONFIG"; then
    # PAM config exists but looks insufficient - back it up and replace
    cp "$PAM_CONFIG" "$PAM_CONFIG.backup-dms-greeter"
    cat > "$PAM_CONFIG" << 'PAM_EOF'
#%PAM-1.0
auth       substack    system-auth
auth       include     postlogin

account    required    pam_nologin.so
account    include     system-auth

password   include     system-auth

session    required    pam_selinux.so close
session    required    pam_loginuid.so
session    required    pam_selinux.so open
session    optional    pam_keyinit.so force revoke
session    include     system-auth
session    include     postlogin
PAM_EOF
    chmod 644 "$PAM_CONFIG"
    echo "Updated PAM configuration (old config backed up to $PAM_CONFIG.backup-dms-greeter)"
fi

# Auto-configure greetd config
GREETD_CONFIG="/etc/greetd/config.toml"
CONFIG_STATUS="Not modified (already configured)"

# Check if niri or hyprland exists
COMPOSITOR="niri"
if ! command -v niri >/dev/null 2>&1; then
        if command -v Hyprland >/dev/null 2>&1; then
                COMPOSITOR="hyprland"
        fi
fi

# If config doesn't exist, create a default one
if [ ! -f "$GREETD_CONFIG" ]; then
        mkdir -p /etc/greetd
        cat > "$GREETD_CONFIG" << 'GREETD_EOF'
[terminal]
vt = 1

[default_session]
user = "greeter"
command = "/usr/bin/dms-greeter --command COMPOSITOR_PLACEHOLDER"
GREETD_EOF
        sed -i "s|COMPOSITOR_PLACEHOLDER|$COMPOSITOR|" "$GREETD_CONFIG"
        CONFIG_STATUS="Created new config with $COMPOSITOR ✓"
# If config exists and doesn't have dms-greeter, update it
elif ! grep -q "dms-greeter" "$GREETD_CONFIG"; then
        # Backup existing config
        BACKUP_FILE="${GREETD_CONFIG}.backup-$(date +%%Y%%m%%d-%%H%%M%%S)"
        cp "$GREETD_CONFIG" "$BACKUP_FILE" 2>/dev/null || true

        # Update command in default_session section
        sed -i "/^\[default_session\]/,/^\[/ s|^command =.*|command = \"/usr/bin/dms-greeter --command $COMPOSITOR\"|" "$GREETD_CONFIG"
        sed -i '/^\[default_session\]/,/^\[/ s|^user =.*|user = "greeter"|' "$GREETD_CONFIG"
        CONFIG_STATUS="Updated existing config (backed up) with $COMPOSITOR ✓"
fi

# Only show banner on initial install
if [ "$1" -eq 1 ]; then
cat << EOF

===============================================================================
    DMS Greeter Installation Complete!
===============================================================================

Configuration status:
    - Greeter cache directory: /var/cache/dms-greeter (created with proper permissions)
    - SELinux contexts: Applied (if semanage available)
    - Greetd config: $CONFIG_STATUS

Next steps to enable the greeter:

1. IMPORTANT: Disable any existing display managers:
     sudo systemctl disable gdm sddm lightdm
     (Only greetd should run as the display manager)

2. Verify greetd configuration:
     Check /etc/greetd/config.toml contains:

     [default_session]
     user = "greeter"
     command = "/usr/bin/dms-greeter --command niri"

     (Also supported: hyprland, sway)
     Note: Existing config backed up to config.toml.backup-* if modified

3. Enable greetd service:
     sudo systemctl enable greetd

4. (Optional) Sync your user's theme with the greeter:
     sudo usermod -aG greeter YOUR_USERNAME
     # Then LOGOUT and LOGIN to apply group membership
     ln -sf ~/.config/DankMaterialShell/settings.json /var/cache/dms-greeter/settings.json
     ln -sf ~/.local/state/DankMaterialShell/session.json /var/cache/dms-greeter/session.json
     ln -sf ~/.cache/quickshell/dankshell/dms-colors.json /var/cache/dms-greeter/colors.json

Documentation: /usr/share/doc/dms-greeter/README.md
===============================================================================

EOF
fi

%postun
# Clean up SELinux contexts on package removal
if [ "$1" -eq 0 ] && [ -x /usr/sbin/semanage ]; then
    semanage fcontext -d '%{_bindir}/dms-greeter' 2>/dev/null || true
    semanage fcontext -d '%{_sharedstatedir}/greeter(/.*)?' 2>/dev/null || true
    semanage fcontext -d '%{_localstatedir}/cache/dms-greeter(/.*)?' 2>/dev/null || true
    semanage fcontext -d '%{_sysconfdir}/xdg/quickshell/dms-greeter(/.*)?' 2>/dev/null || true
fi

%changelog
{{{ git_dir_changelog }}}
