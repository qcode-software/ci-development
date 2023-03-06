NAME=qcode-linter
RELEASE=0
DPKG_NAME=qcode-linter-$(VERSION)
INSTALL_DIR=qcode-linter
TEMP_PATH=/tmp/$(INSTALL_DIR)
MAINTAINER=hackers@qcode.co.uk
REMOTEUSER=deb
REMOTEHOST=deb.qcode.co.uk
REMOTEDIR=deb.qcode.co.uk

.PHONY: all test

all: check-version package upload clean
package: check-version
	# Copy files to pristine temporary directory
	rm -rf $(TEMP_PATH)
	mkdir $(TEMP_PATH)
	rm -rf package
	mkdir package
	curl --fail -K ~/.curlrc_github -L -o v$(VERSION).tar.gz \
	https://api.github.com/repos/qcode-software/ci-development/tarball/v$(VERSION)
	tar --strip-components=1 --exclude Makefile --exclude .github --exclude tests \
	--exclude package.tcl --exclude pkg_mkIndex -xzvf v$(VERSION).tar.gz -C $(TEMP_PATH)
	./package.tcl $(TEMP_PATH)/tcl package ${NAME} ${VERSION}
	./pkg_mkIndex package
	# checkinstall
	fakeroot checkinstall -D --deldoc --backup=no --install=no --pkgname=$(DPKG_NAME) \
	--pkgversion=$(VERSION) --pkgrelease=$(RELEASE) -A all -y \
	--maintainer $(MAINTAINER) --pkglicense="BSD" --reset-uids=yes \
	--requires "tcl,tcllib" --replaces none --conflicts none \
	make install
install:
	mkdir -p /usr/lib/tcltk/$(NAME)$(VERSION)
	cp package/*.tcl /usr/lib/tcltk/$(NAME)$(VERSION)/
	chmod 755 $(TEMP_PATH)/scripts/linting.tcl
	cp $(TEMP_PATH)/scripts/linting.tcl /usr/bin/$(NAME)

upload: check-version
	scp $(DPKG_NAME)_$(VERSION)-$(RELEASE)_all.deb "$(REMOTEUSER)@$(REMOTEHOST):$(REMOTEDIR)/debs"
	ssh $(REMOTEUSER)@$(REMOTEHOST) reprepro -b $(REMOTEDIR) includedeb stretch $(REMOTEDIR)/debs/$(DPKG_NAME)_$(VERSION)-$(RELEASE)_all.deb
	ssh $(REMOTEUSER)@$(REMOTEHOST) reprepro -b $(REMOTEDIR) copy buster stretch $(DPKG_NAME)
	ssh $(REMOTEUSER)@$(REMOTEHOST) rm -f $(REMOTEDIR)/debs/$(DPKG_NAME)_$(VERSION)-$(RELEASE)_all.deb

clean: check-version
	rm -rf package
	rm -rf $(TEMP_PATH)
	rm $(DPKG_NAME)_$(VERSION)-$(RELEASE)_all.deb
	rm -f v$(VERSION).tar.gz

check-version:
ifndef VERSION
    $(error VERSION is undefined. Usage make VERSION=x.x.x)
endif
