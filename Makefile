#
# POSHLI Makefile
#

PREFIX ?= $(HOME)/.local
DESTDIR ?=
POSHLI_TEST_SHELL ?= /bin/sh
LIBDIR = $(DESTDIR)$(PREFIX)/lib/poshli

.PHONY: all bundle test test-bundle install uninstall clean

all: bundle

bundle: poshli.sh

poshli.sh: src/core.sh src/num.sh src/fs.sh src/str.sh
	@printf 'Generating poshli.sh bundle...\n'
	@rm -f "$@.tmp"
	@printf '#!/bin/sh\n#\n# POSHLI - POSIX Shell Library (Single File Bundle)\n# GNU Lesser General Public License v3.0\n#\n\n' > "$@.tmp"
	@printf '[ -n "$${_POSHLI_LOADED+x}" ] && return 0\n_POSHLI_LOADED=1\n\n' >> "$@.tmp"
	@cat src/core.sh src/num.sh src/fs.sh src/str.sh >> "$@.tmp"
	@chmod 644 "$@.tmp"
	@mv -f "$@.tmp" "$@"
	@printf 'poshli.sh generated successfully.\n'

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
