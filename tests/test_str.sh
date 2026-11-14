#!/bin/sh
#
# POSHLI - Unit tests for str.sh
#

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
. "$TEST_DIR/test_runner.sh"

if [ -n "$POSHLI_TEST_BUNDLE" ]; then
	. "$TEST_DIR/../poshli.sh"
else
	. "$TEST_DIR/../src/case_data.sh"
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
_str_invalid_continuation=$(printf '\200')
_str_invalid_truncated=$(printf '\303')
_str_invalid_overlong=$(printf '\300\257')
_str_invalid_surrogate=$(printf '\355\240\200')
_str_invalid_out_of_range=$(printf '\364\220\200\200')
_str_invalid_embedded=$(printf 'a\200b')
_str_valid_max=$(printf '\364\217\277\277')

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

# Argument count validation: single-argument transformations treat missing argument as empty string;
# predicates treat missing/insufficient arguments as false (status 1); str_replace requires 3 arguments (status 2).
res=$(trim); assert_status 0 $? "trim without argument returns status 0"; assert_eq "" "$res" "trim without argument prints empty string"
res=$(lower); assert_status 0 $? "lower without argument returns status 0"; assert_eq "" "$res" "lower without argument prints empty string"
res=$(upper); assert_status 0 $? "upper without argument returns status 0"; assert_eq "" "$res" "upper without argument prints empty string"
starts_with; assert_status 1 $? "starts_with without arguments is false (status 1)"
starts_with "foo"; assert_status 1 $? "starts_with without prefix is false (status 1)"
ends_with; assert_status 1 $? "ends_with without arguments is false (status 1)"
ends_with "foo"; assert_status 1 $? "ends_with without suffix is false (status 1)"
contains; assert_status 1 $? "contains without arguments is false (status 1)"
contains "foo"; assert_status 1 $? "contains without substring is false (status 1)"
res=$(str_len); assert_status 0 $? "str_len without argument returns status 0"; assert_eq "0" "$res" "str_len without argument prints 0"
res=$(str_len_bytes); assert_status 0 $? "str_len_bytes without argument returns status 0"; assert_eq "0" "$res" "str_len_bytes without argument prints 0"
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
_str_trim_multiline=$(printf '  a  \n  b  ')
res=$(trim "$_str_trim_multiline")
assert_eq "$(printf 'a  \n  b')" "$res" "trim: preserves internal spacing across newlines"

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

# lower/upper: the contract is deterministic and identical in every locale:
# Unicode case mapping is applied to cased code points (ASCII, Latin, Greek
# and Cyrillic guaranteed; any other code point with a generated mapping is
# converted too), code points without a mapping are preserved unchanged, and
# invalid UTF-8 is rejected with status 1 (like str_len).

# Latin
res=$(lower "España"); assert_status 0 $? "lower: Latin maps"; assert_eq "españa" "$res" "lower: España -> españa"
res=$(upper "España"); assert_status 0 $? "upper: Latin maps"; assert_eq "ESPAÑA" "$res" "upper: España -> ESPAÑA"
res=$(lower "ÁRBOL ÑANDÚ"); assert_eq "árbol ñandú" "$res" "lower: ÁRBOL ÑANDÚ -> árbol ñandú"
res=$(upper "España café"); assert_eq "ESPAÑA CAFÉ" "$res" "upper: España café -> ESPAÑA CAFÉ"
res=$(lower "áéíóúüñ"); assert_eq "áéíóúüñ" "$res" "lower: keeps lowercase letters unchanged"
res=$(upper "ÁÉÍÓÚÜÑ"); assert_eq "ÁÉÍÓÚÜÑ" "$res" "upper: keeps uppercase letters unchanged"
res=$(lower "HELLO España"); assert_eq "hello españa" "$res" "lower: ASCII and Latin together"

