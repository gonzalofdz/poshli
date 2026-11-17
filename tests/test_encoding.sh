#!/bin/sh
#
# POSHLI - Unit tests for encoding.sh
#
# SPDX-License-Identifier: LGPL-3.0-only
# Copyright (C) 2017-2018, 2026 Luis Gonzalo Fernández-Díez <humanogonzalo@gmail.com>
# This file is part of POSHLI. See LICENSE for the full license text.
#

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
. "$TEST_DIR/test_runner.sh"

if [ -n "$POSHLI_TEST_BUNDLE" ]; then
	_poshli_encoding_test_lib="$TEST_DIR/../poshli.sh"
else
	_poshli_encoding_test_lib="$TEST_DIR/../src/encoding.sh"
fi
. "$_poshli_encoding_test_lib"

printf '\n--- Running encoding.sh tests ---\n'

# Byte-exact comparison helper: hex text of stdin bytes. Command substitution
# strips trailing newlines and cannot hold NUL, so results that must be
# compared byte for byte are compared as hex instead of captured directly.
_b64_hex() {
	od -A n -v -t x1 | tr -d ' \n'
}

# Argument count validation
encoding_base64_encode; assert_status 2 $? "encoding_base64_encode requires argument (status 2)"
encoding_base64_decode; assert_status 2 $? "encoding_base64_decode requires argument (status 2)"

# The POSIX implementation must never invoke an external base64 utility:
# a base64() shim would record every call in a marker file and fail.
_b64_marker="${TMPDIR:-/tmp}/poshli_b64_probe_$$"
rm -f "$_b64_marker"

(
	unset _POSHLI_LOADED _POSHLI_ENCODING_LOADED
	base64() { printf x >> "$_b64_marker"; return 1; }
	. "$_poshli_encoding_test_lib"
	[ ! -f "$_b64_marker" ] &&
		[ "$(encoding_base64_encode "String")" = "U3RyaW5n" ] &&
		[ "$(encoding_base64_decode "U3RyaW5n")" = "String" ] &&
		[ ! -f "$_b64_marker" ]
)
assert_true $? "encoding.sh: no external base64 is used at load time or at run time"

(
	unset _POSHLI_LOADED _POSHLI_ENCODING_LOADED
	base64() { printf x >> "$_b64_marker"; return 1; }
	. "$_poshli_encoding_test_lib"
	encoding_base64_decode "!!!bad!!!" 2>/dev/null
	[ $? -eq 1 ] && [ ! -f "$_b64_marker" ]
)
assert_true $? "encoding_base64_decode: invalid input needs no external base64 either"
rm -f "$_b64_marker"
unset _b64_marker _poshli_encoding_test_lib

# RFC 4648 test vectors (fixed expectations, no external tool involved)
res=$(encoding_base64_encode ""); assert_eq "" "$res" "encoding_base64_encode: RFC 4648 vector empty"
res=$(encoding_base64_encode "f"); assert_eq "Zg==" "$res" "encoding_base64_encode: RFC 4648 vector f"
res=$(encoding_base64_encode "fo"); assert_eq "Zm8=" "$res" "encoding_base64_encode: RFC 4648 vector fo"
res=$(encoding_base64_encode "foo"); assert_eq "Zm9v" "$res" "encoding_base64_encode: RFC 4648 vector foo"
res=$(encoding_base64_encode "foob"); assert_eq "Zm9vYg==" "$res" "encoding_base64_encode: RFC 4648 vector foob"
res=$(encoding_base64_encode "fooba"); assert_eq "Zm9vYmE=" "$res" "encoding_base64_encode: RFC 4648 vector fooba"
res=$(encoding_base64_encode "foobar"); assert_eq "Zm9vYmFy" "$res" "encoding_base64_encode: RFC 4648 vector foobar"

