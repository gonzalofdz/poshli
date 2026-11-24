#!/bin/sh
#
# POSHLI - Unit tests for fs.sh
#
# SPDX-License-Identifier: LGPL-3.0-only
# Copyright (C) 2017-2018, 2026 Luis Gonzalo Fernández-Díez <humanogonzalo@gmail.com>
# This file is part of POSHLI. See LICENSE for the full license text.
#

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
. "$TEST_DIR/test_runner.sh"

if [ -n "$POSHLI_TEST_BUNDLE" ]; then
	. "$TEST_DIR/../poshli.sh"
else
	. "$TEST_DIR/../src/fs.sh"
fi

printf '\n--- Running fs.sh tests ---\n'

# Argument count validation: predicates treat a missing argument as false (status 1);
# fs_is_plain_text is operational and reports a missing argument as invalid usage (status 2).
fs_is_file; assert_status 1 $? "fs_is_file requires argument (status 1)"
fs_is_dir; assert_status 1 $? "fs_is_dir requires argument (status 1)"
fs_is_readable; assert_status 1 $? "fs_is_readable requires argument (status 1)"
fs_is_writable; assert_status 1 $? "fs_is_writable requires argument (status 1)"
fs_is_exec; assert_status 1 $? "fs_is_exec requires argument (status 1)"
fs_is_empty_file; assert_status 1 $? "fs_is_empty_file requires argument (status 1)"
fs_is_plain_text; assert_status 2 $? "fs_is_plain_text requires argument (status 2)"

# Setup temporary test fixtures. Use a private directory under /tmp and make
# sure it does not already exist (no mktemp on POSIX, so we loop on a PID-based
# name if a collision is found).
TMP_FIXTURE_DIR="/tmp/poshli_test_fs_$$"
while [ -e "$TMP_FIXTURE_DIR" ]; do
	TMP_FIXTURE_DIR="${TMP_FIXTURE_DIR}_x"
done
mkdir -p "$TMP_FIXTURE_DIR" || {
	printf 'poshli test_fs: cannot create fixture directory %s\n' "$TMP_FIXTURE_DIR" >&2
	exit 1
}
trap 'rm -rf "$TMP_FIXTURE_DIR"; _test_cleanup_shims' 0 INT TERM HUP

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
UTF8UNI_FILE="$TMP_FIXTURE_DIR/utf8uni.txt"
TABCRLF_FILE="$TMP_FIXTURE_DIR/tabcrlf.txt"
LATIN1_FILE="$TMP_FIXTURE_DIR/latin1.txt"
BADUTF8_FILE="$TMP_FIXTURE_DIR/badutf8.txt"
STRAYUTF8_FILE="$TMP_FIXTURE_DIR/strayutf8.txt"
CTRL01_FILE="$TMP_FIXTURE_DIR/ctrl01.txt"
ESC_FILE="$TMP_FIXTURE_DIR/escape.txt"
VTFF_FILE="$TMP_FIXTURE_DIR/vtff.txt"
DEL_FILE="$TMP_FIXTURE_DIR/del.txt"
C1_FILE="$TMP_FIXTURE_DIR/c1ctrl.txt"
UTF16_FILE="$TMP_FIXTURE_DIR/utf16.txt"
UTF32_FILE="$TMP_FIXTURE_DIR/utf32.txt"
PNG_FILE="$TMP_FIXTURE_DIR/image.png"
SPACE_FILE="$TMP_FIXTURE_DIR/with spaces.txt"
GLOB_FILE="$TMP_FIXTURE_DIR/star*name.txt"
FIFO_FILE="$TMP_FIXTURE_DIR/fifo"
BIN_LINK="$TMP_FIXTURE_DIR/bin_link"
BROKEN_LINK="$TMP_FIXTURE_DIR/broken_link"
B4096_FILE="$TMP_FIXTURE_DIR/size4096.txt"
B4095NUL_FILE="$TMP_FIXTURE_DIR/nul4095.bin"
BPAST_FILE="$TMP_FIXTURE_DIR/binpast.bin"
BCUT_FILE="$TMP_FIXTURE_DIR/cut4096.txt"

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
printf 'caf\303\251 \344\270\255\346\226\207 \360\237\230\200\n' > "$UTF8UNI_FILE"
printf 'col1\tcol2\r\nline2\tvalue\n' > "$TABCRLF_FILE"
printf 'caf\351\n' > "$LATIN1_FILE"
printf 'bad\303\n' > "$BADUTF8_FILE"
printf 'a\200b\n' > "$STRAYUTF8_FILE"
printf 'a\001b\n' > "$CTRL01_FILE"
printf 'esc\033[31mred\033[0m\n' > "$ESC_FILE"
printf 'vt\013ff\014\n' > "$VTFF_FILE"
printf 'del\177x\n' > "$DEL_FILE"
printf 'x\302\233y\n' > "$C1_FILE"
printf 'a\000b\000c\000d\000' > "$UTF16_FILE"
printf 'a\000\000\000b\000\000\000' > "$UTF32_FILE"
printf '\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000' > "$PNG_FILE"
printf 'file with spaces\n' > "$SPACE_FILE"
printf 'glob name\n' > "$GLOB_FILE"
mkfifo "$FIFO_FILE"
ln -s "$BIN_FILE" "$BIN_LINK"
ln -s "$TMP_FIXTURE_DIR/no_such_target" "$BROKEN_LINK"
awk 'BEGIN { for (i = 0; i < 512; i++) printf "12345678" }' > "$B4096_FILE"
{ awk 'BEGIN { for (i = 0; i < 4095; i++) printf "a" }'; printf '\000'; } > "$B4095NUL_FILE"
{ awk 'BEGIN { for (i = 0; i < 4096; i++) printf "a" }'; printf '\000\001\002'; } > "$BPAST_FILE"
{ awk 'BEGIN { for (i = 0; i < 4095; i++) printf "a" }'; printf '\303\251'; } > "$BCUT_FILE"

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

