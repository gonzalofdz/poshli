#!/bin/sh
#
# POSHLI - Unit tests for str.sh
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
res=$(str_trim); assert_status 0 $? "str_trim without argument returns status 0"; assert_eq "" "$res" "str_trim without argument prints empty string"
res=$(str_lower); assert_status 0 $? "str_lower without argument returns status 0"; assert_eq "" "$res" "str_lower without argument prints empty string"
res=$(str_upper); assert_status 0 $? "str_upper without argument returns status 0"; assert_eq "" "$res" "str_upper without argument prints empty string"
str_starts_with; assert_status 1 $? "str_starts_with without arguments is false (status 1)"
str_starts_with "foo"; assert_status 1 $? "str_starts_with without prefix is false (status 1)"
str_ends_with; assert_status 1 $? "str_ends_with without arguments is false (status 1)"
str_ends_with "foo"; assert_status 1 $? "str_ends_with without suffix is false (status 1)"
str_contains; assert_status 1 $? "str_contains without arguments is false (status 1)"
str_contains "foo"; assert_status 1 $? "str_contains without substring is false (status 1)"
res=$(str_len); assert_status 0 $? "str_len without argument returns status 0"; assert_eq "0" "$res" "str_len without argument prints 0"
res=$(str_len_bytes); assert_status 0 $? "str_len_bytes without argument returns status 0"; assert_eq "0" "$res" "str_len_bytes without argument prints 0"
str_replace "a" "b"; assert_status 2 $? "str_replace requires 3 arguments (status 2)"

# str_empty
str_empty ""; assert_true $? "str_empty: empty string"
str_empty; assert_true $? "str_empty: no arguments is empty"
str_empty "hello"; assert_status 1 $? "str_empty: non-empty string"
str_empty " "; assert_status 1 $? "str_empty: space is not empty"
str_empty "0"; assert_status 1 $? "str_empty: 0 is not empty"

# str_trim
res=$(str_trim "hola"); assert_eq "hola" "$res" "str_trim: no spaces"
res=$(str_trim " hola "); assert_eq "hola" "$res" "str_trim: single spaces"
res=$(str_trim "    hola    "); assert_eq "hola" "$res" "str_trim: multiple spaces"
res=$(str_trim "	hola	"); assert_eq "hola" "$res" "str_trim: tabs"
res=$(str_trim " 	  hola 	 "); assert_eq "hola" "$res" "str_trim: mixed spaces and tabs"
res=$(str_trim "  hola   mundo  "); assert_eq "hola   mundo" "$res" "str_trim: preserves interior spaces"
res=$(str_trim "     "); assert_eq "" "$res" "str_trim: only spaces"
res=$(str_trim "		"); assert_eq "" "$res" "str_trim: only tabs"
res=$(str_trim ""); assert_eq "" "$res" "str_trim: empty string"
res=$(str_trim "  *.*  "); assert_eq "*.*" "$res" "str_trim: wildcards"
res=$(str_trim "  -n  "); assert_eq "-n" "$res" "str_trim: leading hyphen"
_str_trim_multiline=$(printf '  a  \n  b  ')
res=$(str_trim "$_str_trim_multiline")
assert_eq "$(printf 'a  \n  b')" "$res" "str_trim: preserves internal spacing across newlines"

# str_lower
res=$(str_lower "HELLO"); assert_eq "hello" "$res" "str_lower: all uppercase"
res=$(str_lower "Hello World"); assert_eq "hello world" "$res" "str_lower: mixed case"
res=$(str_lower "123 ABC !?"); assert_eq "123 abc !?" "$res" "str_lower: numbers and symbols"
res=$(str_lower ""); assert_eq "" "$res" "str_lower: empty string"

# str_upper
res=$(str_upper "hello"); assert_eq "HELLO" "$res" "str_upper: all lowercase"
res=$(str_upper "Hello World"); assert_eq "HELLO WORLD" "$res" "str_upper: mixed case"
res=$(str_upper "123 abc !?"); assert_eq "123 ABC !?" "$res" "str_upper: numbers and symbols"
res=$(str_upper ""); assert_eq "" "$res" "str_upper: empty string"

# str_lower/str_upper: the contract is deterministic and identical in every locale:
# Unicode case mapping is applied to cased code points (ASCII, Latin, Greek
# and Cyrillic guaranteed; any other code point with a generated mapping is
# converted too), code points without a mapping are preserved unchanged, and
# invalid UTF-8 is rejected with status 1 (like str_len).