# Greek. Case mapping preserves accents as they are: U+0391 maps to U+03B1;
# mapping never adds or removes diacritics.
res=$(lower "ΠΡΙΒΕΤ"); assert_eq "πριβετ" "$res" "lower: ΠΡΙΒΕΤ -> πριβετ"
res=$(upper "πριβετ"); assert_eq "ΠΡΙΒΕΤ" "$res" "upper: πριβετ -> ΠΡΙΒΕΤ"
res=$(upper "ελληνικά"); assert_eq "ΕΛΛΗΝΙΚΆ" "$res" "upper: Greek with tonos maps and keeps the accent"
res=$(lower "ΕΛΛΑΔΑ"); assert_eq "ελλαδα" "$res" "lower: unaccented capitals map to unaccented small letters"
res=$(lower "ΟΔΟΣ"); assert_eq "οδοσ" "$res" "lower: sigma maps to U+03C3 (no contextual final sigma)"

# Cyrillic
res=$(lower "ПРИВЕТ"); assert_eq "привет" "$res" "lower: ПРИВЕТ -> привет"
res=$(upper "привет"); assert_eq "ПРИВЕТ" "$res" "upper: привет -> ПРИВЕТ"
res=$(lower "ЁЛКА"); assert_eq "ёлка" "$res" "lower: ЁЛКА -> ёлка"

# Mixed text: scripts are mapped, everything else is preserved (emoji, CJK,
# symbols, punctuation and ASCII emoticonos).
res=$(upper "Hola ;-) España 😀 你好 € — 🎉"); assert_eq "HOLA ;-) ESPAÑA 😀 你好 € — 🎉" "$res" "upper: mixed text maps letters and preserves the rest"
res=$(lower "ÁRBOL ПРИВЕТ ΕΛΛΑΔΑ 🎉"); assert_eq "árbol привет ελλαδα 🎉" "$res" "lower: mixed text maps letters and preserves the rest"

# Code points without a mapping are preserved: combining marks, emoji, CJK,
# symbols, unassigned code points (U+0378) and noncharacters (U+FDD0).
res=$(upper "$_str_combining"); assert_eq "$_str_combining_upper" "$res" "upper: maps base letter and preserves combining mark"
res=$(lower "😀 你好 €"); assert_eq "😀 你好 €" "$res" "lower: preserves emoji, CJK and symbols"
res=$(lower ";-)"); assert_eq ";-)" "$res" "lower: preserves ASCII emoticonos"
res=$(upper "$(printf '\315\270\357\267\220')"); assert_eq "$(printf '\315\270\357\267\220')" "$res" "upper: preserves unassigned code points and noncharacters"

# One-to-many mappings are applied (Unicode unconditional expansions).
res=$(upper "grüße"); assert_eq "GRÜSSE" "$res" "upper: U+00DF expands to SS"
res=$(lower "grüße"); assert_eq "grüße" "$res" "lower: U+00DF has no lowercase mapping and is preserved"
res=$(lower "İSTANBUL"); assert_eq "$(printf 'i\314\207stanbul')" "$res" "lower: U+0130 expands to i + U+0307"

# lower/upper: identical in every locale.
res=$(_str_locale C lower "ПРИВЕТ ΠΡΙΒΕΤ"); assert_eq "привет πριβετ" "$res" "lower: C locale maps Greek and Cyrillic"
res=$(_str_locale C upper "España café"); assert_eq "ESPAÑA CAFÉ" "$res" "upper: C locale maps guaranteed letters"
if [ -n "$_str_utf8_locale" ]; then
	res=$(_str_locale "$_str_utf8_locale" lower "ÁRBOL ÑANDÚ"); assert_status 0 $? "lower: UTF-8 locale maps guaranteed letters"; assert_eq "árbol ñandú" "$res" "lower: UTF-8 locale maps guaranteed letters"
	res=$(_str_locale "$_str_utf8_locale" upper "πριβετ привет"); assert_eq "ΠΡΙΒΕΤ ПРИВЕТ" "$res" "upper: UTF-8 locale maps Greek and Cyrillic"
