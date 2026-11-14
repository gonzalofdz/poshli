#!/bin/sh
#
# POSHLI - Unit tests for encoding.sh
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

# Argument count validation
encoding_base64_encode; assert_status 2 $? "encoding_base64_encode requires argument (status 2)"
encoding_base64_decode; assert_status 2 $? "encoding_base64_decode requires argument (status 2)"

# Backend detection is lazy, and a failed detection is memoized
_b64_marker="${TMPDIR:-/tmp}/poshli_b64_probe.$$"
rm -f "$_b64_marker"

(
	unset _POSHLI_LOADED _POSHLI_ENCODING_LOADED _poshli_base64_dec_flag
	base64() { printf x >> "$_b64_marker"; return 1; }
	. "$_poshli_encoding_test_lib"
	[ ! -f "$_b64_marker" ]
)
assert_true $? "encoding.sh: sourcing does not execute base64"

(
	unset _POSHLI_LOADED _POSHLI_ENCODING_LOADED _poshli_base64_dec_flag
	base64() { printf x >> "$_b64_marker"; return 1; }
	. "$_poshli_encoding_test_lib"
	encoding_base64_decode "QQ==" 2>/dev/null
	encoding_base64_decode "QQ==" 2>/dev/null
	[ "$(cat "$_b64_marker")" = "xx" ]
)
assert_true $? "encoding_base64_decode: failed backend detection is memoized"
rm -f "$_b64_marker"
unset _b64_marker _poshli_encoding_test_lib

# Known Base64 vectors
res=$(encoding_base64_encode "String"); assert_eq "U3RyaW5n" "$res" "encoding_base64_encode: known vector"
res=$(encoding_base64_decode "U3RyaW5n"); assert_eq "String" "$res" "encoding_base64_decode: known vector"
res=$(encoding_base64_encode ""); assert_eq "" "$res" "encoding_base64_encode: empty string"
res=$(encoding_base64_encode "hello world"); assert_eq "aGVsbG8gd29ybGQ=" "$res" "encoding_base64_encode: hello world"
res=$(encoding_base64_decode "aGVsbG8gd29ybGQ="); assert_eq "hello world" "$res" "encoding_base64_decode: hello world"
res=$(encoding_base64_decode "YWE="); assert_eq "aa" "$res" "encoding_base64_decode: canonical padding (one =)"
res=$(encoding_base64_decode "Yg=="); assert_eq "b" "$res" "encoding_base64_decode: canonical padding (two ==)"

# Extra arguments are ignored (conceptually a single string)
res=$(encoding_base64_encode "a" "b"); assert_eq "YQ==" "$res" "encoding_base64_encode: extra arguments ignored"
res=$(encoding_base64_decode "YQ==" "extra"); assert_eq "a" "$res" "encoding_base64_decode: extra arguments ignored"

# Empty input is valid for strict decode and produces no output
res=$(encoding_base64_decode ""); assert_status 0 $? "encoding_base64_decode: empty string status"
assert_eq "" "$res" "encoding_base64_decode: empty string produces no output"

# UTF-8 content survives a round trip
res=$(encoding_base64_encode "España"); assert_eq "RXNwYcOxYQ==" "$res" "encoding_base64_encode: UTF-8"
res=$(encoding_base64_decode "$res"); assert_eq "España" "$res" "encoding_base64_decode: UTF-8 round trip"

# GNU base64 wraps its output at 76 columns; the function must return one line
_long_str="The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog."
res=$(encoding_base64_encode "$_long_str")
_long_stripped=$(printf '%s\n' "$res" | tr -d '\n')
assert_eq "$res" "$_long_stripped" "encoding_base64_encode: long input is a single line"
res=$(encoding_base64_decode "$res"); assert_eq "$_long_str" "$res" "encoding_base64_decode: long input round trip"
unset _long_str _long_stripped

# Strict validation rejects non-RFC 4648 / ambiguous forms and produces no output
for _poshli_b64_bad in \
	"!!!not-base64!!!" \
	"YWJj defg" \
	"YWJj
ZGVm" \
	"YW-j" \
	"YW_j" \
	"YQ" \
	"YWI" \
	"AB==" \
	"AAB=" \
	"YWJ=" \
	"====" \
	"A===" \
	"AA=A" \
	"A==A" \
	"=AAA" \
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