# Latin
res=$(str_lower "España"); assert_status 0 $? "str_lower: Latin maps"; assert_eq "españa" "$res" "str_lower: España -> españa"
res=$(str_upper "España"); assert_status 0 $? "str_upper: Latin maps"; assert_eq "ESPAÑA" "$res" "str_upper: España -> ESPAÑA"
res=$(str_lower "ÁRBOL ÑANDÚ"); assert_eq "árbol ñandú" "$res" "str_lower: ÁRBOL ÑANDÚ -> árbol ñandú"
res=$(str_upper "España café"); assert_eq "ESPAÑA CAFÉ" "$res" "str_upper: España café -> ESPAÑA CAFÉ"
res=$(str_lower "áéíóúüñ"); assert_eq "áéíóúüñ" "$res" "str_lower: keeps lowercase letters unchanged"
res=$(str_upper "ÁÉÍÓÚÜÑ"); assert_eq "ÁÉÍÓÚÜÑ" "$res" "str_upper: keeps uppercase letters unchanged"
res=$(str_lower "HELLO España"); assert_eq "hello españa" "$res" "str_lower: ASCII and Latin together"

# Greek. Case mapping preserves accents as they are: U+0391 maps to U+03B1;
# mapping never adds or removes diacritics.
res=$(str_lower "ΠΡΙΒΕΤ"); assert_eq "πριβετ" "$res" "str_lower: ΠΡΙΒΕΤ -> πριβετ"
res=$(str_upper "πριβετ"); assert_eq "ΠΡΙΒΕΤ" "$res" "str_upper: πριβετ -> ΠΡΙΒΕΤ"
res=$(str_upper "ελληνικά"); assert_eq "ΕΛΛΗΝΙΚΆ" "$res" "str_upper: Greek with tonos maps and keeps the accent"
res=$(str_lower "ΕΛΛΑΔΑ"); assert_eq "ελλαδα" "$res" "str_lower: unaccented capitals map to unaccented small letters"
res=$(str_lower "ΟΔΟΣ"); assert_eq "οδοσ" "$res" "str_lower: sigma maps to U+03C3 (no contextual final sigma)"

# Cyrillic
res=$(str_lower "ПРИВЕТ"); assert_eq "привет" "$res" "str_lower: ПРИВЕТ -> привет"
res=$(str_upper "привет"); assert_eq "ПРИВЕТ" "$res" "str_upper: привет -> ПРИВЕТ"
res=$(str_lower "ЁЛКА"); assert_eq "ёлка" "$res" "str_lower: ЁЛКА -> ёлка"

# Mixed text: scripts are mapped, everything else is preserved (emoji, CJK,
# symbols, punctuation and ASCII emoticonos).
res=$(str_upper "Hola ;-) España 😀 你好 € — 🎉"); assert_eq "HOLA ;-) ESPAÑA 😀 你好 € — 🎉" "$res" "str_upper: mixed text maps letters and preserves the rest"
res=$(str_lower "ÁRBOL ПРИВЕТ ΕΛΛΑΔΑ 🎉"); assert_eq "árbol привет ελλαδα 🎉" "$res" "str_lower: mixed text maps letters and preserves the rest"

# Code points without a mapping are preserved: combining marks, emoji, CJK,
# symbols, unassigned code points (U+0378) and noncharacters (U+FDD0).
res=$(str_upper "$_str_combining"); assert_eq "$_str_combining_upper" "$res" "str_upper: maps base letter and preserves combining mark"
res=$(str_lower "😀 你好 €"); assert_eq "😀 你好 €" "$res" "str_lower: preserves emoji, CJK and symbols"
res=$(str_lower ";-)"); assert_eq ";-)" "$res" "str_lower: preserves ASCII emoticonos"
res=$(str_upper "$(printf '\315\270\357\267\220')"); assert_eq "$(printf '\315\270\357\267\220')" "$res" "str_upper: preserves unassigned code points and noncharacters"