res=$(encoding_base64_decode "Zg=="); assert_eq "f" "$res" "encoding_base64_decode: RFC 4648 vector f"
res=$(encoding_base64_decode "Zm8="); assert_eq "fo" "$res" "encoding_base64_decode: RFC 4648 vector fo"
res=$(encoding_base64_decode "Zm9v"); assert_eq "foo" "$res" "encoding_base64_decode: RFC 4648 vector foo"
res=$(encoding_base64_decode "Zm9vYg=="); assert_eq "foob" "$res" "encoding_base64_decode: RFC 4648 vector foob"
res=$(encoding_base64_decode "Zm9vYmE="); assert_eq "fooba" "$res" "encoding_base64_decode: RFC 4648 vector fooba"
res=$(encoding_base64_decode "Zm9vYmFy"); assert_eq "foobar" "$res" "encoding_base64_decode: RFC 4648 vector foobar"

# Known Base64 vectors
res=$(encoding_base64_encode "String"); assert_eq "U3RyaW5n" "$res" "encoding_base64_encode: known vector"
res=$(encoding_base64_decode "U3RyaW5n"); assert_eq "String" "$res" "encoding_base64_decode: known vector"
res=$(encoding_base64_encode "hello world"); assert_eq "aGVsbG8gd29ybGQ=" "$res" "encoding_base64_encode: hello world"
res=$(encoding_base64_decode "aGVsbG8gd29ybGQ="); assert_eq "hello world" "$res" "encoding_base64_decode: hello world"
res=$(encoding_base64_decode "YWE="); assert_eq "aa" "$res" "encoding_base64_decode: canonical padding (one =)"
res=$(encoding_base64_decode "Yg=="); assert_eq "b" "$res" "encoding_base64_decode: canonical padding (two ==)"
res=$(encoding_base64_decode "YWJj"); assert_eq "abc" "$res" "encoding_base64_decode: full group needs no padding"

# Spaces and special characters are plain data
res=$(encoding_base64_encode " "); assert_eq "IA==" "$res" "encoding_base64_encode: single space"
res=$(encoding_base64_encode "a b	c"); assert_eq "YSBiCWM=" "$res" "encoding_base64_encode: spaces and tab"
res=$(encoding_base64_encode "a\\b%c"); assert_eq "YVxiJWM=" "$res" "encoding_base64_encode: backslash and percent"
res=$(encoding_base64_encode '$(id) `id` ${x}'); assert_eq "JChpZCkgYGlkYCAke3h9" "$res" "encoding_base64_encode: metacharacters are data"
res=$(encoding_base64_encode "-n"); assert_eq "LW4=" "$res" "encoding_base64_encode: leading hyphen"

# Extra arguments are ignored (conceptually a single string)
res=$(encoding_base64_encode "a" "b"); assert_eq "YQ==" "$res" "encoding_base64_encode: extra arguments ignored"
res=$(encoding_base64_decode "YQ==" "extra"); assert_eq "a" "$res" "encoding_base64_decode: extra arguments ignored"

# Empty input is valid for both directions and produces no output
res=$(encoding_base64_encode ""); assert_status 0 $? "encoding_base64_encode: empty string status"
assert_eq "" "$res" "encoding_base64_encode: empty string"
res=$(encoding_base64_decode ""); assert_status 0 $? "encoding_base64_decode: empty string status"
assert_eq "" "$res" "encoding_base64_decode: empty string produces no output"

# UTF-8 content survives a round trip
res=$(encoding_base64_encode "España"); assert_eq "RXNwYcOxYQ==" "$res" "encoding_base64_encode: UTF-8"
res=$(encoding_base64_decode "$res"); assert_eq "España" "$res" "encoding_base64_decode: UTF-8 round trip"
res=$(encoding_base64_encode "你好😀"); assert_eq "5L2g5aW98J+YgA==" "$res" "encoding_base64_encode: UTF-8 emoji"
res=$(encoding_base64_decode "$res"); assert_eq "你好😀" "$res" "encoding_base64_decode: UTF-8 emoji round trip"

