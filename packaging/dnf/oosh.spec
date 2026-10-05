Name:           oosh
Version:        1.0.0
Release:        1
Summary:        openOODA Sovereign Shell - Intent-Driven Capability-Bounded Shell
License:        Apache-2.0
URL:            https://github.com/openOODA-tools/oosh
BuildArch:      x86_64

%description
oosh is the openOODA Sovereign Shell: an intent-driven, ambient,
capability-bounded interactive shell for the AI era with native POSIX
execution, process isolation, Varlink IPC, and autonomous recovery.

%prep

%build

%install
mkdir -p %{buildroot}/usr/bin
install -m 755 %{bin_path} %{buildroot}/usr/bin/oosh

%files
%defattr(-,root,root,-)
/usr/bin/oosh

%changelog
* Mon Oct 05 2026 openOODA Team <team@openooda.org> - 1.0.0-1
- Release v1.0.0: Canonical sovereign shell release with web, dnf, and apt installers
