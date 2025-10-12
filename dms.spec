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

# DMS CLI tool sources - compiled from danklinux
Source1:        https://github.com/AvengeMedia/danklinux/archive/refs/heads/master.tar.gz#/danklinux-master.tar.gz

BuildRequires:  git-core
BuildRequires:  golang >= 1.21
BuildRequires:  rpkg

# Core requirements - Shell and fonts
# Requires:     (quickshell or quickshell-git)
Requires:       dms-cli = %{version}-%{release}
Requires:       dgop
Requires:       fira-code-fonts
Requires:       material-symbols-fonts
Requires:       rsms-inter-fonts
Requires:       quickshell-git

# Core utilities (Highly recommended for DMS functionality)
Recommends:     brightnessctl
Recommends:     cava
Recommends:     cliphist
Recommends:     hyprpicker
Recommends:     matugen
Recommends:     wl-clipboard

# Recommended system packages
Recommends:     gammastep
Recommends:     NetworkManager
Suggests:       qt6ct

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

# Use RPM version and build info
BUILD_TIME=$(date -u '+%%Y-%%m-%%d_%%H:%%M:%%S')

# Build with CGO disabled and version info
export CGO_ENABLED=0
export GOFLAGS="-trimpath -mod=readonly -modcacherw"

go build \
    -tags distro_binary \
    -ldflags="-s -w -X main.Version=%{version}-%{release} -X main.buildTime=${BUILD_TIME} -X main.commit=%{version}" \
    -o dms \
    ./cmd/dms

popd

%install
# Install dms-cli binary
install -Dm755 %{_builddir}/danklinux-master/dms %{buildroot}%{_bindir}/dms

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
%{_bindir}/dms

%changelog
{{{ git_dir_changelog }}}