# Output format: exactly the Base64 text, one unwrapped line, no trailing
# newline (byte-exact through od).
_hx=$(encoding_base64_encode "String" | _b64_hex)
assert_eq "553352796157356e" "$_hx" "encoding_base64_encode: no trailing newline (od compare)"
_hx=$(encoding_base64_decode "YQ==" | _b64_hex)
assert_eq "61" "$_hx" "encoding_base64_decode: raw bytes, no trailing newline (od compare)"

# The encoder must not wrap long output at 76 columns; the result is a
# single line.
_long_str="The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog."
res=$(encoding_base64_encode "$_long_str")
_long_stripped=$(printf '%s\n' "$res" | tr -d '\n')
assert_eq "$res" "$_long_stripped" "encoding_base64_encode: long input is a single line"
res=$(encoding_base64_decode "$res"); assert_eq "$_long_str" "$res" "encoding_base64_decode: long input round trip"
unset _long_str _long_stripped

# Decoded output is raw bytes: NUL and newline bytes are written unchanged
# (compared as hex because $(...) cannot hold them).
_hx=$(encoding_base64_decode "AAAA" | _b64_hex)
assert_eq "000000" "$_hx" "encoding_base64_decode: NUL bytes are written unchanged (od compare)"
_hx=$(encoding_base64_decode "AAA=" | _b64_hex)
assert_eq "0000" "$_hx" "encoding_base64_decode: NUL bytes with one = (od compare)"
_hx=$(encoding_base64_decode "Cg==" | _b64_hex)
assert_eq "0a" "$_hx" "encoding_base64_decode: newline byte is written unchanged (od compare)"
_hx=$(encoding_base64_decode "/4B4" | _b64_hex)
assert_eq "ff8078" "$_hx" "encoding_base64_decode: bytes above 0x7F (od compare)"

# Repeated data: without "od -v", repeated od lines are elided with "*" and
# the encoding silently corrupts. 200 identical bytes catch that.
_m200=""
_i=0
while [ "$_i" -lt 200 ]; do _m200="${_m200}m"; _i=$((_i + 1)); done
_exp=""
_i=0
while [ "$_i" -lt 66 ]; do _exp="${_exp}bW1t"; _i=$((_i + 1)); done
_exp="${_exp}bW0="
res=$(encoding_base64_encode "$_m200")
assert_eq "$_exp" "$res" "encoding_base64_encode: 200 identical bytes (od -v, no elision)"
res=$(encoding_base64_decode "$res")
assert_eq "$_m200" "$res" "encoding_base64_decode: 200 identical bytes round trip"
unset _m200 _exp _i

# Failure simulations for the od/wc validation. POSIX pipelines report the
# status of their last command only, so od failing could be hidden by awk
# succeeding: the encoder validates what od actually produced instead (the wc
# byte count and the od field values in awk) before printing any Base64.
# Each simulation runs in its own subshell so the shims cannot leak into the
# rest of the suite, and a fake od that needs the real od calls it through
# "command od". Two conditions per scenario: return status exactly 1 and not
# a single byte on stdout. These simulations need no external base64 utility:
# a base64() shim records every call in a marker file that must never appear.
_poshli_b64_scen_out="${TMPDIR:-/tmp}/poshli_b64_scen_out.$$"
_poshli_b64_scen_marker="${TMPDIR:-/tmp}/poshli_b64_scen_probe.$$"
rm -f "$_poshli_b64_scen_out" "$_poshli_b64_scen_marker"
base64() { printf x >> "$_poshli_b64_scen_marker"; return 1; }

# 100-byte input: large enough that "head -n 2" below keeps only 32 of its
# bytes (od writes 16 bytes per line), so the output is genuinely partial.
_poshli_b64_in100="0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"

