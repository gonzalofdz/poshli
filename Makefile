#
# POSHLI Makefile
#
# SPDX-License-Identifier: LGPL-3.0-only
# Copyright (C) 2017-2018, 2026 Luis Gonzalo Fernández-Díez <humanogonzalo@gmail.com>
# This file is part of POSHLI. See LICENSE for the full license text.
#

PREFIX ?= $(HOME)/.local
DESTDIR ?=
POSHLI_TEST_SHELL ?= /bin/sh
BUNDLE_OUTPUT ?= poshli.sh
BUNDLE_SOURCES = src/core.sh src/num.sh src/fs.sh src/case_data.sh src/str.sh src/encoding.sh
LIBDIR = $(DESTDIR)$(PREFIX)/lib/poshli

.PHONY: all bundle check-bundle check-bashisms case-data test test-bundle install uninstall clean

all: bundle

bundle: $(BUNDLE_OUTPUT)

$(BUNDLE_OUTPUT): $(BUNDLE_SOURCES) Makefile
	@printf 'Generating %s bundle...\n' "$@"
	@rm -f "$@.tmp"
	@printf '#!/bin/sh\n#\n# POSHLI\n#\n# SPDX-License-Identifier: LGPL-3.0-only AND Unicode-DFS-2016\n# Copyright (C) 2017-2018, 2026 Luis Gonzalo Fernández-Díez <humanogonzalo@gmail.com>\n# This file is part of POSHLI. See LICENSE for the full license text.\n#\n# This bundle contains Unicode case mapping data derived from the Unicode\n# Character Database, Unicode 15.0.0. Unicode data copyright (C) 1991-2022\n# Unicode, Inc.; licensed under the Unicode License Agreement - Data Files and\n# Software (2016) (SPDX: Unicode-DFS-2016)\n# <https://spdx.org/licenses/Unicode-DFS-2016.html>.\n#\n' > "$@.tmp"
	@printf '[ -n "$${_POSHLI_LOADED+x}" ] && return 0\n_POSHLI_LOADED=1\n' >> "$@.tmp"
	@awk '/^[[:space:]]*#/ { next } { print }' $(BUNDLE_SOURCES) >> "$@.tmp"
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

check-bashisms:
	@if command -v checkbashisms >/dev/null 2>&1; then \
		checkbashisms -f -p src/*.sh poshli.sh tests/*.sh; \
	else \
		printf 'checkbashisms is not installed (devscripts package); skipping check.\n'; \
	fi

case-data:
	@printf 'Generating src/case_data.sh...\n'
	@python3 tools/gen_case.py > src/case_data.sh.tmp || { rm -f src/case_data.sh.tmp; exit 1; }
	@mv -f src/case_data.sh.tmp src/case_data.sh
	@printf 'src/case_data.sh generated successfully.\n'

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