# One-to-many mappings are applied (Unicode unconditional expansions).
res=$(str_upper "grüße"); assert_eq "GRÜSSE" "$res" "str_upper: U+00DF expands to SS"
res=$(str_lower "grüße"); assert_eq "grüße" "$res" "str_lower: U+00DF has no lowercase mapping and is preserved"
res=$(str_lower "İSTANBUL"); assert_eq "$(printf 'i\314\207stanbul')" "$res" "str_lower: U+0130 expands to i + U+0307"

# str_lower/str_upper: identical in every locale.
res=$(_str_locale C str_lower "ПРИВЕТ ΠΡΙΒΕΤ"); assert_eq "привет πριβετ" "$res" "str_lower: C locale maps Greek and Cyrillic"
res=$(_str_locale C str_upper "España café"); assert_eq "ESPAÑA CAFÉ" "$res" "str_upper: C locale maps guaranteed letters"
if [ -n "$_str_utf8_locale" ]; then
	res=$(_str_locale "$_str_utf8_locale" str_lower "ÁRBOL ÑANDÚ"); assert_status 0 $? "str_lower: UTF-8 locale maps guaranteed letters"; assert_eq "árbol ñandú" "$res" "str_lower: UTF-8 locale maps guaranteed letters"
	res=$(_str_locale "$_str_utf8_locale" str_upper "πριβετ привет"); assert_eq "ΠΡΙΒΕΤ ПРИВЕТ" "$res" "str_upper: UTF-8 locale maps Greek and Cyrillic"
fi

# str_lower/str_upper: invalid UTF-8 is rejected like in str_len.
res=$(str_lower "$_str_invalid_truncated" 2>/dev/null); assert_status 1 $? "str_lower: rejects invalid UTF-8"; assert_eq "" "$res" "str_lower: prints nothing for invalid UTF-8"
res=$(str_upper "$_str_invalid_embedded" 2>/dev/null); assert_status 1 $? "str_upper: rejects invalid UTF-8"; assert_eq "" "$res" "str_upper: prints nothing for invalid UTF-8"
res=$(str_lower "$_str_invalid_overlong" 2>/dev/null); assert_status 1 $? "str_lower: rejects overlong UTF-8"; assert_eq "" "$res" "str_lower: prints nothing for overlong UTF-8"
res=$(str_upper "$_str_invalid_surrogate" 2>/dev/null); assert_status 1 $? "str_upper: rejects UTF-8 surrogates"; assert_eq "" "$res" "str_upper: prints nothing for UTF-8 surrogates"

# str_lower/str_upper: the diagnostic reports invalid UTF-8.
err=$(str_lower "$_str_invalid_truncated" 2>&1 >/dev/null)
_str_diag=""
case "$err" in *"input is not valid UTF-8"*) _str_diag="invalid-utf8" ;; esac
assert_eq "invalid-utf8" "$_str_diag" "str_lower: diagnostic reports invalid UTF-8"
unset err _str_diag

# str_lower/str_upper: diagnostics use the public function names (H2).
err=$(str_upper "$_str_invalid_truncated" 2>&1 >/dev/null)
assert_eq "poshli: str_upper: input is not valid UTF-8" "$err" "str_upper: diagnostic uses the public name"
unset err

(
	_test_shim_od missing
	_out=$(str_lower A 2>/dev/null)
	_st=$?
	_err=$(str_lower A 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ "$_err" = "poshli: str_lower: could not read input bytes" ]
)
assert_true $? "str_lower: od failure diagnostic uses the public name"

# str_starts_with
str_starts_with "http://example.com" "http://"; assert_true $? "str_starts_with: URL protocol"
str_starts_with "foobar" "foo"; assert_true $? "str_starts_with: prefix"
str_starts_with "foobar" "foobar"; assert_true $? "str_starts_with: exact match"
str_starts_with "foobar" ""; assert_true $? "str_starts_with: empty prefix"
str_starts_with "foobar" "bar"; assert_status 1 $? "str_starts_with rejects: wrong prefix"
str_starts_with "" "foo"; assert_status 1 $? "str_starts_with rejects: empty target"

# str_ends_with
str_ends_with "archive.tar.gz" ".tar.gz"; assert_true $? "str_ends_with: compound extension"
str_ends_with "script.sh" ".sh"; assert_true $? "str_ends_with: extension"
str_ends_with "foobar" "foobar"; assert_true $? "str_ends_with: exact match"
str_ends_with "foobar" ""; assert_true $? "str_ends_with: empty suffix"
str_ends_with "foobar" "foo"; assert_status 1 $? "str_ends_with rejects: wrong suffix"
str_ends_with "" "bar"; assert_status 1 $? "str_ends_with rejects: empty target"