# 1) od fails producing no output at all.
_poshli_b64_st=$( (
	od() { return 1; }
	encoding_base64_encode "$_poshli_b64_in100" > "$_poshli_b64_scen_out"
	printf '%s' "$?"
) )
assert_status 1 "$_poshli_b64_st" "encoding_base64_encode: od failing with no output returns 1"
[ ! -s "$_poshli_b64_scen_out" ]; assert_true $? "encoding_base64_encode: od failing with no output emits no output"

# 2) od fails after emitting partial output.
_poshli_b64_st=$( (
	od() { command od "$@" | head -n 2; return 1; }
	encoding_base64_encode "$_poshli_b64_in100" > "$_poshli_b64_scen_out"
	printf '%s' "$?"
) )
assert_status 1 "$_poshli_b64_st" "encoding_base64_encode: od failing after partial output returns 1"
[ ! -s "$_poshli_b64_scen_out" ]; assert_true $? "encoding_base64_encode: od failing after partial output emits no output"

# 3) od emits truncated output but reports success.
_poshli_b64_st=$( (
	od() { command od "$@" | head -n 2; return 0; }
	encoding_base64_encode "$_poshli_b64_in100" > "$_poshli_b64_scen_out"
	printf '%s' "$?"
) )
assert_status 1 "$_poshli_b64_st" "encoding_base64_encode: od truncated with status 0 returns 1"
[ ! -s "$_poshli_b64_scen_out" ]; assert_true $? "encoding_base64_encode: od truncated with status 0 emits no output"

# 4) od ignores -v: repeated od lines are elided with "*", so fewer bytes
# come back than were sent. 200 identical bytes force the elision.
_poshli_b64_m200=""
_poshli_b64_i=0
while [ "$_poshli_b64_i" -lt 200 ]; do _poshli_b64_m200="${_poshli_b64_m200}m"; _poshli_b64_i=$((_poshli_b64_i + 1)); done
_poshli_b64_st=$( (
	od() { command od -A n -t u1; }
	encoding_base64_encode "$_poshli_b64_m200" > "$_poshli_b64_scen_out"
	printf '%s' "$?"
) )
assert_status 1 "$_poshli_b64_st" "encoding_base64_encode: od ignoring -v (elided repeats) returns 1"
[ ! -s "$_poshli_b64_scen_out" ]; assert_true $? "encoding_base64_encode: od ignoring -v (elided repeats) emits no output"

# 5a) od emits a value outside the byte range. The field count matches the 3
# expected bytes on purpose: only the value check can catch this case.
_poshli_b64_st=$( (
	od() { printf ' 97 98 300\n'; }
	encoding_base64_encode "abc" > "$_poshli_b64_scen_out"
	printf '%s' "$?"
) )
assert_status 1 "$_poshli_b64_st" "encoding_base64_encode: od value above 255 returns 1 (count matches, values checked)"
[ ! -s "$_poshli_b64_scen_out" ]; assert_true $? "encoding_base64_encode: od value above 255 emits no output"

# 5b) od emits a non-numeric field. Again the count matches on purpose.
_poshli_b64_st=$( (
	od() { printf ' 97 98 x\n'; }
	encoding_base64_encode "abc" > "$_poshli_b64_scen_out"
	printf '%s' "$?"
) )
assert_status 1 "$_poshli_b64_st" "encoding_base64_encode: od non-numeric field returns 1 (count matches, values checked)"
[ ! -s "$_poshli_b64_scen_out" ]; assert_true $? "encoding_base64_encode: od non-numeric field emits no output"

# 5c) od emits more bytes than the input has.
_poshli_b64_st=$( (
	od() { printf ' 97 98 99 100\n'; }
	encoding_base64_encode "abc" > "$_poshli_b64_scen_out"
	printf '%s' "$?"
) )
assert_status 1 "$_poshli_b64_st" "encoding_base64_encode: od extra bytes return 1 (count mismatch)"
[ ! -s "$_poshli_b64_scen_out" ]; assert_true $? "encoding_base64_encode: od extra bytes emit no output"

