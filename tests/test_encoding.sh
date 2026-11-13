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
base64_enc; assert_status 2 $? "base64_enc requires argument (status 2)"
base64_dec; assert_status 2 $? "base64_dec requires argument (status 2)"

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
	base64_dec "QQ==" 2>/dev/null
	base64_dec "QQ==" 2>/dev/null
	[ "$(cat "$_b64_marker")" = "xx" ]
)
assert_true $? "base64_dec: failed backend detection is memoized"
rm -f "$_b64_marker"
unset _b64_marker _poshli_encoding_test_lib

# Known Base64 vectors
res=$(base64_enc "String"); assert_eq "U3RyaW5n" "$res" "base64_enc: known vector"
res=$(base64_dec "U3RyaW5n"); assert_eq "String" "$res" "base64_dec: known vector"
res=$(base64_enc ""); assert_eq "" "$res" "base64_enc: empty string"
res=$(base64_enc "hello world"); assert_eq "aGVsbG8gd29ybGQ=" "$res" "base64_enc: hello world"
res=$(base64_dec "aGVsbG8gd29ybGQ="); assert_eq "hello world" "$res" "base64_dec: hello world"
res=$(base64_dec "YWE="); assert_eq "aa" "$res" "base64_dec: canonical padding (one =)"
res=$(base64_dec "Yg=="); assert_eq "b" "$res" "base64_dec: canonical padding (two ==)"

# Extra arguments are ignored (conceptually a single string)
res=$(base64_enc "a" "b"); assert_eq "YQ==" "$res" "base64_enc: extra arguments ignored"
res=$(base64_dec "YQ==" "extra"); assert_eq "a" "$res" "base64_dec: extra arguments ignored"

# Empty input is valid for strict decode and produces no output
res=$(base64_dec ""); assert_status 0 $? "base64_dec: empty string status"
assert_eq "" "$res" "base64_dec: empty string produces no output"

# UTF-8 content survives a round trip
res=$(base64_enc "España"); assert_eq "RXNwYcOxYQ==" "$res" "base64_enc: UTF-8"
res=$(base64_dec "$res"); assert_eq "España" "$res" "base64_dec: UTF-8 round trip"

# GNU base64 wraps its output at 76 columns; the function must return one line
_long_str="The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog."
res=$(base64_enc "$_long_str")
_long_stripped=$(printf '%s\n' "$res" | tr -d '\n')
assert_eq "$res" "$_long_stripped" "base64_enc: long input is a single line"
res=$(base64_dec "$res"); assert_eq "$_long_str" "$res" "base64_dec: long input round trip"
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
	_poshli_b64_out=$(base64_dec "$_poshli_b64_bad" 2>/dev/null)
	_poshli_b64_status=$?
	assert_status 1 "$_poshli_b64_status" "base64_dec rejects invalid input: $_poshli_b64_bad"
	assert_eq "" "$_poshli_b64_out" "base64_dec produces no output on invalid input: $_poshli_b64_bad"
done
unset _poshli_b64_bad _poshli_b64_out _poshli_b64_status

test_summary