fi

# lower/upper: invalid UTF-8 is rejected like in str_len.
res=$(lower "$_str_invalid_truncated" 2>/dev/null); assert_status 1 $? "lower: rejects invalid UTF-8"; assert_eq "" "$res" "lower: prints nothing for invalid UTF-8"
res=$(upper "$_str_invalid_embedded" 2>/dev/null); assert_status 1 $? "upper: rejects invalid UTF-8"; assert_eq "" "$res" "upper: prints nothing for invalid UTF-8"
res=$(lower "$_str_invalid_overlong" 2>/dev/null); assert_status 1 $? "lower: rejects overlong UTF-8"; assert_eq "" "$res" "lower: prints nothing for overlong UTF-8"
res=$(upper "$_str_invalid_surrogate" 2>/dev/null); assert_status 1 $? "upper: rejects UTF-8 surrogates"; assert_eq "" "$res" "upper: prints nothing for UTF-8 surrogates"

# lower/upper: the diagnostic reports invalid UTF-8.
err=$(lower "$_str_invalid_truncated" 2>&1 >/dev/null)
_str_diag=""
case "$err" in *"input is not valid UTF-8"*) _str_diag="invalid-utf8" ;; esac
assert_eq "invalid-utf8" "$_str_diag" "lower: diagnostic reports invalid UTF-8"
unset err _str_diag

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

# str_len: invalid UTF-8 is rejected instead of yielding an approximate count.
res=$(str_len "$_str_invalid_continuation" 2>/dev/null); assert_status 1 $? "str_len rejects a lone continuation byte"; assert_eq "" "$res" "str_len prints nothing for a lone continuation byte"
res=$(str_len "$_str_invalid_truncated" 2>/dev/null); assert_status 1 $? "str_len rejects a truncated sequence"; assert_eq "" "$res" "str_len prints nothing for a truncated sequence"
res=$(str_len "$_str_invalid_overlong" 2>/dev/null); assert_status 1 $? "str_len rejects an overlong sequence"; assert_eq "" "$res" "str_len prints nothing for an overlong sequence"
res=$(str_len "$_str_invalid_surrogate" 2>/dev/null); assert_status 1 $? "str_len rejects a surrogate"; assert_eq "" "$res" "str_len prints nothing for a surrogate"
res=$(str_len "$_str_invalid_out_of_range" 2>/dev/null); assert_status 1 $? "str_len rejects a code point beyond U+10FFFF"; assert_eq "" "$res" "str_len prints nothing for a code point beyond U+10FFFF"
res=$(str_len "$_str_invalid_embedded" 2>/dev/null); assert_status 1 $? "str_len rejects invalid bytes embedded in valid text"; assert_eq "" "$res" "str_len prints nothing for invalid bytes embedded in valid text"
res=$(str_len "$_str_valid_max"); assert_eq "1" "$res" "str_len accepts U+10FFFF"

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

# od transport ("od -A n -v -t u1") and long repetitive input.
# The invocation is strictly POSIX (XCU od in POSIX.1-2017/2024: -A n, -v
# and -t u1 are all standard) and -v is what stops od from replacing groups
# of repeated output lines with a "*" line. Long repetitive inputs must
# reach the parsers complete: one number per byte, no "*" substitution.
# Each fixture spans many od output lines, so any elision would be visible.
_str_od_stats() {
#	Prints "<fields> <stars>": the number of byte values emitted by the
#	exact od invocation used in src/str.sh, and the number of "*" fields
#	(od's repeated-line substitution marker, impossible with -v).
#
	printf '%s' "$1" | LC_ALL=C od -A n -v -t u1 | LC_ALL=C awk '
		{ for (i = 1; i <= NF; i++) { n++; if ($i == "*") stars++ } }
		END { print n + 0, stars + 0 }
	'
}

