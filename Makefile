include VERSION

PACKAGE = pxvirt-virtio-win
BUILDDIR ?= $(CURDIR)/build
export BUILDDIR

DEB = $(PACKAGE)_$(VIRTIO_WIN_VERSION)-$(PKG_RELEASE)_all.deb
RPMTOP = $(BUILDDIR)/rpmbuild
RPM_SOURCE = $(RPMTOP)/SOURCES/virtio-win-slim-$(VIRTIO_WIN_VERSION).tar.gz

.PHONY: all
all: deb rpm

.PHONY: fetch
fetch:
	scripts/fetch.sh

$(BUILDDIR)/virtio-win/VERSION: VERSION slim.conf scripts/slim.sh
	scripts/fetch.sh
	scripts/slim.sh

.PHONY: slim
slim: $(BUILDDIR)/virtio-win/VERSION

.PHONY: deb
deb: slim
	test "$$(dpkg-parsechangelog -S Version)" = "$(VIRTIO_WIN_VERSION)-$(PKG_RELEASE)" \
	    || (echo "debian/changelog does not match VERSION" && false)
	rm -rf debian/$(PACKAGE) debian/.debhelper debian/files debian/*.substvars
	dpkg-buildpackage -b -us -uc --no-pre-clean
	mkdir -p $(BUILDDIR)/out
	mv ../$(DEB) $(BUILDDIR)/out/
	rm -f ../$(PACKAGE)_*.buildinfo ../$(PACKAGE)_*.changes

.PHONY: rpm
rpm: slim
	mkdir -p $(RPMTOP)/SOURCES $(BUILDDIR)/out
	tar -C $(BUILDDIR) -czf $(RPM_SOURCE) virtio-win
	rpmbuild -bb \
	    --define "_topdir $(RPMTOP)" \
	    --define "pkgversion $(VIRTIO_WIN_VERSION)" \
	    --define "pkgrelease $(PKG_RELEASE)" \
	    rpm/$(PACKAGE).spec
	find $(RPMTOP)/RPMS -name '*.rpm' -exec mv {} $(BUILDDIR)/out/ \;

.PHONY: update
update:
	scripts/update-version.sh

.PHONY: clean
clean:
	rm -rf $(BUILDDIR) debian/$(PACKAGE) debian/.debhelper debian/files \
	    debian/*.substvars debian/*.debhelper.log debian/debhelper-build-stamp