# fs_is_plain_text: must be plain text
fs_is_plain_text "$REG_FILE"; assert_true $? "fs_is_plain_text: ASCII text file"
fs_is_plain_text "$UTF8_FILE"; assert_true $? "fs_is_plain_text: UTF-8 text file"
fs_is_plain_text "$UTF8UNI_FILE"; assert_true $? "fs_is_plain_text: valid UTF-8 with Unicode characters"
fs_is_plain_text "$EXEC_FILE"; assert_true $? "fs_is_plain_text: executable script"
fs_is_plain_text "$TABCRLF_FILE"; assert_true $? "fs_is_plain_text: text with TAB and CR/LF line endings"
fs_is_plain_text "$EMPTY_FILE"; assert_true $? "fs_is_plain_text: empty file is plain text"
fs_is_plain_text "$B4096_FILE"; assert_true $? "fs_is_plain_text: text of exactly 4096 bytes"
fs_is_plain_text "$BCUT_FILE"; assert_true $? "fs_is_plain_text: UTF-8 character cut by the 4096-byte limit is tolerated"
fs_is_plain_text "$BPAST_FILE"; assert_true $? "fs_is_plain_text: binary after the 4096-byte limit is not inspected (documented limitation)"
fs_is_plain_text "$SPACE_FILE"; assert_true $? "fs_is_plain_text: filename with spaces"
fs_is_plain_text "$GLOB_FILE"; assert_true $? "fs_is_plain_text: filename with glob characters"