# Repetitive fixtures: ASCII (1000 bytes), 2-byte UTF-8 (800 bytes) and
# 4-byte UTF-8 emoji (1000 bytes), each repeated long enough to cover many
# od output lines.
_str_ascii_rep=''
_str_ascii_rep_up=''
_str_rep_i=0
while [ "$_str_rep_i" -lt 1000 ]; do
	_str_ascii_rep=${_str_ascii_rep}a
	_str_ascii_rep_up=${_str_ascii_rep_up}A
	_str_rep_i=$((_str_rep_i + 1))
done
_str_mb_rep=''
_str_mb_rep_up=''
_str_rep_i=0
while [ "$_str_rep_i" -lt 400 ]; do
	_str_mb_rep=${_str_mb_rep}ñ
	_str_mb_rep_up=${_str_mb_rep_up}Ñ
	_str_rep_i=$((_str_rep_i + 1))
done
_str_emoji_rep=''
_str_rep_i=0
while [ "$_str_rep_i" -lt 250 ]; do
	_str_emoji_rep=${_str_emoji_rep}😀
	_str_rep_i=$((_str_rep_i + 1))
done
unset _str_rep_i

# od transport: no byte is lost and no "*" substitution appears.
res=$(_str_od_stats "$_str_ascii_rep"); assert_eq "1000 0" "$res" "od transport: 1000 repeated ASCII bytes complete, no *"
res=$(_str_od_stats "$_str_mb_rep"); assert_eq "800 0" "$res" "od transport: 800 bytes of repeated 2-byte UTF-8 complete, no *"
res=$(_str_od_stats "$_str_emoji_rep"); assert_eq "1000 0" "$res" "od transport: 1000 bytes of repeated 4-byte UTF-8 complete, no *"

# str_len: long repetitive input counts every code point.
res=$(str_len "$_str_ascii_rep"); assert_status 0 $? "str_len: 1000 repeated ASCII returns 0"; assert_eq "1000" "$res" "str_len: 1000 repeated ASCII code points"
res=$(str_len "$_str_mb_rep"); assert_status 0 $? "str_len: 400 repeated 2-byte code points returns 0"; assert_eq "400" "$res" "str_len: 400 repeated 2-byte code points"
res=$(str_len "$_str_emoji_rep"); assert_status 0 $? "str_len: 250 repeated emoji returns 0"; assert_eq "250" "$res" "str_len: 250 repeated 4-byte code points"

# lower/upper: every repetition is mapped; none is dropped or substituted.
res=$(lower "$_str_ascii_rep_up"); assert_status 0 $? "lower: 1000 repeated ASCII letters returns 0"; assert_eq "$_str_ascii_rep" "$res" "lower: 1000 repeated ASCII letters map completely"
res=$(upper "$_str_mb_rep"); assert_status 0 $? "upper: 400 repeated ñ returns 0"; assert_eq "$_str_mb_rep_up" "$res" "upper: 400 repeated ñ map completely"
res=$(lower "$_str_emoji_rep"); assert_status 0 $? "lower: 250 repeated emoji returns 0"; assert_eq "$_str_emoji_rep" "$res" "lower: 250 repeated emoji preserved unchanged"
res=$(upper "$_str_emoji_rep"); assert_status 0 $? "upper: 250 repeated emoji returns 0"; assert_eq "$_str_emoji_rep" "$res" "upper: 250 repeated emoji preserved unchanged"

# The mapped results keep every byte.
res=$(str_len_bytes "$(lower "$_str_ascii_rep_up")"); assert_eq "1000" "$res" "lower: mapped ASCII keeps 1000 bytes"
res=$(str_len_bytes "$(upper "$_str_mb_rep")"); assert_eq "800" "$res" "upper: mapped 2-byte UTF-8 keeps 800 bytes"
res=$(str_len_bytes "$(upper "$_str_emoji_rep")"); assert_eq "1000" "$res" "upper: preserved emoji keeps 1000 bytes"

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