# 6) wc is not available.
_poshli_b64_st=$( (
	wc() { return 127; }
	encoding_base64_encode "$_poshli_b64_in100" > "$_poshli_b64_scen_out"
	printf '%s' "$?"
) )
assert_status 1 "$_poshli_b64_st" "encoding_base64_encode: missing wc returns 1"
[ ! -s "$_poshli_b64_scen_out" ]; assert_true $? "encoding_base64_encode: missing wc emits no output"

# 7) wc reports a byte count that contradicts od.
_poshli_b64_st=$( (
	wc() { printf '3\n'; }
	encoding_base64_encode "$_poshli_b64_in100" > "$_poshli_b64_scen_out"
	printf '%s' "$?"
) )
assert_status 1 "$_poshli_b64_st" "encoding_base64_encode: wrong wc count returns 1"
[ ! -s "$_poshli_b64_scen_out" ]; assert_true $? "encoding_base64_encode: wrong wc count emits no output"

[ ! -f "$_poshli_b64_scen_marker" ]; assert_true $? "encoding.sh: failure simulations never call an external base64"
rm -f "$_poshli_b64_scen_out" "$_poshli_b64_scen_marker"
unset -f base64
unset _poshli_b64_scen_out _poshli_b64_scen_marker _poshli_b64_in100 _poshli_b64_m200 _poshli_b64_i _poshli_b64_st

# Write failures of the final printf must not be hidden by the trailing
# unset that cleans the temporaries: the function must return a non-zero
# status and clean up anyway. stdout is closed for the call so the write
# cannot succeed; each simulation runs in its own subshell and reports the
# observed status. A leaked temporary turns the reported status into a
# sentinel 9, so the assertions cover return code and cleanup at once.
_poshli_b64_wfail_st=$( (
	encoding_base64_encode "abc" >&- 2>/dev/null
	_st=$?
	[ -z "${_poshli_base64_out+x}${_poshli_b64_want+x}" ] || _st=9
	printf '%s' "$_st"
) )
assert_status 1 "$_poshli_b64_wfail_st" "encoding_base64_encode: printf write failure returns 1 (not hidden by unset) and cleans temporaries"

_poshli_b64_wfail_st=$( (
	encoding_base64_decode "YWJj" >&- 2>/dev/null
	_st=$?
	[ -z "${_poshli_b64_esc+x}" ] || _st=9
	printf '%s' "$_st"
) )
assert_status 1 "$_poshli_b64_wfail_st" "encoding_base64_decode: printf write failure returns 1 (not hidden by unset) and cleans temporaries"

# Temporaries are cleaned on the success path as well.
(
	encoding_base64_encode "abc" > /dev/null &&
	encoding_base64_decode "YWJj" > /dev/null &&
	[ -z "${_poshli_base64_out+x}" ] &&
	[ -z "${_poshli_b64_want+x}" ] &&
	[ -z "${_poshli_b64_esc+x}" ]
)
assert_true $? "encoding.sh: temporaries are cleaned on success"

# Temporaries are also cleaned when the awk stage fails (invalid or
# unavailable awk output paths), not only when the final printf fails.
_poshli_b64_wfail_st=$( (
	awk() { return 1; }
	encoding_base64_encode "abc" > /dev/null 2>&1
	_st=$?
	[ -z "${_poshli_base64_out+x}${_poshli_b64_want+x}" ] || _st=9
	printf '%s' "$_st"
) )
assert_status 1 "$_poshli_b64_wfail_st" "encoding_base64_encode: awk failure returns 1 and cleans temporaries"

_poshli_b64_wfail_st=$( (
	awk() { return 1; }
	encoding_base64_decode "YWJj" > /dev/null 2>&1
	_st=$?
	[ -z "${_poshli_b64_esc+x}" ] || _st=9
	printf '%s' "$_st"
) )
assert_status 1 "$_poshli_b64_wfail_st" "encoding_base64_decode: awk failure returns 1 and cleans temporaries"
unset _poshli_b64_wfail_st

