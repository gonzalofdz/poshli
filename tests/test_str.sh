#!/bin/sh
#
# POSHLI - Unit tests for str.sh
#

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
. "$TEST_DIR/test_runner.sh"

if [ -n "$POSHLI_TEST_BUNDLE" ]; then
	. "$TEST_DIR/../poshli.sh"
else
	. "$TEST_DIR/../src/str.sh"
fi

printf '\n--- Running str.sh tests ---\n'

# Unicode fixtures. This test file is UTF-8.
_str_newline=$(printf 'a\nb')
_str_combining=$(printf 'e\314\201')        # e + U+0301 COMBINING ACUTE ACCENT
_str_combining_upper=$(printf 'E\314\201')  # E + U+0301
_str_zwj='👨‍👩‍👧‍👦'                       # family ZWJ sequence
_str_flag='🇪🇸'
_str_skin='👍🏽'
_str_keycap='1️⃣'

# Find an installed UTF-8 locale for explicit locale tests (may be empty).
_str_utf8_locale=""
if command -v locale >/dev/null 2>&1; then
	for _str_loc in C.utf8 C.UTF-8 en_US.UTF-8 en_US.utf8; do
		if locale -a 2>/dev/null | grep -i -x -F "$_str_loc" >/dev/null 2>&1; then
			_str_utf8_locale=$_str_loc
			break
		fi
	done
fi
unset _str_loc

# Run a command with an explicitly exported locale. External tools only see
# exported variables, so a plain LC_ALL assignment is not sufficient.
_str_locale() {
	(
		export LC_ALL
		LC_ALL=$1
		shift
		"$@"
	)
}

# Argument count validation: the operational functions report a missing mandatory
# argument as invalid usage (status 2); the predicates treat it as false (status 1).
trim; assert_status 2 $? "trim requires argument (status 2)"
lower; assert_status 2 $? "lower requires argument (status 2)"
upper; assert_status 2 $? "upper requires argument (status 2)"
starts_with; assert_status 1 $? "starts_with without arguments is false (status 1)"
starts_with "foo"; assert_status 1 $? "starts_with without prefix is false (status 1)"
ends_with; assert_status 1 $? "ends_with without arguments is false (status 1)"
ends_with "foo"; assert_status 1 $? "ends_with without suffix is false (status 1)"
contains; assert_status 1 $? "contains without arguments is false (status 1)"
contains "foo"; assert_status 1 $? "contains without substring is false (status 1)"
str_len; assert_status 2 $? "str_len requires argument (status 2)"
str_len_bytes; assert_status 2 $? "str_len_bytes requires argument (status 2)"
str_replace "a" "b"; assert_status 2 $? "str_replace requires 3 arguments (status 2)"

# is_empty
is_empty ""; assert_true $? "is_empty: empty string"
is_empty; assert_true $? "is_empty: no arguments is empty"
is_empty "hello"; assert_status 1 $? "is_empty: non-empty string"
is_empty " "; assert_status 1 $? "is_empty: space is not empty"
is_empty "0"; assert_status 1 $? "is_empty: 0 is not empty"

# trim
res=$(trim "hola"); assert_eq "hola" "$res" "trim: no spaces"
res=$(trim " hola "); assert_eq "hola" "$res" "trim: single spaces"
res=$(trim "    hola    "); assert_eq "hola" "$res" "trim: multiple spaces"
res=$(trim "	hola	"); assert_eq "hola" "$res" "trim: tabs"
res=$(trim " 	  hola 	 "); assert_eq "hola" "$res" "trim: mixed spaces and tabs"
res=$(trim "  hola   mundo  "); assert_eq "hola   mundo" "$res" "trim: preserves interior spaces"
res=$(trim "     "); assert_eq "" "$res" "trim: only spaces"
res=$(trim "		"); assert_eq "" "$res" "trim: only tabs"
res=$(trim ""); assert_eq "" "$res" "trim: empty string"
res=$(trim "  *.*  "); assert_eq "*.*" "$res" "trim: wildcards"
res=$(trim "  -n  "); assert_eq "-n" "$res" "trim: leading hyphen"

