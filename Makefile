#
# POSHLI Makefile
#

PREFIX ?= $(HOME)/.local
DESTDIR ?=
POSHLI_TEST_SHELL ?= /bin/sh
BUNDLE_OUTPUT ?= poshli.sh
BUNDLE_SOURCES = src/core.sh src/num.sh src/fs.sh src/str.sh src/encoding.sh
LIBDIR = $(DESTDIR)$(PREFIX)/lib/poshli

.PHONY: all bundle check-bundle test test-bundle install uninstall clean

all: bundle

bundle: $(BUNDLE_OUTPUT)

$(BUNDLE_OUTPUT): $(BUNDLE_SOURCES)
	@printf 'Generating %s bundle...\n' "$@"
	@rm -f "$@.tmp"
	@printf '#!/bin/sh\n#\n# POSHLI - POSIX Shell Library (Single File Bundle)\n# GNU Lesser General Public License v3.0\n#\n\n' > "$@.tmp"
	@printf '[ -n "$${_POSHLI_LOADED+x}" ] && return 0\n_POSHLI_LOADED=1\n\n' >> "$@.tmp"
	@cat $(BUNDLE_SOURCES) >> "$@.tmp"
	@chmod 644 "$@.tmp"
	@mv -f "$@.tmp" "$@"
	@printf '%s generated successfully.\n' "$@"

check-bundle:
	@tmp="poshli.sh.check.$$$$"; \
	trap 'rm -f "$$tmp"' 0 1 2 15; \
	rm -f "$$tmp"; \
	$(MAKE) --no-print-directory bundle BUNDLE_OUTPUT="$$tmp" >/dev/null || exit 1; \
	if cmp -s "$$tmp" poshli.sh; then \
		printf 'poshli.sh is synchronized with src/.\n'; \
	else \
		printf 'ERROR: poshli.sh is out of date with src/. Run "make bundle".\n' >&2; \
		exit 1; \
	fi

test: bundle
	@POSHLI_TEST_SHELL="$(POSHLI_TEST_SHELL)" $(POSHLI_TEST_SHELL) ./tests/run_all.sh

test-bundle: bundle
	@POSHLI_TEST_BUNDLE=1 POSHLI_TEST_SHELL="$(POSHLI_TEST_SHELL)" $(POSHLI_TEST_SHELL) ./tests/run_all.sh

install: bundle
	@printf 'Installing poshli.sh to %s...\n' "$(LIBDIR)"
	@mkdir -p "$(LIBDIR)"
	@cp poshli.sh "$(LIBDIR)/poshli.sh"
	@chmod 644 "$(LIBDIR)/poshli.sh"
	@printf 'Successfully installed poshli.sh to %s/poshli.sh\n' "$(LIBDIR)"

uninstall:
	@printf 'Removing %s/poshli.sh...\n' "$(LIBDIR)"
	@rm -f "$(LIBDIR)/poshli.sh"
	@rmdir "$(LIBDIR)" 2>/dev/null || true
	@printf 'Successfully uninstalled poshli.\n'

clean:
	@rm -f poshli.sh.tmp
