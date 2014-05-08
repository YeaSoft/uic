# avoid dpkg-dev dependency; fish out the version with sed
VERSION := $(shell sed 's/.*(\(.*\)).*/\1/; q' debian/changelog)


all:

clean: uninstall

install:
	mkdir -p $(DESTDIR)/usr/share/yea
	mkdir -p $(DESTDIR)/usr/bin
	mkdir -p $(DESTDIR)/etc

	install -o root -g root -m 0644 etc/uic.conf		$(DESTDIR)/etc
	install -o root -g root -m 0744 bin/uic			$(DESTDIR)/usr/bin
	install -o root -g root -m 0744 bin/uic_get		$(DESTDIR)/usr/bin
	install -o root -g root -m 0744 bin/uic_create		$(DESTDIR)/usr/bin
	install -o root -g root -m 0744 bin/uic_upgrade		$(DESTDIR)/usr/bin
	install -o root -g root -m 0744 bin/uic_install		$(DESTDIR)/usr/bin
	install -o root -g root -m 0744 bin/uic_remove		$(DESTDIR)/usr/bin
	install -o root -g root -m 0744 bin/uic_enter		$(DESTDIR)/usr/bin
	install -o root -g root -m 0744 bin/uic_build		$(DESTDIR)/usr/bin
	install -o root -g root -m 0744 bin/uic_clean		$(DESTDIR)/usr/bin
	install -o root -g root -m 0744 bin/uic_attach		$(DESTDIR)/usr/bin
	install -o root -g root -m 0744 bin/uic_detach		$(DESTDIR)/usr/bin
	install -o root -g root -m 0744 bin/uic_pack		$(DESTDIR)/usr/bin
	sed 's/@VERSION@/$(VERSION)/g' yea/uicutils.sh >	$(DESTDIR)/usr/share/yea/uicutils.sh
	touch -r yea/uicutils.sh				$(DESTDIR)/usr/share/yea/uicutils.sh
	chown root:root 					$(DESTDIR)/usr/share/yea/uicutils.sh
	chmod 644						$(DESTDIR)/usr/share/yea/uicutils.sh

uninstall:
	rm -f $(DESTDIR)/etc/uic.conf
	rm -f $(DESTDIR)/usr/share/yea/uicutils.sh
	rm -f $(DESTDIR)/usr/bin/uic_pack
	rm -f $(DESTDIR)/usr/bin/uic_detach
	rm -f $(DESTDIR)/usr/bin/uic_attach
	rm -f $(DESTDIR)/usr/bin/uic_clean
	rm -f $(DESTDIR)/usr/bin/uic_build
	rm -f $(DESTDIR)/usr/bin/uic_enter
	rm -f $(DESTDIR)/usr/bin/uic_upgrade
	rm -f $(DESTDIR)/usr/bin/uic_remove
	rm -f $(DESTDIR)/usr/bin/uic_install
	rm -f $(DESTDIR)/usr/bin/uic_create
	rm -f $(DESTDIR)/usr/bin/uic_get
	rm -f $(DESTDIR)/usr/bin/uic
