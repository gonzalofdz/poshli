#!/bin/sh
#
# POSHLI - Unit tests for fs.sh
#

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
. "$TEST_DIR/test_runner.sh"

if [ -n "$POSHLI_TEST_BUNDLE" ]; then
	. "$TEST_DIR/../poshli.sh"
else
	. "$TEST_DIR/../src/fs.sh"
fi

printf '\n--- Running fs.sh tests ---\n'

# Argument count validation (returns 2 if no argument)
is_file; assert_status 2 $? "is_file requires argument (status 2)"
is_dir; assert_status 2 $? "is_dir requires argument (status 2)"
is_readable; assert_status 2 $? "is_readable requires argument (status 2)"
is_writable; assert_status 2 $? "is_writable requires argument (status 2)"
is_exec; assert_status 2 $? "is_exec requires argument (status 2)"
is_empty_file; assert_status 2 $? "is_empty_file requires argument (status 2)"

# Setup temporary test fixtures
TMP_FIXTURE_DIR="/tmp/poshli_test_fs_$$"
trap 'rm -rf "$TMP_FIXTURE_DIR"' EXIT INT TERM HUP
mkdir -p "$TMP_FIXTURE_DIR"

REG_FILE="$TMP_FIXTURE_DIR/regular.txt"
EMPTY_FILE="$TMP_FIXTURE_DIR/empty.txt"
SUB_DIR="$TMP_FIXTURE_DIR/subdir"
EXEC_FILE="$TMP_FIXTURE_DIR/exec.sh"
NO_EXEC_FILE="$TMP_FIXTURE_DIR/no_exec.txt"
RO_FILE="$TMP_FIXTURE_DIR/readonly.txt"
NON_EXISTENT="$TMP_FIXTURE_DIR/non_existent_file_$$"

printf 'hello world\n' > "$REG_FILE"
: > "$EMPTY_FILE"
mkdir -p "$SUB_DIR"
printf '#!/bin/sh\nexit 0\n' > "$EXEC_FILE"
chmod 755 "$EXEC_FILE"
printf 'not exec\n' > "$NO_EXEC_FILE"
chmod 644 "$NO_EXEC_FILE"
printf 'read only\n' > "$RO_FILE"
chmod 444 "$RO_FILE"

# is_file
is_file "$REG_FILE"; assert_true $? "is_file: regular file"
is_file "$EMPTY_FILE"; assert_true $? "is_file: empty file is regular"
is_file "$SUB_DIR"; assert_false $? "is_file: directory is not regular file"
is_file "$NON_EXISTENT"; assert_false $? "is_file: non-existent path"

# is_dir
is_dir "$SUB_DIR"; assert_true $? "is_dir: directory"
is_dir "$REG_FILE"; assert_false $? "is_dir: file is not directory"
is_dir "$NON_EXISTENT"; assert_false $? "is_dir: non-existent path"

# is_readable
is_readable "$REG_FILE"; assert_true $? "is_readable: regular file"
is_readable "$SUB_DIR"; assert_true $? "is_readable: directory"
is_readable "$NON_EXISTENT"; assert_false $? "is_readable: non-existent path"

# is_writable
is_writable "$REG_FILE"; assert_true $? "is_writable: regular file"
is_writable "$SUB_DIR"; assert_true $? "is_writable: directory"
is_writable "$NON_EXISTENT"; assert_false $? "is_writable: non-existent path"
if [ "$(id -u 2>/dev/null)" = "0" ]; then
	printf '  [SKIP] is_writable: read-only file (mode 444) [skipped when run as root]\n'
else
	is_writable "$RO_FILE"; assert_false $? "is_writable: read-only file (mode 444)"
fi

# is_exec
is_exec "$EXEC_FILE"; assert_true $? "is_exec: executable file (mode 755)"
is_exec "$NO_EXEC_FILE"; assert_false $? "is_exec: non-executable file (mode 644)"
is_exec "$NON_EXISTENT"; assert_false $? "is_exec: non-existent path"

# is_empty_file
is_empty_file "$EMPTY_FILE"; assert_true $? "is_empty_file: 0-byte file"
is_empty_file "$REG_FILE"; assert_false $? "is_empty_file: file with content"
is_empty_file "$SUB_DIR"; assert_false $? "is_empty_file: directory is not empty file"
is_empty_file "$NON_EXISTENT"; assert_false $? "is_empty_file: non-existent path"

# Cleanup fixtures
rm -rf "$TMP_FIXTURE_DIR"

test_summary
