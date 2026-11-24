#!/bin/sh
#
# POSHLI - Master test runner executing all test suites
#
# SPDX-License-Identifier: LGPL-3.0-only
# Copyright (C) 2017-2018, 2026 Luis Gonzalo Fernández-Díez <humanogonzalo@gmail.com>
# This file is part of POSHLI. See LICENSE for the full license text.
#

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
SH_CMD="${POSHLI_TEST_SHELL:-/bin/sh}"
export POSHLI_TEST_SHELL="$SH_CMD"

# One suite runs at a time. Its output is captured so the final summary line
# can be verified: a suite that aborts before test_summary (for example on a
# shell that exits on an unexpected condition) must be reported as a hard
# failure with an explicit diagnostic, never look like a skip or a clean run.
# Capturing costs nothing at this suite size and keeps the check portable
# (POSIX pipelines report only the last command's status).
SUITE_LOG="${TMPDIR:-/tmp}/poshli_suite_$$.log"
trap 'rm -f "$SUITE_LOG"' 0 1 2 3 14 15

run_suite() {
	_suite_file="$1"
	_suite_name=${_suite_file##*/}
	# Parse interpreter command into positional arguments (supports e.g. "busybox sh", "bash --posix")
	# shellcheck disable=SC2086
	set -- $SH_CMD "$_suite_file"
	"$@" > "$SUITE_LOG" 2>&1
	_suite_status=$?
	cat "$SUITE_LOG"
	if ! grep -q 'Tests run:' "$SUITE_LOG"; then
		printf 'SUITE ABORTED BEFORE SUMMARY: %s (exit %d)\n' \
			"$_suite_name" "$_suite_status"
		rm -f "$SUITE_LOG"
		unset _suite_file _suite_name
		return 1
	fi
	rm -f "$SUITE_LOG"
	unset _suite_file _suite_name
	return "$_suite_status"
}

printf '========================================\n'
printf '        POSHLI TEST SUITE EXECUTION     \n'
printf '========================================\n'

STATUS=0

run_suite "$TEST_DIR/test_num.sh" || STATUS=1
run_suite "$TEST_DIR/test_fs.sh" || STATUS=1
run_suite "$TEST_DIR/test_str.sh" || STATUS=1
run_suite "$TEST_DIR/test_encoding.sh" || STATUS=1
run_suite "$TEST_DIR/test_guards.sh" || STATUS=1

printf '\n========================================\n'
if [ "$STATUS" -eq 0 ]; then
	printf '       ALL TEST SUITES SUCCEEDED        \n'
else
	printf '       ONE OR MORE TEST SUITES FAILED   \n'
fi
printf '========================================\n'

exit "$STATUS"
