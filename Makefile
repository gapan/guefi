PREFIX ?= /usr/local
DESTDIR ?= /
PACKAGE_LOCALE_DIR ?= /usr/share/locale

.PHONY: all
all: mo desktop policy

.PHONY: mo
mo:
	for i in `ls po/*.po`; do \
		msgfmt $$i -o `echo $$i | sed "s/\.po//"`.mo; \
	done

.PHONY: desktop
desktop:
	intltool-merge po/ -d -u \
		guefi.desktop.in guefi.desktop

.PHONY: policy
policy:
	itstool -j org.salixos.guefi.policy.in -o org.salixos.guefi.policy po/*.mo

.PHONY: updatepo
updatepo:
	for i in `ls po/*.po`; do \
		msgmerge -UNs $$i po/guefi.pot; \
	done
	rm -f po/*~

.PHONY: pot
pot:
	itstool -i /usr/share/gettext/its/polkit.its \
		-o po/guefi.pot org.salixos.guefi.policy.in
	xgettext --from-code=utf-8 \
		-j \
		-x po/EXCLUDE \
		-L Glade \
		-o po/guefi.pot \
		src/guefi.ui
	xgettext --from-code=utf-8 \
		-j \
		-L Python \
		-o po/guefi.pot \
		src/guefi
	intltool-extract --type="gettext/ini" \
		guefi.desktop.in
	sed -i '/char \*s = N_("guefi");/d' *.in.h
	xgettext --from-code=utf-8 -j -L C -kN_ \
		-o po/guefi.pot guefi.desktop.in.h
	rm -f guefi.desktop.in.h

.PHONY: clean
clean:
	rm -f po/*.mo
	rm -f po/*.po~
	rm -f guefi.desktop
	rm -f org.salixos.guefi.policy

.PHONY: install
install: install-icons install-mo
	install -d -m 755 $(DESTDIR)/usr/sbin
	install -d -m 755 $(DESTDIR)/usr/bin
	install -d -m 755 $(DESTDIR)/usr/share/polkit-1/actions
	install -d -m 755 $(DESTDIR)/usr/share/applications
	install -d -m 755 $(DESTDIR)/usr/share/guefi
	install -d -m 755 $(DESTDIR)/etc
	install -m 755 src/guefi $(DESTDIR)/usr/sbin/
	install -m 755 src/guefi-pkexec $(DESTDIR)/usr/bin/
	install -m 755 org.salixos.guefi.policy $(DESTDIR)/usr/share/polkit-1/actions/
	install -m 644 src/guefi.ui $(DESTDIR)/usr/share/guefi/
	install -m 644 guefi.desktop $(DESTDIR)/usr/share/applications/

.PHONY: install-icons
install-icons:
	install -d -m 755 $(DESTDIR)/usr/share/icons/hicolor/scalable/apps/
	install -m 644 icons/guefi.svg \
		$(DESTDIR)/usr/share/icons/hicolor/scalable/apps/
	for i in 48 32 24 22 16; do \
		install -d -m 755 \
		$(DESTDIR)/usr/share/icons/hicolor/$${i}x$${i}/apps/ \
		2> /dev/null; \
		install -m 644 icons/guefi-$$i.png \
		$(DESTDIR)/usr/share/icons/hicolor/$${i}x$${i}/apps/guefi.png; \
	done

.PHONY: install-mo
install-mo:
	for i in `ls po/*.po|sed "s/po\/\(.*\)\.po/\1/"`; do \
		install -d -m 755 $(DESTDIR)/usr/share/locale/$$i/LC_MESSAGES; \
		install -m 644 po/$$i.mo $(DESTDIR)/usr/share/locale/$$i/LC_MESSAGES/guefi.mo; \
	done

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)/usr/sbin/guefi
	rm -f $(DESTDIR)/usr/bin/guefi-pkexec
	rm -f $(DESTDIR)/usr/share/polkit-1/actions/org.salixos.guefi.policy
	rm -f $(DESTDIR)/usr/share/applications/guefi.desktop
	rm -f $(DESTDIR)/usr/share/guefi/guefi.ui
	rm -f $(DESTDIR)/usr/share/icons/hicolor/*/apps/guefi.png
	rm -f $(DESTDIR)/usr/share/icons/hicolor/scalable/apps/guefi.svg
	rm -f $(DESTDIR)/usr/share/locale/*/LC_MESSAGES/guefi.mo

.PHONY: tx-pull
tx-pull:
	tx pull -a
	make fix-charset
	make delete-empty-po

.PHONY: tx-pull-f
tx-pull-f:
	tx pull -a -f
	make fix-charset
	make delete-empty-po

.PHONY: fix-charset
fix-charset:
	sed -i "s/charset=CHARSET/charset=UTF-8/" po/*.po

.PHONY: delete-empty-po
delete-empty-po:
	@for i in `ls po/*.po`; do \
		msgfmt --statistics $$i 2>&1 | grep "^0 translated" > /dev/null \
			&& rm $$i || true; \
	done
	@rm -f messages.mo

.PHONY: stat
stat:
	@for i in `ls po/*.po`; do \
		echo "Statistics for $$i:"; \
		msgfmt --statistics $$i 2>&1; \
		echo; \
	done
	@rm -f messages.mo

