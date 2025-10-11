# Spec for DMS - Produces stable and git builds

%global debug_package %{nil}

%global version_tag %(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0")
%global commit_count %(git rev-list --count HEAD 2>/dev/null || echo "0")
%global short_commit %(git rev-parse --short=8 HEAD 2>/dev/null || echo "00000000")
%global on_tag %([ "$(git describe --exact-match --tags 2>/dev/null | sed 's/^v//')" = "%{version_tag}" ] && echo 1 || echo 0)

%if 0%{?on_tag}
%global version %{version_tag}
%else
%global version 0.0.git.%{commit_count}.%{short_commit}
%endif

%global pkg_summary DankMaterialShell - Material 3 inspired shell for Wayland compositors

Name:           dms
Version:        %{version}
Release:        1%{?dist}
Summary:        %{pkg_summary}

License:        GPL-3.0-only
URL:            https://github.com/AvengeMedia/DankMaterialShell
VCS:            git+https://github.com/AvengeMedia/DankMaterialShell.git
Source0:        https://github.com/AvengeMedia/DankMaterialShell/archive/%{short_commit}/DankMaterialShell-%{short_commit}.tar.gz

# DMS CLI tool sources - compiled from danklinux
Source1:        https://github.com/AvengeMedia/danklinux/archive/refs/heads/master.tar.gz#/danklinux-master.tar.gz

BuildRequires:  git-core
BuildRequires:  golang >= 1.21

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
%setup -q -n DankMaterialShell-%{short_commit}

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
* %(date "+%a %b %d %Y") AvengeMedia <noreply@avengemedia.com> - %{version}-%{release}
- Automated build from git commit %{short_commit}