# str_contains
str_contains "the quick brown fox" "brown"; assert_true $? "str_contains: middle substring"
str_contains "the quick brown fox" "the"; assert_true $? "str_contains: start substring"
str_contains "the quick brown fox" "fox"; assert_true $? "str_contains: end substring"
str_contains "foobar" ""; assert_true $? "str_contains: empty substring"
str_contains "the quick brown fox" "cat"; assert_status 1 $? "str_contains rejects: absent substring"
str_contains "" "foo"; assert_status 1 $? "str_contains rejects: empty target"

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

# str_lower/str_upper: every repetition is mapped; none is dropped or substituted.
res=$(str_lower "$_str_ascii_rep_up"); assert_status 0 $? "str_lower: 1000 repeated ASCII letters returns 0"; assert_eq "$_str_ascii_rep" "$res" "str_lower: 1000 repeated ASCII letters map completely"
res=$(str_upper "$_str_mb_rep"); assert_status 0 $? "str_upper: 400 repeated ñ returns 0"; assert_eq "$_str_mb_rep_up" "$res" "str_upper: 400 repeated ñ map completely"
res=$(str_lower "$_str_emoji_rep"); assert_status 0 $? "str_lower: 250 repeated emoji returns 0"; assert_eq "$_str_emoji_rep" "$res" "str_lower: 250 repeated emoji preserved unchanged"
res=$(str_upper "$_str_emoji_rep"); assert_status 0 $? "str_upper: 250 repeated emoji returns 0"; assert_eq "$_str_emoji_rep" "$res" "str_upper: 250 repeated emoji preserved unchanged"

# The mapped results keep every byte.
res=$(str_len_bytes "$(str_lower "$_str_ascii_rep_up")"); assert_eq "1000" "$res" "str_lower: mapped ASCII keeps 1000 bytes"
res=$(str_len_bytes "$(str_upper "$_str_mb_rep")"); assert_eq "800" "$res" "str_upper: mapped 2-byte UTF-8 keeps 800 bytes"
res=$(str_len_bytes "$(str_upper "$_str_emoji_rep")"); assert_eq "1000" "$res" "str_upper: preserved emoji keeps 1000 bytes"

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

# POSIX pipelines only report the last command's status. Functions that rely
# on od or wc must detect a tool failure and fail closed instead of returning
# success with an empty or partial result. The checks run in subshells so the
# shims do not leak into the rest of the suite; each subshell exit status is
# asserted in the parent so the suite counters are updated.
(
	_test_shim_od missing
	res=$(str_len "hello" 2>/dev/null)
	[ $? -eq 1 ]
)
assert_true $? "str_len fails closed when od is unavailable"
(
	_test_shim_od missing
	res=$(str_len "hello" 2>/dev/null)
	[ -z "$res" ]
)
assert_true $? "str_len prints nothing when od is unavailable"
(
	_test_shim_od missing
	res=$(str_lower "HELLO" 2>/dev/null)
	[ $? -eq 1 ]
)
assert_true $? "str_lower fails closed when od is unavailable"
(
	_test_shim_od missing
	res=$(str_lower "HELLO" 2>/dev/null)
	[ -z "$res" ]
)
assert_true $? "str_lower prints nothing when od is unavailable"
(
	_test_shim_od missing
	res=$(str_upper "hello" 2>/dev/null)
	[ $? -eq 1 ]
)
assert_true $? "str_upper fails closed when od is unavailable"
(
	_test_shim_od missing
	res=$(str_upper "hello" 2>/dev/null)
	[ -z "$res" ]
)
assert_true $? "str_upper prints nothing when od is unavailable"
(
	_test_shim_wc missing
	res=$(str_len_bytes "hello" 2>/dev/null)
	[ $? -eq 1 ]
)
assert_true $? "str_len_bytes fails closed when wc is unavailable"
(
	_test_shim_wc missing
	res=$(str_len_bytes "hello" 2>/dev/null)
	[ -z "$res" ]
)
assert_true $? "str_len_bytes prints nothing when wc is unavailable"

