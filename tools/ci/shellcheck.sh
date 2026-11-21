#!/bin/sh
#
#  POSHLI - ShellCheck CI gate
#
#  SPDX-License-Identifier: LGPL-3.0-only
#  Copyright (C) 2017-2018, 2026 Luis Gonzalo Fernández-Díez <humanogonzalo@gmail.com>
#  This file is part of POSHLI. See LICENSE for the full license text.
#
#  Runs "shellcheck -s sh --format=gcc" over the sources, the tests and the
#  generated bundle, and compares the sorted output with the checked-in
#  baseline. Any new finding, any fixed finding, or any change in the
#  baseline makes the comparison fail: the baseline must be updated
#  explicitly.
#
#  The baseline is specific to the ShellCheck version pinned in
#  .github/workflows/tests.yml (0.9.0). After an intentional upgrade, check
#  that the options used here still work and regenerate the baseline:
#
#	tools/ci/shellcheck.sh --update
#
#  Review the diff of tools/ci/shellcheck-baseline.txt before committing it.
#

set -u

repo_root=$(
	unset CDPATH
	cd "$(dirname "$0")/../.." && pwd
) || exit 1
cd "$repo_root" || exit 1

if ! command -v shellcheck >/dev/null 2>&1; then
	printf 'shellcheck is not installed\n' >&2
	exit 1
fi

update=0
if [ "${1:-}" = "--update" ]; then
	update=1
fi

tmpdir=${TMPDIR:-/tmp}/poshli-shellcheck.$$
trap 'rm -rf "$tmpdir"' 0 1 2 15
mkdir "$tmpdir" || exit 1

raw=$tmpdir/raw
sorted=$tmpdir/sorted
baseline=tools/ci/shellcheck-baseline.txt

# The positional parameters carry the file list, so no word-splitting
# suppression is needed.
set -- poshli.sh src/*.sh tests/*.sh

shellcheck -s sh --format=gcc "$@" > "$raw" 2> "$tmpdir/err"
status=$?

# 0: no findings; 1: findings (the baseline decides whether they are
# accepted); anything else is a ShellCheck usage or file error.
if [ "$status" -gt 1 ]; then
	printf 'ShellCheck could not run correctly (status %s).\n' "$status" >&2
	cat "$tmpdir/err" >&2
	exit 1
fi

LC_ALL=C sort "$raw" > "$sorted"

if [ "$update" -eq 1 ]; then
	cp "$sorted" "$baseline"
	printf 'Updated %s\n' "$baseline"
	exit 0
fi

if [ ! -f "$baseline" ]; then
	printf 'Missing baseline: %s\n' "$baseline" >&2
	printf 'Create it with: tools/ci/shellcheck.sh --update\n' >&2
	exit 1
fi

if diff -u "$baseline" "$sorted"; then
	printf 'ShellCheck findings match the baseline.\n'
	exit 0
fi

printf '\nShellCheck findings differ from the baseline.\n' >&2
printf 'Fix the finding, or update the baseline for an intentional change:\n' >&2
printf '  tools/ci/shellcheck.sh --update\n' >&2
exit 1
