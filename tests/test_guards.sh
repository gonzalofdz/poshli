#!/bin/sh
#
# POSHLI - Unit tests for load guards and bundle integration
# GNU Lesser General Public License v3.0
#

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_DIR=$(cd "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_runner.sh"

SH_BIN="${POSHLI_TEST_SHELL:-/bin/sh}"

printf '\n--- Running test_guards.sh (using %s) ---\n' "$SH_BIN"

# Helper to run a command in an isolated subshell
run_guard_test() {
	# shellcheck disable=SC2086
	set -- $SH_BIN -c "cd '$REPO_DIR' && $1"
	"$@"
}

# ==============================================================================
# Scenario 1: Load individual modules
# ==============================================================================
run_guard_test '
	. ./src/core.sh
	[ "$POSHLI_VERSION" = "1.0.0" ] && [ "$_POSHLI_CORE_LOADED" = "1" ] && ! command -v is_integer >/dev/null 2>&1
'
assert_true $? "Scenario 1: core.sh sets version and does not load other modules"

run_guard_test '
	. ./src/num.sh
	command -v is_integer >/dev/null 2>&1 && [ "$_POSHLI_NUM_LOADED" = "1" ] && ! command -v is_file >/dev/null 2>&1
'
assert_true $? "Scenario 1: num.sh defines is_integer and does not load fs"

run_guard_test '
	. ./src/fs.sh
	command -v is_file >/dev/null 2>&1 && [ "$_POSHLI_FS_LOADED" = "1" ] && ! command -v trim >/dev/null 2>&1
'
assert_true $? "Scenario 1: fs.sh defines is_file and does not load str"

run_guard_test '
	. ./src/str.sh
	command -v trim >/dev/null 2>&1 && [ "$_POSHLI_STR_LOADED" = "1" ] && ! command -v is_integer >/dev/null 2>&1
'
assert_true $? "Scenario 1: str.sh defines trim and does not load num"

run_guard_test '
	. ./src/encoding.sh
	command -v base64_enc >/dev/null 2>&1 && [ "$_POSHLI_ENCODING_LOADED" = "1" ] && ! command -v trim >/dev/null 2>&1
'
assert_true $? "Scenario 1: encoding.sh defines base64_enc and does not load str"

# ==============================================================================
# Scenario 2: Load bundle poshli.sh
# ==============================================================================
run_guard_test '
	. ./poshli.sh
	[ "$POSHLI_VERSION" = "1.0.0" ] &&
	[ "$_POSHLI_LOADED" = "1" ] &&
	command -v is_integer >/dev/null 2>&1 &&
	command -v is_file >/dev/null 2>&1 &&
	command -v trim >/dev/null 2>&1 &&
	command -v base64_enc >/dev/null 2>&1
'
assert_true $? "Scenario 2: poshli.sh loads all modules and defines all functions"

# ==============================================================================
# Scenario 3: Load module first, then bundle
# ==============================================================================
run_guard_test '
	. ./src/core.sh
	. ./poshli.sh
	[ "$POSHLI_VERSION" = "1.0.0" ] &&
	command -v is_integer >/dev/null 2>&1 &&
	command -v is_file >/dev/null 2>&1 &&
	command -v trim >/dev/null 2>&1
'
assert_true $? "Scenario 3: core.sh then poshli.sh does not abort and loads all functions"

run_guard_test '
	. ./src/num.sh
	. ./poshli.sh
	command -v is_integer >/dev/null 2>&1 &&
	command -v is_file >/dev/null 2>&1 &&
	command -v trim >/dev/null 2>&1
'
assert_true $? "Scenario 3: num.sh then poshli.sh loads all functions"

run_guard_test '
	. ./src/fs.sh
	. ./poshli.sh
	command -v is_integer >/dev/null 2>&1 &&
	command -v is_file >/dev/null 2>&1 &&
	command -v trim >/dev/null 2>&1
'
assert_true $? "Scenario 3: fs.sh then poshli.sh loads all functions"

run_guard_test '
	. ./src/str.sh
	. ./poshli.sh
	command -v is_integer >/dev/null 2>&1 &&
	command -v is_file >/dev/null 2>&1 &&
	command -v trim >/dev/null 2>&1
'
assert_true $? "Scenario 3: str.sh then poshli.sh loads all functions"

run_guard_test '
	. ./src/core.sh
	. ./src/num.sh
	. ./poshli.sh
	[ "$POSHLI_VERSION" = "1.0.0" ] &&
	command -v is_integer >/dev/null 2>&1 &&
	command -v is_file >/dev/null 2>&1 &&
	command -v trim >/dev/null 2>&1
'
assert_true $? "Scenario 3: multiple modules (core + num) then poshli.sh loads all functions"

# ==============================================================================
# Scenario 4: Load bundle first, then module
# ==============================================================================
run_guard_test '
	. ./poshli.sh
	. ./src/core.sh
	[ "$POSHLI_VERSION" = "1.0.0" ] && command -v is_integer >/dev/null 2>&1
'
assert_true $? "Scenario 4: poshli.sh then core.sh is safe and keeps all functions"

run_guard_test '
	. ./poshli.sh
	. ./src/num.sh
	command -v is_integer >/dev/null 2>&1 && command -v is_file >/dev/null 2>&1
'
assert_true $? "Scenario 4: poshli.sh then num.sh is safe and keeps all functions"

run_guard_test '
	. ./poshli.sh
	. ./src/fs.sh
	command -v is_file >/dev/null 2>&1 && command -v trim >/dev/null 2>&1
'
assert_true $? "Scenario 4: poshli.sh then fs.sh is safe and keeps all functions"

run_guard_test '
	. ./poshli.sh
	. ./src/str.sh
	command -v trim >/dev/null 2>&1 && command -v is_integer >/dev/null 2>&1
'
assert_true $? "Scenario 4: poshli.sh then str.sh is safe and keeps all functions"

# ==============================================================================
# Scenario 5: Repeated loading in any combination
# ==============================================================================
run_guard_test '
	. ./src/core.sh
	. ./src/core.sh
	[ "$POSHLI_VERSION" = "1.0.0" ]
'
assert_true $? "Scenario 5: core.sh loaded repeatedly is idempotent"

run_guard_test '
	. ./src/num.sh
	. ./src/num.sh
	command -v is_integer >/dev/null 2>&1
'
assert_true $? "Scenario 5: num.sh loaded repeatedly is idempotent"

run_guard_test '
	. ./src/fs.sh
	. ./src/fs.sh
	command -v is_file >/dev/null 2>&1
'
assert_true $? "Scenario 5: fs.sh loaded repeatedly is idempotent"

run_guard_test '
	. ./src/str.sh
	. ./src/str.sh
	command -v trim >/dev/null 2>&1
'
assert_true $? "Scenario 5: str.sh loaded repeatedly is idempotent"

run_guard_test '
	. ./poshli.sh
	. ./poshli.sh
	[ "$POSHLI_VERSION" = "1.0.0" ] && command -v is_integer >/dev/null 2>&1
'
assert_true $? "Scenario 5: poshli.sh loaded repeatedly is idempotent"

run_guard_test '
	. ./src/core.sh
	. ./src/core.sh
	. ./src/num.sh
	. ./poshli.sh
	. ./poshli.sh
	. ./src/fs.sh
	. ./src/str.sh
	. ./poshli.sh
	[ "$POSHLI_VERSION" = "1.0.0" ] &&
	command -v is_integer >/dev/null 2>&1 &&
	command -v is_file >/dev/null 2>&1 &&
	command -v trim >/dev/null 2>&1
'
assert_true $? "Scenario 5: complex arbitrary loading sequence succeeds"

test_summary