# A1: failures while writing the final result to stdout must not be hidden by
# the cleanup unset. stdout is redirected to a read-only descriptor at the start of each subshell; the status
# and cleanup are checked in that subshell. The observed status is reported
# through fd 3 so closing stdout cannot hide it. A leaked temporary turns the
# reported status into the sentinel 9.
_str_wfail=$( (
	exec 1</dev/null
	str_trim "  a  " 2>/dev/null
	_st=$?
	[ -z "${_poshli_str_trim_value+x}" ] || _st=9
	printf '%s' "$_st" >&3
) 3>&1 )
_test_assert_write_failure "$_str_wfail" "str_trim: write failure returns 1 and cleans temporaries"

_str_wfail=$( (
	exec 1</dev/null
	str_lower A 2>/dev/null
	_st=$?
	[ -z "${_poshli_case_map_table+x}${_poshli_case_map_out+x}${_poshli_case_map_od+x}" ] || _st=9
	printf '%s' "$_st" >&3
) 3>&1 )
_test_assert_write_failure "$_str_wfail" "str_lower: write failure returns 1 and cleans temporaries"

_str_wfail=$( (
	exec 1</dev/null
	str_len abc 2>/dev/null
	_st=$?
	[ -z "${_poshli_str_len_od+x}${_poshli_str_len_out+x}" ] || _st=9
	printf '%s' "$_st" >&3
) 3>&1 )
_test_assert_write_failure "$_str_wfail" "str_len: write failure returns 1 and cleans temporaries"

_str_wfail=$( (
	exec 1</dev/null
	str_len_bytes abc 2>/dev/null
	_st=$?
	[ -z "${_poshli_str_len_bytes_count+x}${_poshli_str_len_bytes_result+x}" ] || _st=9
	printf '%s' "$_st" >&3
) 3>&1 )
_test_assert_write_failure "$_str_wfail" "str_len_bytes: write failure returns 1 and cleans temporaries"

_str_wfail=$( (
	exec 1</dev/null
	str_replace a b a 2>/dev/null
	_st=$?
	[ -z "${_poshli_str_replace_search+x}${_poshli_str_replace_replacement+x}${_poshli_str_replace_str+x}${_poshli_str_replace_out+x}${_poshli_str_replace_prefix+x}${_poshli_str_replace_rest+x}" ] || _st=9
	printf '%s' "$_st" >&3
) 3>&1 )
_test_assert_write_failure "$_str_wfail" "str_replace: write failure returns 1 and cleans temporaries"

# A failing awk that writes to stdout before exiting must not leak that
# partial result: str_len buffers the awk output and publishes it only on
# success.
_str_wfail=$( (
	_test_shim_awk partial
	_out=$(str_len hello 2>/dev/null)
	_st=$?
	[ -z "$_out" ] || _st=9
	printf '%s' "$_st"
) )
assert_status 1 "$_str_wfail" "str_len: failing awk leaks no partial stdout and returns 1"

(
	_test_shim_awk fail
	_out=$(str_len hello 2>/dev/null)
	[ "$?" -eq 1 ] && [ -z "$_out" ]
)
assert_true $? "str_len: failing awk returns 1 with empty stdout"

(
	_test_shim_awk fail
	_out=$(str_len_bytes hello 2>/dev/null)
	[ "$?" -eq 1 ] && [ -z "$_out" ]
)
assert_true $? "str_len_bytes: failing awk returns 1 with empty stdout"

# _poshli_case_map: missing data and invalid selector must keep stdout clean.
(
	unset _POSHLI_CASE_LOADED
	_out=$(_poshli_case_map lower A 2>/dev/null)
	_st=$?
	_err=$(_poshli_case_map lower A 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ -n "$_err" ]
)
assert_true $? "_poshli_case_map: missing data returns 1, empty stdout and stderr diagnostic"

(
	_out=$(_poshli_case_map bogus A 2>/dev/null)
	_st=$?
	_err=$(_poshli_case_map bogus A 2>&1 >/dev/null)
	[ "$_st" -eq 2 ] && [ -z "$_out" ] && [ -z "$_err" ]
)
assert_true $? "_poshli_case_map: invalid selector returns 2 silently"

# str_replace: insufficient arguments and the empty-search branch.
(
	_out=$(str_replace a b 2>/dev/null)
	_st=$?
	_err=$(str_replace a b 2>&1 >/dev/null)
	[ "$_st" -eq 2 ] && [ -z "$_out" ] && [ -z "$_err" ]
)
assert_true $? "str_replace: two arguments returns 2 silently"