# Round trips: original -> encode -> decode -> original, byte-exact.
for _poshli_b64_rt in \
	"" \
	"a" \
	"ab" \
	"abc" \
	"abcd" \
	"hello world" \
	"España" \
	"你好😀" \
	"a b	c" \
	'a\b%c $(id) `id` ${x} %s %b' \
	"-n"
do
	_poshli_b64_enc=$(encoding_base64_encode "$_poshli_b64_rt")
	_poshli_b64_hx=$(encoding_base64_decode "$_poshli_b64_enc" | _b64_hex)
	assert_eq "$(printf '%s' "$_poshli_b64_rt" | _b64_hex)" "$_poshli_b64_hx" "round trip: $_poshli_b64_rt"
done

# Round trip with an embedded newline (kept verbatim by command substitution).
_rt_nl="a
b"
_poshli_b64_enc=$(encoding_base64_encode "$_rt_nl")
assert_eq "YQpi" "$_poshli_b64_enc" "encoding_base64_encode: embedded newline"
_poshli_b64_hx=$(encoding_base64_decode "$_poshli_b64_enc" | _b64_hex)
assert_eq "610a62" "$_poshli_b64_hx" "round trip: embedded newline (od compare)"

# Round trip with a trailing newline. A shell variable keeps it, $(...) does
# not: the input side encodes it byte-exact...
_rt_trail="abc
"
assert_eq "YWJjCg==" "$(encoding_base64_encode "$_rt_trail")" "encoding_base64_encode: input with trailing newline is encoded byte-exact"
# ...and the decoded bytes are exact when compared with od ...
_hx=$(encoding_base64_decode "YWJjCg==" | _b64_hex)
assert_eq "6162630a" "$_hx" "encoding_base64_decode: trailing newline byte is written unchanged (od compare)"
# ...but this documents the capture limit: $(...) strips trailing newlines,
# so a round trip observed through $(...) loses them. This is a limit of
# command substitution, not of the Base64 encoding.
res=$(encoding_base64_decode "YWJjCg==")
assert_eq "abc" "$res" "documented limit: \$(...) strips trailing newlines from captured output"
unset _rt_nl _rt_trail _poshli_b64_rt _poshli_b64_enc _poshli_b64_hx _hx

# Binary data. A shell argument cannot hold NUL (0x00): shell variables and
# $(...) drop it, so the encoder cannot be tested with a NUL byte. That is a
# limit of the shell string API, not of the Base64 encoding. The encoder is
# tested here with every other byte value (1..255), and the decoder is tested
# with all 256 values including NUL further below. The input is built with
# octal escapes in the FORMAT string of a single printf, ending in \377: the
# last byte is not a line break, so the command substitution cannot strip a
# trailing newline from the sequence. Binary results are compared through od
# hex, never as strings, so the comparison cannot alter the data.
_b1_255=$(printf '\001\002\003\004\005\006\007\010\011\012\013\014\015\016\017\020\021\022\023\024\025\026\027\030\031\032\033\034\035\036\037\040\041\042\043\044\045\046\047\050\051\052\053\054\055\056\057\060\061\062\063\064\065\066\067\070\071\072\073\074\075\076\077\100\101\102\103\104\105\106\107\110\111\112\113\114\115\116\117\120\121\122\123\124\125\126\127\130\131\132\133\134\135\136\137\140\141\142\143\144\145\146\147\150\151\152\153\154\155\156\157\160\161\162\163\164\165\166\167\170\171\172\173\174\175\176\177\200\201\202\203\204\205\206\207\210\211\212\213\214\215\216\217\220\221\222\223\224\225\226\227\230\231\232\233\234\235\236\237\240\241\242\243\244\245\246\247\250\251\252\253\254\255\256\257\260\261\262\263\264\265\266\267\270\271\272\273\274\275\276\277\300\301\302\303\304\305\306\307\310\311\312\313\314\315\316\317\320\321\322\323\324\325\326\327\330\331\332\333\334\335\336\337\340\341\342\343\344\345\346\347\350\351\352\353\354\355\356\357\360\361\362\363\364\365\366\367\370\371\372\373\374\375\376\377')
_exp_b64='AQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHyAhIiMkJSYnKCkqKywtLi8wMTIzNDU2Nzg5Ojs8PT4/QEFCQ0RFRkdISUpLTE1OT1BRUlNUVVZXWFlaW1xdXl9gYWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXp7fH1+f4CBgoOEhYaHiImKi4yNjo+QkZKTlJWWl5iZmpucnZ6foKGio6SlpqeoqaqrrK2ur7CxsrO0tba3uLm6u7y9vr/AwcLDxMXGx8jJysvMzc7P0NHS09TV1tfY2drb3N3e3+Dh4uPk5ebn6Onq6+zt7u/w8fLz9PX29/j5+vv8/f7/'
res=$(encoding_base64_encode "$_b1_255")
assert_eq "$_exp_b64" "$res" "encoding_base64_encode: binary bytes 1..255 (fixed vector)"
_exp_hex=""
_i=1
while [ "$_i" -lt 256 ]; do _exp_hex="${_exp_hex}$(printf '%02x' "$_i")"; _i=$((_i + 1)); done
_hx=$(encoding_base64_decode "$res" | _b64_hex)
assert_eq "$_exp_hex" "$_hx" "round trip: binary bytes 1..255 (od compare)"
unset _b1_255 _exp_b64 _exp_hex _i