# fs_is_plain_text: must not be plain text
fs_is_plain_text "$BIN_FILE"; assert_status 1 $? "fs_is_plain_text: binary file (NUL + control)"
fs_is_plain_text "$TRICK_FILE"; assert_status 1 $? "fs_is_plain_text: binary file named 'text_*' is not fooled"
fs_is_plain_text "$PNG_FILE"; assert_status 1 $? "fs_is_plain_text: typical binary (PNG header)"
fs_is_plain_text "$CTRL01_FILE"; assert_status 1 $? "fs_is_plain_text: forbidden C0 control (0x01)"
fs_is_plain_text "$ESC_FILE"; assert_status 1 $? "fs_is_plain_text: forbidden C0 control (ESC)"
fs_is_plain_text "$VTFF_FILE"; assert_status 1 $? "fs_is_plain_text: forbidden C0 controls (VT, FF)"
fs_is_plain_text "$DEL_FILE"; assert_status 1 $? "fs_is_plain_text: DEL control (0x7F) is not plain text"
fs_is_plain_text "$C1_FILE"; assert_status 1 $? "fs_is_plain_text: C1 control character (U+009B) is not plain text"
fs_is_plain_text "$LATIN1_FILE"; assert_status 1 $? "fs_is_plain_text: Latin-1 bytes are invalid UTF-8"
fs_is_plain_text "$BADUTF8_FILE"; assert_status 1 $? "fs_is_plain_text: truncated UTF-8 sequence"
fs_is_plain_text "$STRAYUTF8_FILE"; assert_status 1 $? "fs_is_plain_text: stray UTF-8 continuation byte"
fs_is_plain_text "$UTF16_FILE"; assert_status 1 $? "fs_is_plain_text: UTF-16 file (NUL bytes)"
fs_is_plain_text "$UTF32_FILE"; assert_status 1 $? "fs_is_plain_text: UTF-32 file (NUL bytes)"
fs_is_plain_text "$B4095NUL_FILE"; assert_status 1 $? "fs_is_plain_text: NUL inside the 4096-byte window"

# fs_is_plain_text: error cases
fs_is_plain_text "$SUB_DIR"; assert_status 1 $? "fs_is_plain_text: directory"
fs_is_plain_text "$FIFO_FILE"; assert_status 1 $? "fs_is_plain_text: fifo is not a regular file"
fs_is_plain_text "$BIN_LINK"; assert_status 1 $? "fs_is_plain_text: symlink to binary file"
fs_is_plain_text "$BROKEN_LINK"; assert_status 1 $? "fs_is_plain_text: broken symlink"
fs_is_plain_text "$NON_EXISTENT"; assert_status 1 $? "fs_is_plain_text: non-existent path (status 1)"
if [ "$(id -u 2>/dev/null)" = "0" ]; then
	printf '  [SKIP] fs_is_plain_text: unreadable file (mode 000) [skipped when run as root]\n'
else
	fs_is_plain_text "$UNREADABLE_FILE"; assert_status 1 $? "fs_is_plain_text: unreadable file (status 1)"
fi
( cd "$TMP_FIXTURE_DIR" && fs_is_plain_text -n ); assert_true $? "fs_is_plain_text: leading hyphen filename"
fs_is_plain_text "$LINK_FILE"; assert_true $? "fs_is_plain_text: symlink to text file"

# External awk shims avoid ksh93's function-in-pipeline status quirk.
# BusyBox resolves awk as an applet even when PATH is overridden, so
# test_runner.sh defines a function shim instead in that case.
_fs_shim_env() {
	_test_shim_awk "$1"
}

# Failure injection: od is replaced by a shell function inside a subshell;
# awk uses an external executable so its success status is portable.
(
	_test_shim_od fail
	_out=$(fs_is_plain_text "$REG_FILE" 2>/dev/null)
	_st=$?
	_err=$(fs_is_plain_text "$REG_FILE" 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ "$_err" = "poshli: fs_is_plain_text: could not read file" ]
)
assert_true $? "fs_is_plain_text: od failure returns 1 with read diagnostic and no stdout"

(
	_test_shim_od missing
	_out=$(fs_is_plain_text "$REG_FILE" 2>/dev/null)
	_st=$?
	_err=$(fs_is_plain_text "$REG_FILE" 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ "$_err" = "poshli: fs_is_plain_text: could not read file" ]
)
assert_true $? "fs_is_plain_text: missing od (127) returns 1 with read diagnostic and no stdout"

(
	_test_shim_od partial
	_out=$(fs_is_plain_text "$REG_FILE" 2>/dev/null)
	_st=$?
	_err=$(fs_is_plain_text "$REG_FILE" 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ "$_err" = "poshli: fs_is_plain_text: could not read file" ]
)
assert_true $? "fs_is_plain_text: failing od leaks no partial stdout and uses the read diagnostic"