# lower
res=$(lower "HELLO"); assert_eq "hello" "$res" "lower: all uppercase"
res=$(lower "Hello World"); assert_eq "hello world" "$res" "lower: mixed case"
res=$(lower "123 ABC !?"); assert_eq "123 abc !?" "$res" "lower: numbers and symbols"
res=$(lower ""); assert_eq "" "$res" "lower: empty string"

# upper
res=$(upper "hello"); assert_eq "HELLO" "$res" "upper: all lowercase"
res=$(upper "Hello World"); assert_eq "HELLO WORLD" "$res" "upper: mixed case"
res=$(upper "123 abc !?"); assert_eq "123 ABC !?" "$res" "upper: numbers and symbols"
res=$(upper ""); assert_eq "" "$res" "upper: empty string"

# lower/upper: under a non-UTF-8 locale no Unicode backend must be selected.
# The ASCII fallback must leave non-ASCII bytes untouched, never corrupt them.
res=$(_str_locale C lower "HELLO España"); assert_eq "hello españa" "$res" "lower: C locale ASCII fallback"
res=$(_str_locale C upper "hello España"); assert_eq "HELLO ESPAñA" "$res" "upper: C locale ASCII fallback"
res=$(_str_locale C lower "ÁÉÍÓÚ"); assert_eq "ÁÉÍÓÚ" "$res" "lower: C locale leaves non-ASCII uppercase unchanged"
res=$(_str_locale C upper "áéíóú"); assert_eq "áéíóú" "$res" "upper: C locale leaves non-ASCII lowercase unchanged"
res=$(_str_locale C lower "😀 你好"); assert_eq "😀 你好" "$res" "lower: C locale leaves emoji/CJK unchanged"
res=$(_str_locale C upper "😀 你好"); assert_eq "😀 你好" "$res" "upper: C locale leaves emoji/CJK unchanged"
res=$(_str_locale C lower "$_str_combining"); assert_eq "$_str_combining" "$res" "lower: C locale preserves combining mark"
res=$(_str_locale C upper "$_str_combining"); assert_eq "$_str_combining_upper" "$res" "upper: C locale preserves combining mark"

# lower/upper: in an available UTF-8 locale, verify the behavior that the
# detected capabilities imply. If É maps to é, a broader Unicode set must map
# consistently; otherwise the safe ASCII fallback must leave it unchanged.
if [ -n "$_str_utf8_locale" ]; then
	_str_case_probe=$(_str_locale "$_str_utf8_locale" lower "É")
	if [ "$_str_case_probe" = "é" ]; then
		res=$(_str_locale "$_str_utf8_locale" lower "ÁÉÍÓÚ")
		assert_eq "áéíóú" "$res" "lower: UTF-8 Unicode simple mapping"
		res=$(_str_locale "$_str_utf8_locale" upper "áéíóú")
		assert_eq "ÁÉÍÓÚ" "$res" "upper: UTF-8 Unicode simple mapping"
		res=$(_str_locale "$_str_utf8_locale" upper "España")
		assert_eq "ESPAÑA" "$res" "upper: UTF-8 maps Ñ"
		res=$(_str_locale "$_str_utf8_locale" lower "ПРИВЕТ")
		assert_eq "привет" "$res" "lower: UTF-8 maps Cyrillic"
		res=$(_str_locale "$_str_utf8_locale" lower "$_str_combining_upper")
		assert_eq "$_str_combining" "$res" "lower: UTF-8 preserves combining mark"
	else
		res=$(_str_locale "$_str_utf8_locale" lower "ÁÉÍÓÚ")
		assert_eq "ÁÉÍÓÚ" "$res" "lower: UTF-8 falls back to ASCII"
		res=$(_str_locale "$_str_utf8_locale" upper "áéíóú")
		assert_eq "áéíóú" "$res" "upper: UTF-8 falls back to ASCII"
	fi
	res=$(_str_locale "$_str_utf8_locale" lower "😀 你好")
	assert_eq "😀 你好" "$res" "lower: UTF-8 leaves emoji/CJK unchanged"
	res=$(_str_locale "$_str_utf8_locale" upper "😀 你好")
	assert_eq "😀 你好" "$res" "upper: UTF-8 leaves emoji/CJK unchanged"
