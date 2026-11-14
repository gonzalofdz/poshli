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
fs_is_file; assert_status 2 $? "fs_is_file requires argument (status 2)"
fs_is_dir; assert_status 2 $? "fs_is_dir requires argument (status 2)"
fs_is_readable; assert_status 2 $? "fs_is_readable requires argument (status 2)"
fs_is_writable; assert_status 2 $? "fs_is_writable requires argument (status 2)"
fs_is_exec; assert_status 2 $? "fs_is_exec requires argument (status 2)"
fs_is_empty_file; assert_status 2 $? "fs_is_empty_file requires argument (status 2)"
fs_is_plain_text; assert_status 2 $? "fs_is_plain_text requires argument (status 2)"

# Setup temporary test fixtures
TMP_FIXTURE_DIR="/tmp/poshli_test_fs_$$"
trap 'rm -rf "$TMP_FIXTURE_DIR"' 0 INT TERM HUP
mkdir -p "$TMP_FIXTURE_DIR"

REG_FILE="$TMP_FIXTURE_DIR/regular.txt"
EMPTY_FILE="$TMP_FIXTURE_DIR/empty.txt"
SUB_DIR="$TMP_FIXTURE_DIR/subdir"
EXEC_FILE="$TMP_FIXTURE_DIR/exec.sh"
NO_EXEC_FILE="$TMP_FIXTURE_DIR/no_exec.txt"
RO_FILE="$TMP_FIXTURE_DIR/readonly.txt"
BIN_FILE="$TMP_FIXTURE_DIR/binary.bin"
TRICK_FILE="$TMP_FIXTURE_DIR/text_binary.bin"
UTF8_FILE="$TMP_FIXTURE_DIR/utf8.txt"
UNREADABLE_FILE="$TMP_FIXTURE_DIR/unreadable.txt"
NON_EXISTENT="$TMP_FIXTURE_DIR/non_existent_file_$$"
HYPHEN_FILE="$TMP_FIXTURE_DIR/-n"
LINK_FILE="$TMP_FIXTURE_DIR/link.txt"

printf 'hello world\n' > "$REG_FILE"
: > "$EMPTY_FILE"
mkdir -p "$SUB_DIR"
printf '#!/bin/sh\nexit 0\n' > "$EXEC_FILE"
chmod 755 "$EXEC_FILE"
printf 'not exec\n' > "$NO_EXEC_FILE"
chmod 644 "$NO_EXEC_FILE"
printf 'read only\n' > "$RO_FILE"
chmod 444 "$RO_FILE"
printf 'a\000b\001c' > "$BIN_FILE"
printf 'x\000y' > "$TRICK_FILE"
printf 'España\n' > "$UTF8_FILE"
printf 'secret\n' > "$UNREADABLE_FILE"
chmod 000 "$UNREADABLE_FILE"
printf 'hello world\n' > "$HYPHEN_FILE"
ln -s "$REG_FILE" "$LINK_FILE"

# fs_is_file
fs_is_file "$REG_FILE"; assert_true $? "fs_is_file: regular file"
fs_is_file "$EMPTY_FILE"; assert_true $? "fs_is_file: empty file is regular"
fs_is_file "$SUB_DIR"; assert_false $? "fs_is_file: directory is not regular file"
fs_is_file "$NON_EXISTENT"; assert_false $? "fs_is_file: non-existent path"

# fs_is_dir
fs_is_dir "$SUB_DIR"; assert_true $? "fs_is_dir: directory"
fs_is_dir "$REG_FILE"; assert_false $? "fs_is_dir: file is not directory"
fs_is_dir "$NON_EXISTENT"; assert_false $? "fs_is_dir: non-existent path"

# fs_is_readable
fs_is_readable "$REG_FILE"; assert_true $? "fs_is_readable: regular file"
fs_is_readable "$SUB_DIR"; assert_true $? "fs_is_readable: directory"
fs_is_readable "$NON_EXISTENT"; assert_false $? "fs_is_readable: non-existent path"

# fs_is_writable
fs_is_writable "$REG_FILE"; assert_true $? "fs_is_writable: regular file"
fs_is_writable "$SUB_DIR"; assert_true $? "fs_is_writable: directory"
fs_is_writable "$NON_EXISTENT"; assert_false $? "fs_is_writable: non-existent path"
if [ "$(id -u 2>/dev/null)" = "0" ]; then
	printf '  [SKIP] fs_is_writable: read-only file (mode 444) [skipped when run as root]\n'
else
	fs_is_writable "$RO_FILE"; assert_false $? "fs_is_writable: read-only file (mode 444)"
fi

# fs_is_exec
fs_is_exec "$EXEC_FILE"; assert_true $? "fs_is_exec: executable file (mode 755)"
fs_is_exec "$NO_EXEC_FILE"; assert_false $? "fs_is_exec: non-executable file (mode 644)"
fs_is_exec "$NON_EXISTENT"; assert_false $? "fs_is_exec: non-existent path"

# fs_is_empty_file
fs_is_empty_file "$EMPTY_FILE"; assert_true $? "fs_is_empty_file: 0-byte file"
fs_is_empty_file "$REG_FILE"; assert_false $? "fs_is_empty_file: file with content"
fs_is_empty_file "$SUB_DIR"; assert_false $? "fs_is_empty_file: directory is not empty file"
fs_is_empty_file "$NON_EXISTENT"; assert_false $? "fs_is_empty_file: non-existent path"

# fs_is_plain_text
fs_is_plain_text "$REG_FILE"; assert_true $? "fs_is_plain_text: ASCII text file"
fs_is_plain_text "$UTF8_FILE"; assert_true $? "fs_is_plain_text: UTF-8 text file"
fs_is_plain_text "$EXEC_FILE"; assert_true $? "fs_is_plain_text: executable script"
fs_is_plain_text "$BIN_FILE"; assert_false $? "fs_is_plain_text: binary file"
fs_is_plain_text "$TRICK_FILE"; assert_false $? "fs_is_plain_text: binary file named 'text_*' is not fooled"
fs_is_plain_text "$EMPTY_FILE"; assert_false $? "fs_is_plain_text: empty file"
fs_is_plain_text "$SUB_DIR"; assert_false $? "fs_is_plain_text: directory"
fs_is_plain_text "$NON_EXISTENT"; assert_status 1 $? "fs_is_plain_text: non-existent path (status 1)"
if [ "$(id -u 2>/dev/null)" = "0" ]; then
	printf '  [SKIP] fs_is_plain_text: unreadable file (mode 000) [skipped when run as root]\n'
else
	fs_is_plain_text "$UNREADABLE_FILE"; assert_status 1 $? "fs_is_plain_text: unreadable file (status 1)"
fi
( cd "$TMP_FIXTURE_DIR" && fs_is_plain_text -n ); assert_true $? "fs_is_plain_text: leading hyphen filename"
fs_is_plain_text "$LINK_FILE"; assert_true $? "fs_is_plain_text: symlink to text file"

# Cleanup fixtures
rm -rf "$TMP_FIXTURE_DIR"

test_summary
