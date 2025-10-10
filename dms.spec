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
Requires:       (quickshell or quickshell-git)
Recommends:     quickshell-git
Requires:       fira-code-fonts
Requires:       rsms-inter-fonts

# Core utilities (REQUIRED for DMS functionality)
Requires:       dgop
Requires:       cava
Requires:       wl-clipboard
Requires:       brightnessctl
Requires:       matugen
Requires:       cliphist
Requires:       material-symbols-fonts

# Recommended system packages
Recommends:     NetworkManager
Recommends:     gammastep
Recommends:     qt6ct

# Auto-require the CLI sub-package
Requires:       dms-cli = %{version}-%{release}

%description
DankMaterialShell (DMS) is a modern Wayland desktop shell built with Quickshell
and optimized for the niri and Hyprland compositors. Features notifications,
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