fi
unset _str_case_probe

# starts_with
starts_with "http://example.com" "http://"; assert_true $? "starts_with: URL protocol"
starts_with "foobar" "foo"; assert_true $? "starts_with: prefix"
starts_with "foobar" "foobar"; assert_true $? "starts_with: exact match"
starts_with "foobar" ""; assert_true $? "starts_with: empty prefix"
starts_with "foobar" "bar"; assert_status 1 $? "starts_with rejects: wrong prefix"
starts_with "" "foo"; assert_status 1 $? "starts_with rejects: empty target"

# ends_with
ends_with "archive.tar.gz" ".tar.gz"; assert_true $? "ends_with: compound extension"
ends_with "script.sh" ".sh"; assert_true $? "ends_with: extension"
ends_with "foobar" "foobar"; assert_true $? "ends_with: exact match"
ends_with "foobar" ""; assert_true $? "ends_with: empty suffix"
ends_with "foobar" "foo"; assert_status 1 $? "ends_with rejects: wrong suffix"
ends_with "" "bar"; assert_status 1 $? "ends_with rejects: empty target"

# contains
contains "the quick brown fox" "brown"; assert_true $? "contains: middle substring"
contains "the quick brown fox" "the"; assert_true $? "contains: start substring"
contains "the quick brown fox" "fox"; assert_true $? "contains: end substring"
contains "foobar" ""; assert_true $? "contains: empty substring"
contains "the quick brown fox" "cat"; assert_status 1 $? "contains rejects: absent substring"
contains "" "foo"; assert_status 1 $? "contains rejects: empty target"

# str_len: Unicode code points in valid UTF-8, independent of shell/locale.
res=$(str_len "hello"); assert_eq "5" "$res" "str_len: ASCII hello (5 code points)"
res=$(str_len ""); assert_eq "0" "$res" "str_len: empty string"
res=$(str_len "   "); assert_eq "3" "$res" "str_len: 3 spaces"
res=$(str_len "-n"); assert_eq "2" "$res" "str_len: leading hyphen"
res=$(str_len "España"); assert_eq "6" "$res" "str_len: España (6 code points)"
res=$(str_len "áéíóú"); assert_eq "5" "$res" "str_len: accented vowels (5 code points)"
res=$(str_len "你好"); assert_eq "2" "$res" "str_len: CJK (2 code points)"
res=$(str_len "😀"); assert_eq "1" "$res" "str_len: emoji (1 code point)"
res=$(str_len "$_str_combining"); assert_eq "2" "$res" "str_len: combining mark (2 code points)"
res=$(str_len "$_str_zwj"); assert_eq "7" "$res" "str_len: ZWJ family (7 code points)"
res=$(str_len "$_str_flag"); assert_eq "2" "$res" "str_len: flag (2 code points)"
res=$(str_len "$_str_skin"); assert_eq "2" "$res" "str_len: skin-tone emoji (2 code points)"
res=$(str_len "$_str_keycap"); assert_eq "3" "$res" "str_len: keycap sequence (3 code points)"
res=$(str_len "$_str_newline"); assert_eq "3" "$res" "str_len: embedded newline is a code point"
res=$(_str_locale C str_len "España"); assert_eq "6" "$res" "str_len: C locale still counts code points"
res=$(_str_locale C str_len "$_str_zwj"); assert_eq "7" "$res" "str_len: C locale counts ZWJ code points"
if [ -n "$_str_utf8_locale" ]; then
	res=$(_str_locale "$_str_utf8_locale" str_len "España")
	assert_eq "6" "$res" "str_len: UTF-8 locale counts code points"
	res=$(_str_locale "$_str_utf8_locale" str_len "$_str_zwj")
	assert_eq "7" "$res" "str_len: UTF-8 locale counts ZWJ code points"
