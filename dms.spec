# Modular spec for DMS - stable and git builds
#
# Build types controlled by %git_build macro:
# - git_build=1 (default): Build from latest git commit (dms-git package)
# - git_build=0: Build from tagged release (dms package)

%global debug_package %{nil}

# Set build type - override with --define 'git_build 0' for stable releases
%{!?git_build: %global git_build 1}

%if %{git_build}
# Git build - use rpkg git macros
%global version {{{ git_dir_version }}}
%global pkg_summary DankMaterialShell - Material 3 inspired shell for Wayland compositors (git development version)
%else
# Stable build - use tagged version
%global version 1.0.0
%global pkg_summary DankMaterialShell - Material 3 inspired shell for Wayland compositors
%endif

Name:           dms
Version:        %{version}
Release:        1%{?dist}
Summary:        %{pkg_summary}

License:        GPL-3.0-only
URL:            https://github.com/AvengeMedia/DankMaterialShell

%if %{git_build}
VCS:            {{{ git_dir_vcs }}}
Source0:        {{{ git_dir_pack }}}
%else
Source0:        https://github.com/AvengeMedia/DankMaterialShell/archive/refs/tags/v%{version}.tar.gz#/dms-%{version}.tar.gz
%endif

# dms CLI tool sources
%if %{git_build}
# Git build: Compile from danklinux source
Source1:        https://github.com/AvengeMedia/danklinux/archive/refs/heads/master.tar.gz#/danklinux-master.tar.gz
# Vendored Go dependencies for danklinux (Copr has no network access)
Source2:        danklinux-vendor.tar.gz

BuildRequires:  git-core
BuildRequires:  golang >= 1.21
%else
# Stable build: Use pre-built binaries from DankMaterialShell releases
Source1:        https://github.com/AvengeMedia/DankMaterialShell/releases/download/v%{version}/dms-amd64.gz
Source2:        https://github.com/AvengeMedia/DankMaterialShell/releases/download/v%{version}/dms-amd64.gz.sha256
Source3:        https://github.com/AvengeMedia/DankMaterialShell/releases/download/v%{version}/dms-arm64.gz
Source4:        https://github.com/AvengeMedia/DankMaterialShell/releases/download/v%{version}/dms-arm64.gz.sha256

BuildRequires:  gzip
%endif

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
%if %{git_build}
Requires:       dms-cli = %{version}-%{release}
%else
Requires:       dms-cli = %{version}-%{release}
%endif

%description
DankMaterialShell (DMS) is a modern Wayland desktop shell built with Quickshell
and optimized for the niri and Hyprland compositors. Features notifications,
app launcher, wallpaper customization, and fully customizable with plugins.

Includes auto-theming for GTK/Qt apps with matugen, 20+ customizable widgets,
process monitoring, notification center, clipboard history, dock, control center,
lock screen, and comprehensive plugin system.

%if %{git_build}
This is the development version built from the latest git commit.
%endif

%package -n dms-cli
Summary:        DankMaterialShell CLI tool
License:        GPL-3.0-only
%if %{git_build}
URL:            https://github.com/AvengeMedia/danklinux
%else
URL:            https://github.com/AvengeMedia/DankMaterialShell
%endif

%description -n dms-cli
Command-line interface for DankMaterialShell configuration and management.
Provides native DBus bindings, NetworkManager integration, and system utilities.
%if %{git_build}
Built from danklinux repository master branch (development version).
%endif

%prep
%if %{git_build}
{{{ git_dir_setup_macro }}}

# Extract danklinux for building dms CLI
tar -xzf %{SOURCE1} -C %{_builddir}
tar -xzf %{SOURCE2} -C %{_builddir}/danklinux-master/
%else
%autosetup -n DankMaterialShell-%{version}

# Extract and verify the appropriate dms binary based on architecture
%ifarch x86_64

echo "$(cat %{SOURCE2} | cut -d' ' -f1)  %{SOURCE1}" | sha256sum -c - || { echo "Checksum mismatch!"; exit 1; }
gunzip -c %{SOURCE1} > dms
%endif
%ifarch aarch64

echo "$(cat %{SOURCE4} | cut -d' ' -f1)  %{SOURCE3}" | sha256sum -c - || { echo "Checksum mismatch!"; exit 1; }
gunzip -c %{SOURCE3} > dms
%endif
chmod +x dms
%endif

%build
%if %{git_build}
# Git build: Compile dms CLI from source
pushd %{_builddir}/danklinux-master
export CGO_CPPFLAGS="${CPPFLAGS}"
export CGO_CFLAGS="${CFLAGS}"
export CGO_CXXFLAGS="${CXXFLAGS}"
export CGO_LDFLAGS="${LDFLAGS}"
export GOFLAGS="-buildmode=pie -trimpath -ldflags=-linkmode=external -mod=vendor -modcacherw"

go build -mod=vendor -o dms ./cmd/dms
popd
%else
# Stable build: Use pre-built binary
%endif

%install
# Install dms-cli binary
%if %{git_build}
# Git: Install built binary
install -Dm755 %{_builddir}/danklinux-master/dms %{buildroot}%{_bindir}/dms-cli
%else
# Stable: Install pre-built binary
install -Dm755 dms %{buildroot}%{_bindir}/dms-cli
%endif

# Install shell files to XDG config location
install -dm755 %{buildroot}%{_sysconfdir}/xdg/quickshell/dms
cp -r ./* %{buildroot}%{_sysconfdir}/xdg/quickshell/dms/

# Remove git-related files
rm -rf %{buildroot}%{_sysconfdir}/xdg/quickshell/dms/.git*
rm -f %{buildroot}%{_sysconfdir}/xdg/quickshell/dms/.gitignore
rm -rf %{buildroot}%{_sysconfdir}/xdg/quickshell/dms/.github

%if ! %{git_build}
# Stable: Remove the dms binary from the config directory (if copied)
rm -f %{buildroot}%{_sysconfdir}/xdg/quickshell/dms/dms
%endif

%files
%license LICENSE
%doc README.md CONTRIBUTING.md
%{_sysconfdir}/xdg/quickshell/dms/

%files -n dms-cli
%{_bindir}/dms-cli

%changelog
%if %{git_build}
{{{ git_dir_changelog }}}
%else
* Thu Oct 09 2025 AvengeMedia <support@avengemedia.net> - 1.0.0-1
- Initial stable release
%endif