# The decoder must write all 256 possible byte values unchanged, NUL
# included. The expectation is built value by value and the comparison goes
# through od hex because $(...) cannot hold NUL or preserve the raw bytes.
_dec256='AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYGFiY2RlZmdoaWprbG1ub3BxcnN0dXZ3eHl6e3x9fn+AgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6ChoqOkpaanqKmqq6ytrq+wsbKztLW2t7i5uru8vb6/wMHCw8TFxsfIycrLzM3Oz9DR0tPU1dbX2Nna29zd3t/g4eLj5OXm5+jp6uvs7e7v8PHy8/T19vf4+fr7/P3+/w=='
_exp_hex=""
_i=0
while [ "$_i" -lt 256 ]; do _exp_hex="${_exp_hex}$(printf '%02x' "$_i")"; _i=$((_i + 1)); done
_hx=$(encoding_base64_decode "$_dec256" | _b64_hex)
assert_eq "$_exp_hex" "$_hx" "encoding_base64_decode: all 256 byte values including NUL (od compare)"
unset _dec256 _exp_hex _i _hx

# Strict validation rejects non-RFC 4648 / ambiguous forms and produces no output
for _poshli_b64_bad in \
	"!!!not-base64!!!" \
	"YWJj defg" \
	"YWJj
ZGVm" \
	"$(printf '\t')YWJj" \
	"$(printf 'YQ\r')" \
	" " \
	"YW-j" \
	"YW_j" \
	"YQ" \
	"YWI" \
	"aGVsbG8" \
	"AB==" \
	"AAB=" \
	"YWJ=" \
	"ZZ==" \
	"Zm9=" \
	"AAA==" \
	"====" \
	"A===" \
	"AA===" \
	"AAAAA==" \
	"AA=A" \
	"A==A" \
	"=AAA" \
	"YQ==YQ==" \
	"AA==AAAA" \
	"AAAA=AAA" \
	"AAAA====" \
	"SGVsbG8=SGVs"
do
	_poshli_b64_out=$(encoding_base64_decode "$_poshli_b64_bad" 2>/dev/null)
	_poshli_b64_status=$?
	assert_status 1 "$_poshli_b64_status" "encoding_base64_decode rejects invalid input: $_poshli_b64_bad"
	assert_eq "" "$_poshli_b64_out" "encoding_base64_decode produces no output on invalid input: $_poshli_b64_bad"
done
unset _poshli_b64_bad _poshli_b64_out _poshli_b64_status

test_summary
