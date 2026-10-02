# version and release are passed by the Makefile from the VERSION file
%{!?pkgversion: %global pkgversion 0}
%{!?pkgrelease: %global pkgrelease 1}

%global debug_package %{nil}
%global installdir /usr/share/pve-manager/virtio-win

Name:           pxvirt-virtio-win
Version:        %{pkgversion}
Release:        %{pkgrelease}
Summary:        VirtIO drivers for Windows guests (slim) for PXVirt
License:        Redistributable, see virtio-win_license.txt
URL:            https://github.com/virtio-win/kvm-guest-drivers-windows
Source0:        virtio-win-slim-%{version}.tar.gz
BuildArch:      noarch

%description
A reduced set of the virtio-win drivers (viostor, vioscsi, NetKVM, Balloon,
vioserial) for Windows 10/11 and Server 2016-2025 on amd64 and ARM64, plus the
QEMU guest agent installer.

The drivers are installed to /usr/share/pve-manager/virtio-win/ and are used by
the PXVirt autoinstall feature to provide drivers to Windows Setup.

%prep
%setup -q -n virtio-win

%build

%install
mkdir -p %{buildroot}%{installdir}
cp -r . %{buildroot}%{installdir}/

%files
%{installdir}

%changelog
* Fri Oct 02 2026 Lierfang Support Team <itsupport@lierfang.com> - 0.1.271-1
- initial release