fi

# str_len_bytes: exact byte counts, independent of shell/locale.
res=$(str_len_bytes "hello"); assert_eq "5" "$res" "str_len_bytes: ASCII hello (5 bytes)"
res=$(str_len_bytes ""); assert_eq "0" "$res" "str_len_bytes: empty string"
res=$(str_len_bytes "España"); assert_eq "7" "$res" "str_len_bytes: España (7 bytes)"
res=$(str_len_bytes "áéíóú"); assert_eq "10" "$res" "str_len_bytes: accented vowels (10 bytes)"
res=$(str_len_bytes "你好"); assert_eq "6" "$res" "str_len_bytes: CJK (6 bytes)"
res=$(str_len_bytes "😀"); assert_eq "4" "$res" "str_len_bytes: emoji (4 bytes)"
res=$(str_len_bytes "$_str_combining"); assert_eq "3" "$res" "str_len_bytes: combining mark (3 bytes)"
res=$(str_len_bytes "$_str_zwj"); assert_eq "25" "$res" "str_len_bytes: ZWJ family (25 bytes)"
res=$(str_len_bytes "$_str_flag"); assert_eq "8" "$res" "str_len_bytes: flag (8 bytes)"
res=$(str_len_bytes "$_str_skin"); assert_eq "8" "$res" "str_len_bytes: skin-tone emoji (8 bytes)"
res=$(str_len_bytes "$_str_keycap"); assert_eq "7" "$res" "str_len_bytes: keycap sequence (7 bytes)"
res=$(str_len_bytes "$_str_newline"); assert_eq "3" "$res" "str_len_bytes: embedded newline is one byte"
res=$(_str_locale C str_len_bytes "España"); assert_eq "7" "$res" "str_len_bytes: C locale byte count"
res=$(_str_locale C str_len_bytes "$_str_zwj"); assert_eq "25" "$res" "str_len_bytes: C locale ZWJ byte count"
if [ -n "$_str_utf8_locale" ]; then
	res=$(_str_locale "$_str_utf8_locale" str_len_bytes "España")
	assert_eq "7" "$res" "str_len_bytes: UTF-8 locale byte count"
	res=$(_str_locale "$_str_utf8_locale" str_len_bytes "$_str_zwj")
	assert_eq "25" "$res" "str_len_bytes: UTF-8 locale ZWJ byte count"
fi

# str_replace
res=$(str_replace "dog" "cat" "my dog is a dog"); assert_eq "my cat is a cat" "$res" "str_replace: simple words"
res=$(str_replace "and" "&" "bread and butter"); assert_eq "bread & butter" "$res" "str_replace: replace with ampersand"
res=$(str_replace "&" "and" "bread & butter"); assert_eq "bread and butter" "$res" "str_replace: replace ampersand"
res=$(str_replace "/" "\\" "/usr/bin"); assert_eq "\\usr\\bin" "$res" "str_replace: slashes and backslashes"
res=$(str_replace "." "_" "a.b.c"); assert_eq "a_b_c" "$res" "str_replace: dots"
res=$(str_replace "[a]" "[b]" "letters [a] and [a]"); assert_eq "letters [b] and [b]" "$res" "str_replace: brackets"
res=$(str_replace "*" "#" "star * and *"); assert_eq "star # and #" "$res" "str_replace: asterisks"
res=$(str_replace "?" "!" "what? really?"); assert_eq "what! really!" "$res" "str_replace: question marks"
res=$(str_replace "foo" "bar" "hello world"); assert_eq "hello world" "$res" "str_replace: pattern not found"
res=$(str_replace "" "x" "hello"); assert_eq "hello" "$res" "str_replace: empty search"

test_summary
