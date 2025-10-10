# Spec for DMS - uses rpkg macros for both stable and git builds

%global debug_package %{nil}
%global version {{{ git_dir_version }}}
%global pkg_summary DankMaterialShell - Material 3 inspired shell for Wayland compositors

Name:           dms
Version:        %{version}
Release:        1%{?dist}
Summary:        %{pkg_summary}

License:        GPL-3.0-only
URL:            https://github.com/AvengeMedia/DankMaterialShell
VCS:            {{{ git_dir_vcs }}}
Source0:        {{{ git_dir_pack }}}

# dms CLI tool sources - compiled from danklinux
Source1:        https://github.com/AvengeMedia/danklinux/archive/refs/heads/master.tar.gz#/danklinux-master.tar.gz

BuildRequires:  git-core
BuildRequires:  golang >= 1.21
BuildRequires:  rpkg

# Core requirements - Shell and fonts
# Requires:     (quickshell or quickshell-git)
# DMS DankLinux CLI tool
Requires:       dms-cli = %{version}-%{release}
# Stateless CLI system monitor
Requires:       dgop
Requires:       fira-code-fonts
Requires:       material-symbols-fonts
Requires:       rsms-inter-fonts
Requires:       quickshell-git

# Core utilities (Highly recommended for DMS functionality)
Recommends:     brightnessctl   # Laptop screen brightness control
Recommends:     cava            # Audio visualizer
Recommends:     cliphist        # Clipboard manager
Recommends:     hyprpicker      # Color picker
Recommends:     matugen         # Material design color generator
Recommends:     wl-clipboard    # wl-copy, wl-paste

# Recommended system packages
Recommends:     gammastep       # NightMode
Recommends:     NetworkManager  # Network management
Recommends:     qt6ct           # Qt6 application theming

%description
DankMaterialShell (DMS) is a modern Wayland desktop shell built with Quickshell
and optimized for the niri and hyprland compositors. Features notifications,
app launcher, wallpaper customization, and fully customizable with plugins.

Includes auto-theming for GTK/Qt apps with matugen, 20+ customizable widgets,
process monitoring, notification center, clipboard history, dock, control center,
lock screen, and comprehensive plugin system.

%package -n dms-cli
Summary:        DankMaterialShell CLI tool
License:        GPL-3.0-only
URL:            https://github.com/AvengeMedia/danklinux

%description -n dms-cli
Command-line interface for DankMaterialShell configuration and management.
Provides native DBus bindings, NetworkManager integration, and system utilities.

%prep
{{{ git_dir_setup_macro }}}

# Extract danklinux for building dms CLI
tar -xzf %{SOURCE1} -C %{_builddir}

%build
# Compile dms CLI from danklinux source
pushd %{_builddir}/danklinux-master
export CGO_CPPFLAGS="${CPPFLAGS}"
export CGO_CFLAGS="${CFLAGS}"
export CGO_CXXFLAGS="${CXXFLAGS}"
export CGO_LDFLAGS="${LDFLAGS}"
export GOFLAGS="-buildmode=pie -trimpath -ldflags=-linkmode=external -mod=readonly -modcacherw"

go build -o dms ./cmd/dms
popd

%install
# Install dms-cli binary
install -Dm755 %{_builddir}/danklinux-master/dms %{buildroot}%{_bindir}/dms-cli

# Install shell files to XDG config location
install -dm755 %{buildroot}%{_sysconfdir}/xdg/quickshell/dms
cp -r ./* %{buildroot}%{_sysconfdir}/xdg/quickshell/dms/

# Remove git-related files
rm -rf %{buildroot}%{_sysconfdir}/xdg/quickshell/dms/.git*
rm -f %{buildroot}%{_sysconfdir}/xdg/quickshell/dms/.gitignore
rm -rf %{buildroot}%{_sysconfdir}/xdg/quickshell/dms/.github

%files
%license LICENSE
%doc README.md CONTRIBUTING.md
%{_sysconfdir}/xdg/quickshell/dms/

%files -n dms-cli
%{_bindir}/dms-cli

%changelog
{{{ git_dir_changelog }}}
