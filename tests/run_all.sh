#!/bin/sh
#
# POSHLI - Master test runner executing all test suites
#

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
SH_CMD="${POSHLI_TEST_SHELL:-/bin/sh}"
export POSHLI_TEST_SHELL="$SH_CMD"

run_suite() {
	_suite_file="$1"
	# Parse interpreter command into positional arguments (supports e.g. "busybox sh", "bash --posix")
	# shellcheck disable=SC2086
	set -- $SH_CMD "$_suite_file"
	"$@"
}

printf '========================================\n'
printf '        POSHLI TEST SUITE EXECUTION     \n'
printf '========================================\n'

STATUS=0

run_suite "$TEST_DIR/test_num.sh" || STATUS=1
run_suite "$TEST_DIR/test_fs.sh" || STATUS=1
run_suite "$TEST_DIR/test_str.sh" || STATUS=1
run_suite "$TEST_DIR/test_guards.sh" || STATUS=1

printf '\n========================================\n'
if [ "$STATUS" -eq 0 ]; then
	printf '       ALL TEST SUITES SUCCEEDED        \n'
else
	printf '       ONE OR MORE TEST SUITES FAILED   \n'
fi
printf '========================================\n'

exit "$STATUS"