(
	_test_shim_od empty
	_out=$(fs_is_plain_text "$REG_FILE" 2>/dev/null)
	_st=$?
	_err=$(fs_is_plain_text "$REG_FILE" 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ "$_err" = "poshli: fs_is_plain_text: could not read file" ]
)
assert_true $? "fs_is_plain_text: successful od with no output on a non-empty file fails closed"

(
	_test_shim_od empty
	_out=$(fs_is_plain_text "$EMPTY_FILE" 2>/dev/null)
	_st=$?
	_err=$(fs_is_plain_text "$EMPTY_FILE" 2>&1 >/dev/null)
	[ "$_st" -eq 0 ] && [ -z "$_out" ] && [ -z "$_err" ]
)
assert_true $? "fs_is_plain_text: successful od with no output on an empty file is plain text"

(
	_fs_shim_env fail
	_out=$(fs_is_plain_text "$REG_FILE" 2>/dev/null)
	_st=$?
	_err=$(fs_is_plain_text "$REG_FILE" 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ "$_err" = "poshli: fs_is_plain_text: could not validate content" ]
)
assert_true $? "fs_is_plain_text: awk failure returns 1 with validation diagnostic and no stdout"

(
	_fs_shim_env missing
	_out=$(fs_is_plain_text "$REG_FILE" 2>/dev/null)
	_st=$?
	_err=$(fs_is_plain_text "$REG_FILE" 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ "$_err" = "poshli: fs_is_plain_text: could not validate content" ]
)
assert_true $? "fs_is_plain_text: missing awk (127) returns 1 with validation diagnostic and no stdout"

(
	_fs_shim_env partial
	_out=$(fs_is_plain_text "$REG_FILE" 2>/dev/null)
	_st=$?
	_err=$(fs_is_plain_text "$REG_FILE" 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ "$_err" = "poshli: fs_is_plain_text: could not validate content" ]
)
assert_true $? "fs_is_plain_text: failing awk leaks no partial stdout and uses the validation diagnostic"

(
	_fs_shim_env empty
	_out=$(fs_is_plain_text "$REG_FILE" 2>/dev/null)
	_st=$?
	_err=$(fs_is_plain_text "$REG_FILE" 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ "$_err" = "poshli: fs_is_plain_text: could not validate content" ]
)
assert_true $? "fs_is_plain_text: awk without output fails validation"

(
	_fs_shim_env garbage
	_out=$(fs_is_plain_text "$REG_FILE" 2>/dev/null)
	_st=$?
	_err=$(fs_is_plain_text "$REG_FILE" 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ "$_err" = "poshli: fs_is_plain_text: could not validate content" ]
)
assert_true $? "fs_is_plain_text: unexpected awk output fails validation"

(
	_fs_shim_env valid-extra
	_out=$(fs_is_plain_text "$REG_FILE" 2>/dev/null)
	_st=$?
	_err=$(fs_is_plain_text "$REG_FILE" 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ "$_err" = "poshli: fs_is_plain_text: could not validate content" ]
)
assert_true $? "fs_is_plain_text: extra output after VALID fails validation"

(
	_fs_shim_env invalid
	_out=$(fs_is_plain_text "$REG_FILE" 2>/dev/null)
	_st=$?
	_err=$(fs_is_plain_text "$REG_FILE" 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ -z "$_err" ]
)
assert_true $? "fs_is_plain_text: exact INVALID sentinel returns 1 silently"

# Not plain text must stay silent and must not write anything to stdout.
_out=$(fs_is_plain_text "$BIN_FILE" 2>/dev/null)
_st=$?
_err=$(fs_is_plain_text "$BIN_FILE" 2>&1 >/dev/null)
[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ -z "$_err" ]
assert_true $? "fs_is_plain_text: not plain text returns 1 silently with empty stdout"

unset _out _st _err

# Cleanup fixtures
rm -rf "$TMP_FIXTURE_DIR"

test_summary
