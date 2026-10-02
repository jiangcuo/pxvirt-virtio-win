# version and release are passed by the Makefile from the VERSION file
%{!?pkgversion: %global pkgversion 0}
%{!?pkgrelease: %global pkgrelease 1}

%global debug_package %{nil}
%global installdir /usr/share/pve-manager/virtio-win
%global isodir /var/lib/vz/template/iso

Name:           pxvirt-virtio-win
Version:        %{pkgversion}
Release:        %{pkgrelease}
Summary:        VirtIO drivers for Windows guests (slim) for PXVirt
License:        Redistributable, see virtio-win_license.txt
URL:            https://github.com/virtio-win/kvm-guest-drivers-windows
Source0:        virtio-win-slim-%{version}.tar.gz
Source1:        pxvirt-virtio-win.iso
BuildArch:      noarch

%description
A reduced set of the virtio-win drivers (viostor, vioscsi, NetKVM, Balloon,
vioserial) for Windows 10/11 and Server 2016-2025 on amd64 and ARM64, plus the
QEMU guest agent installer.

The drivers are installed to /usr/share/pve-manager/virtio-win/ and are used by
the PXVirt autoinstall feature to provide drivers to Windows Setup.

%package iso
Summary:        VirtIO drivers ISO for Windows guests (slim) for PXVirt

%description iso
ISO image with the same reduced set of virtio-win drivers and the QEMU guest
agent as pxvirt-virtio-win.

The image is installed as /var/lib/vz/template/iso/pxvirt-virtio-win.iso and
can be attached to Windows guests as local:iso/pxvirt-virtio-win.iso.

%prep
%setup -q -n virtio-win

%build

%install
mkdir -p %{buildroot}%{installdir}
cp -r . %{buildroot}%{installdir}/
install -D -m 0644 %{SOURCE1} %{buildroot}%{isodir}/pxvirt-virtio-win.iso

%files
%{installdir}

%files iso
%{isodir}/pxvirt-virtio-win.iso

%changelog
* Fri Oct 02 2026 Lierfang Support Team <itsupport@lierfang.com> - 0.1.271-3
- use qemu-ga 11.1.2-1 from jiangcuo/qemu-guest-agent for x86_64 and ARM64

* Fri Oct 02 2026 Lierfang Support Team <itsupport@lierfang.com> - 0.1.271-2
- add pxvirt-virtio-win-iso package with a slim ISO in /var/lib/vz/template/iso

* Fri Oct 02 2026 Lierfang Support Team <itsupport@lierfang.com> - 0.1.271-1
- initial release