_str_wfail=$( (
	exec 1</dev/null
	str_replace "" x hello 2>/dev/null
	_st=$?
	printf '%s' "$_st" >&3
) 3>&1 )
_test_assert_write_failure "$_str_wfail" "str_replace: empty-search write failure returns 1"

# The no-argument paths already propagate the final printf status through
# return; keep that behavior covered.
_str_wfail=$( ( exec 1</dev/null; str_trim 2>/dev/null; printf '%s' "$?" >&3 ) 3>&1 )
_test_assert_write_failure "$_str_wfail" "str_trim: no-argument write failure returns 1"
_str_wfail=$( ( exec 1</dev/null; str_lower 2>/dev/null; printf '%s' "$?" >&3 ) 3>&1 )
_test_assert_write_failure "$_str_wfail" "str_lower: no-argument write failure returns 1"
_str_wfail=$( ( exec 1</dev/null; str_upper 2>/dev/null; printf '%s' "$?" >&3 ) 3>&1 )
_test_assert_write_failure "$_str_wfail" "str_upper: no-argument write failure returns 1"
_str_wfail=$( ( exec 1</dev/null; str_len 2>/dev/null; printf '%s' "$?" >&3 ) 3>&1 )
_test_assert_write_failure "$_str_wfail" "str_len: no-argument write failure returns 1"
_str_wfail=$( ( exec 1</dev/null; str_len_bytes 2>/dev/null; printf '%s' "$?" >&3 ) 3>&1 )
_test_assert_write_failure "$_str_wfail" "str_len_bytes: no-argument write failure returns 1"

# Successful calls keep stderr empty.
_err=$(str_trim "  a  " 2>&1 >/dev/null)
assert_eq "" "$_err" "str_trim: success writes nothing to stderr"
_err=$(str_lower A 2>&1 >/dev/null)
assert_eq "" "$_err" "str_lower: success writes nothing to stderr"
_err=$(str_upper a 2>&1 >/dev/null)
assert_eq "" "$_err" "str_upper: success writes nothing to stderr"
_err=$(str_len abc 2>&1 >/dev/null)
assert_eq "" "$_err" "str_len: success writes nothing to stderr"
_err=$(str_len_bytes abc 2>&1 >/dev/null)
assert_eq "" "$_err" "str_len_bytes: success writes nothing to stderr"
_err=$(str_replace a b a 2>&1 >/dev/null)
assert_eq "" "$_err" "str_replace: success writes nothing to stderr"

# M3: str_len must distinguish invalid UTF-8 from an awk execution failure.
(
	_out=$(str_len "España" 2>/dev/null)
	_st=$?
	_err=$(str_len "España" 2>&1 >/dev/null)
	[ "$_st" -eq 0 ] && [ "$_out" = "6" ] && [ -z "$_err" ]
)
assert_true $? "str_len: valid UTF-8 returns the count with empty stderr"

(
	_out=$(str_len "$_str_invalid_truncated" 2>/dev/null)
	_st=$?
	_err=$(str_len "$_str_invalid_truncated" 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ "$_err" = "poshli: str_len: input is not valid UTF-8" ]
)
assert_true $? "str_len: invalid UTF-8 uses the UTF-8 diagnostic"

(
	_test_shim_awk fail
	_out=$(str_len hello 2>/dev/null)
	_st=$?
	_err=$(str_len hello 2>&1 >/dev/null)
	[ "$_st" -eq 1 ] && [ -z "$_out" ] && [ "$_err" = "poshli: str_len: could not count code points" ]
)
assert_true $? "str_len: awk failure uses the awk diagnostic"

(
	_test_shim_awk fail
	_err=$(str_len hello 2>&1 >/dev/null)
	case "$_err" in
		*"input is not valid UTF-8"*) exit 1 ;;
		*) exit 0 ;;
	esac
)
assert_true $? "str_len: awk failure does not use the UTF-8 diagnostic"

(
	_test_shim_awk partial
	_err=$(str_len hello 2>&1 >/dev/null)
	[ "$_err" = "poshli: str_len: could not count code points" ]
)
assert_true $? "str_len: failing awk with partial output uses the awk diagnostic"

unset _str_wfail _out _st _err

test_summary
