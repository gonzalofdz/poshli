#!/bin/sh
#
# POSHLI - Unit tests for num.sh
#
# SPDX-License-Identifier: LGPL-3.0-only
# Copyright (C) 2017-2018, 2026 Luis Gonzalo Fernández-Díez <humanogonzalo@gmail.com>
# This file is part of POSHLI. See LICENSE for the full license text.
#

# Locate test_runner.sh and num.sh
TEST_DIR=$(cd "$(dirname "$0")" && pwd)
. "$TEST_DIR/test_runner.sh"

if [ -n "$POSHLI_TEST_BUNDLE" ]; then
	. "$TEST_DIR/../poshli.sh"
else
	. "$TEST_DIR/../src/num.sh"
fi

printf '\n--- Running num.sh tests ---\n'

# Argument count validation: predicates treat a missing argument as false (status 1);
# num_randomize is operational and reports a missing argument as invalid usage (status 2).
num_is_integer
assert_status 1 $? "num_is_integer without argument is invalid (status 1)"
num_is_natural
assert_status 1 $? "num_is_natural without argument is invalid (status 1)"
num_is_number
assert_status 1 $? "num_is_number without argument is invalid (status 1)"
num_is_hex
assert_status 1 $? "num_is_hex without argument is invalid (status 1)"
num_is_bin
assert_status 1 $? "num_is_bin without argument is invalid (status 1)"
num_is_octal
assert_status 1 $? "num_is_octal without argument is invalid (status 1)"
num_is_bool
assert_status 1 $? "num_is_bool without argument is invalid (status 1)"
num_randomize
assert_status 2 $? "num_randomize requires argument (status 2)"

# Predicates must also return status 1 without arguments under nounset.
(
	set -u
	num_is_integer
)
assert_status 1 $? "num_is_integer without argument under nounset is invalid (status 1)"
(
	set -u
	num_is_natural
)
assert_status 1 $? "num_is_natural without argument under nounset is invalid (status 1)"
(
	set -u
	num_is_number
)
assert_status 1 $? "num_is_number without argument under nounset is invalid (status 1)"
(
	set -u
	num_is_hex
)
assert_status 1 $? "num_is_hex without argument under nounset is invalid (status 1)"
(
	set -u
	num_is_bin
)
assert_status 1 $? "num_is_bin without argument under nounset is invalid (status 1)"
(
	set -u
	num_is_octal
)
assert_status 1 $? "num_is_octal without argument under nounset is invalid (status 1)"
(
	set -u
	num_is_bool
)
assert_status 1 $? "num_is_bool without argument under nounset is invalid (status 1)"

# num_is_integer tests
num_is_integer "42"; assert_true $? "num_is_integer: 42"
num_is_integer "-42"; assert_true $? "num_is_integer: -42"
num_is_integer "+42"; assert_true $? "num_is_integer: +42"
num_is_integer "0012"; assert_true $? "num_is_integer: 0012"
num_is_integer "0"; assert_true $? "num_is_integer: 0"

num_is_integer "+"; assert_status 1 $? "num_is_integer rejects: +"
num_is_integer "-"; assert_status 1 $? "num_is_integer rejects: -"
num_is_integer "12-3"; assert_status 1 $? "num_is_integer rejects: 12-3"
num_is_integer "1+2"; assert_status 1 $? "num_is_integer rejects: 1+2"
num_is_integer "12+"; assert_status 1 $? "num_is_integer rejects: 12+"
num_is_integer "+12+"; assert_status 1 $? "num_is_integer rejects: +12+"
num_is_integer "++1"; assert_status 1 $? "num_is_integer rejects: ++1"
num_is_integer "--1"; assert_status 1 $? "num_is_integer rejects: --1"
num_is_integer ""; assert_status 1 $? "num_is_integer rejects: empty string"
num_is_integer "3.14"; assert_status 1 $? "num_is_integer rejects: 3.14"
num_is_integer " "; assert_status 1 $? "num_is_integer rejects: space"
num_is_integer "abc"; assert_status 1 $? "num_is_integer rejects: abc"

# num_is_natural tests
num_is_natural "0"; assert_true $? "num_is_natural: 0"
num_is_natural "1"; assert_true $? "num_is_natural: 1"
num_is_natural "42"; assert_true $? "num_is_natural: 42"
num_is_natural "0012"; assert_true $? "num_is_natural: 0012"

num_is_natural "-42"; assert_status 1 $? "num_is_natural rejects: -42"
num_is_natural "+42"; assert_status 1 $? "num_is_natural rejects: +42"
num_is_natural "-1"; assert_status 1 $? "num_is_natural rejects: -1"
num_is_natural "+1"; assert_status 1 $? "num_is_natural rejects: +1"
num_is_natural ""; assert_status 1 $? "num_is_natural rejects: empty string"
num_is_natural "3.14"; assert_status 1 $? "num_is_natural rejects: 3.14"
num_is_natural ".5"; assert_status 1 $? "num_is_natural rejects: .5"
num_is_natural "abc"; assert_status 1 $? "num_is_natural rejects: abc"

# num_is_number tests
num_is_number "42"; assert_true $? "num_is_number: 42"
num_is_number "+42"; assert_true $? "num_is_number: +42"
num_is_number "-42"; assert_true $? "num_is_number: -42"
num_is_number "0"; assert_true $? "num_is_number: 0"
num_is_number "0012"; assert_true $? "num_is_number: 0012"
num_is_number "3.14"; assert_true $? "num_is_number: 3.14"
num_is_number "-3.14"; assert_true $? "num_is_number: -3.14"
num_is_number "+0.05"; assert_true $? "num_is_number: +0.05"
num_is_number "100.25"; assert_true $? "num_is_number: 100.25"

# A leading or trailing decimal point is accepted as a valid decimal number
num_is_number ".5"; assert_true $? "num_is_number: .5"
num_is_number "-.5"; assert_true $? "num_is_number: -.5"
num_is_number "+.5"; assert_true $? "num_is_number: +.5"
num_is_number "3."; assert_true $? "num_is_number: 3."
num_is_number "-3."; assert_true $? "num_is_number: -3."

# Scientific notation is not supported
num_is_number "1e10"; assert_status 1 $? "num_is_number rejects: 1e10"
num_is_number "1E10"; assert_status 1 $? "num_is_number rejects: 1E10"
num_is_number "1.5e2"; assert_status 1 $? "num_is_number rejects: 1.5e2"
num_is_number "1.e10"; assert_status 1 $? "num_is_number rejects: 1.e10"
num_is_number ".5E-2"; assert_status 1 $? "num_is_number rejects: .5E-2"
num_is_number "+1e+10"; assert_status 1 $? "num_is_number rejects: +1e+10"
num_is_number "-3E-5"; assert_status 1 $? "num_is_number rejects: -3E-5"
num_is_number "1.2e3"; assert_status 1 $? "num_is_number rejects: 1.2e3"
num_is_number "e10"; assert_status 1 $? "num_is_number rejects: e10"
num_is_number "1e"; assert_status 1 $? "num_is_number rejects: 1e"
num_is_number "1e+"; assert_status 1 $? "num_is_number rejects: 1e+"
num_is_number "1e-"; assert_status 1 $? "num_is_number rejects: 1e-"
num_is_number "1e2e3"; assert_status 1 $? "num_is_number rejects: multiple exponents"
num_is_number "1.2.3e4"; assert_status 1 $? "num_is_number rejects: invalid mantissa"

# Invalid formats
num_is_number "+"; assert_status 1 $? "num_is_number rejects: +"
num_is_number "-"; assert_status 1 $? "num_is_number rejects: -"
num_is_number "12-3"; assert_status 1 $? "num_is_number rejects: 12-3"
num_is_number "1+2"; assert_status 1 $? "num_is_number rejects: 1+2"
num_is_number "12+"; assert_status 1 $? "num_is_number rejects: 12+"
num_is_number "+12+"; assert_status 1 $? "num_is_number rejects: +12+"
num_is_number "++1"; assert_status 1 $? "num_is_number rejects: ++1"
num_is_number "--1"; assert_status 1 $? "num_is_number rejects: --1"
num_is_number ""; assert_status 1 $? "num_is_number rejects: empty string"
num_is_number "."; assert_status 1 $? "num_is_number rejects: ."
num_is_number "-."; assert_status 1 $? "num_is_number rejects: -."
num_is_number "+."; assert_status 1 $? "num_is_number rejects: +."
num_is_number "3.."; assert_status 1 $? "num_is_number rejects: 3.."
num_is_number "1.2.3"; assert_status 1 $? "num_is_number rejects: 1.2.3"
num_is_number "NaN"; assert_status 1 $? "num_is_number rejects: NaN"
num_is_number "Infinity"; assert_status 1 $? "num_is_number rejects: Infinity"
num_is_number " "; assert_status 1 $? "num_is_number rejects: space"
num_is_number "espacio"; assert_status 1 $? "num_is_number rejects: espacio"
num_is_number "abc"; assert_status 1 $? "num_is_number rejects: abc"

# num_is_hex tests
num_is_hex "0"; assert_true $? "num_is_hex: 0"
num_is_hex "1a"; assert_true $? "num_is_hex: 1a"
num_is_hex "DEADBEEF"; assert_true $? "num_is_hex: DEADBEEF"
num_is_hex "0xFF"; assert_true $? "num_is_hex: 0xFF"
num_is_hex "0XFF"; assert_true $? "num_is_hex: 0XFF"
num_is_hex "0x10"; assert_true $? "num_is_hex: 0x10"
num_is_hex "abc"; assert_true $? "num_is_hex: abc"
num_is_hex "0b101"; assert_true $? "num_is_hex: 0b101"

num_is_hex ""; assert_status 1 $? "num_is_hex rejects: empty string"
num_is_hex "0x"; assert_status 1 $? "num_is_hex rejects: 0x"
num_is_hex "0X"; assert_status 1 $? "num_is_hex rejects: 0X"
num_is_hex "12G"; assert_status 1 $? "num_is_hex rejects: 12G"
num_is_hex "xyz"; assert_status 1 $? "num_is_hex rejects: xyz"
num_is_hex "0x0x1"; assert_status 1 $? "num_is_hex rejects: 0x0x1"

# num_is_bin tests
num_is_bin "0"; assert_true $? "num_is_bin: 0"
num_is_bin "1"; assert_true $? "num_is_bin: 1"
num_is_bin "10110"; assert_true $? "num_is_bin: 10110"
num_is_bin "0b1010"; assert_true $? "num_is_bin: 0b1010"
num_is_bin "0B1"; assert_true $? "num_is_bin: 0B1"

num_is_bin ""; assert_status 1 $? "num_is_bin rejects: empty string"
num_is_bin "0b"; assert_status 1 $? "num_is_bin rejects: 0b"
num_is_bin "0B"; assert_status 1 $? "num_is_bin rejects: 0B"
num_is_bin "102"; assert_status 1 $? "num_is_bin rejects: 102"
num_is_bin "abc"; assert_status 1 $? "num_is_bin rejects: abc"
num_is_bin "0b0b1"; assert_status 1 $? "num_is_bin rejects: 0b0b1"

# num_is_octal tests
num_is_octal "0"; assert_true $? "num_is_octal: 0"
num_is_octal "7"; assert_true $? "num_is_octal: 7"
num_is_octal "755"; assert_true $? "num_is_octal: 755"
num_is_octal "0777"; assert_true $? "num_is_octal: 0777"
num_is_octal "0o755"; assert_true $? "num_is_octal: 0o755"
num_is_octal "0O755"; assert_true $? "num_is_octal: 0O755"

num_is_octal ""; assert_status 1 $? "num_is_octal rejects: empty string"
num_is_octal "0o"; assert_status 1 $? "num_is_octal rejects: 0o"
num_is_octal "0O"; assert_status 1 $? "num_is_octal rejects: 0O"
num_is_octal "8"; assert_status 1 $? "num_is_octal rejects: 8"
num_is_octal "09"; assert_status 1 $? "num_is_octal rejects: 09"
num_is_octal "0o8"; assert_status 1 $? "num_is_octal rejects: 0o8"
num_is_octal "0o0o1"; assert_status 1 $? "num_is_octal rejects: 0o0o1"

# Non-ASCII digits are never accepted, regardless of locale or shell
num_is_integer "١٢"; assert_status 1 $? "num_is_integer rejects: Arabic-Indic digits"
num_is_natural "١٢"; assert_status 1 $? "num_is_natural rejects: Arabic-Indic digits"
num_is_number "١٢.٥"; assert_status 1 $? "num_is_number rejects: Arabic-Indic digits"
num_is_hex "١a"; assert_status 1 $? "num_is_hex rejects: Arabic-Indic digit"
num_is_octal "١"; assert_status 1 $? "num_is_octal rejects: Arabic-Indic digit"
num_is_integer "１２"; assert_status 1 $? "num_is_integer rejects: fullwidth digits"

# num_is_bool tests
num_is_bool "0"; assert_true $? "num_is_bool: 0"
num_is_bool "1"; assert_true $? "num_is_bool: 1"

num_is_bool "true"; assert_true $? "num_is_bool: true"
num_is_bool "TRUE"; assert_true $? "num_is_bool: TRUE"
num_is_bool "True"; assert_true $? "num_is_bool: True"
num_is_bool "tRuE"; assert_true $? "num_is_bool: tRuE"

num_is_bool "false"; assert_true $? "num_is_bool: false"
num_is_bool "FALSE"; assert_true $? "num_is_bool: FALSE"
num_is_bool "False"; assert_true $? "num_is_bool: False"
num_is_bool "fAlSe"; assert_true $? "num_is_bool: fAlSe"

num_is_bool ""; assert_status 1 $? "num_is_bool rejects: empty string"
num_is_bool "yes"; assert_status 1 $? "num_is_bool rejects: yes"
num_is_bool "no"; assert_status 1 $? "num_is_bool rejects: no"
num_is_bool "on"; assert_status 1 $? "num_is_bool rejects: on"
num_is_bool "off"; assert_status 1 $? "num_is_bool rejects: off"
num_is_bool "y"; assert_status 1 $? "num_is_bool rejects: y"
num_is_bool "n"; assert_status 1 $? "num_is_bool rejects: n"
num_is_bool "2"; assert_status 1 $? "num_is_bool rejects: 2"
num_is_bool "-1"; assert_status 1 $? "num_is_bool rejects: -1"

# num_randomize tests
num_randomize 0; assert_status 1 $? "num_randomize rejects limit 0 (status 1)"
num_randomize -1; assert_status 1 $? "num_randomize rejects negative limit (status 1)"
num_randomize abc; assert_status 1 $? "num_randomize rejects non-natural limit (status 1)"
num_randomize 1.5; assert_status 1 $? "num_randomize rejects decimal limit (status 1)"
num_randomize ""; assert_status 1 $? "num_randomize rejects empty limit (status 1)"

# Valid limit: prints a natural number below the limit
res=$(num_randomize 5); assert_true $? "num_randomize 5 succeeds"
num_is_natural "$res"; assert_true $? "num_randomize 5 prints a natural number"
[ "$res" -lt 5 ]; assert_true $? "num_randomize 5 result is below the limit"

# Result always stays within [0, limit) over repeated calls
_i=0
_rand_ok=0
while [ "$_i" -lt 20 ]; do
	_r=$(num_randomize 10)
	num_is_natural "$_r" && [ "$_r" -lt 10 ] && _rand_ok=$((_rand_ok + 1))
	_i=$((_i + 1))
done
assert_eq 20 "$_rand_ok" "num_randomize: 20 results all within [0, 10)"
unset _i _rand_ok _r

# Limit 1 can only produce 0
_i=0
_rand_one=0
while [ "$_i" -lt 10 ]; do
	_r=$(num_randomize 1)
	[ "$_r" = "0" ] && _rand_one=$((_rand_one + 1))
	_i=$((_i + 1))
done
assert_eq 10 "$_rand_one" "num_randomize: limit 1 always returns 0"
unset _i _rand_one _r

# Failure injection: awk is replaced by a shell function inside a subshell.
(
	_test_shim_awk fail
	_out=$(num_randomize 5 2>/dev/null)
	_st=$?
	[ "$_st" -eq 1 ] && [ -z "$_out" ]
)
assert_true $? "num_randomize: failing awk returns 1 with empty stdout"

(
	_test_shim_awk missing
	_out=$(num_randomize 5 2>/dev/null)
	_st=$?
	[ "$_st" -eq 1 ] && [ -z "$_out" ]
)
assert_true $? "num_randomize: missing awk (127) returns 1 with empty stdout"

(
	_test_shim_awk partial
	_out=$(num_randomize 5 2>/dev/null)
	_st=$?
	[ "$_st" -eq 1 ] && [ -z "$_out" ]
)
assert_true $? "num_randomize: failing awk leaks no partial stdout"

(
	_test_shim_awk fail
	_err=$(num_randomize 5 2>&1 >/dev/null)
	case "$_err" in
		*"could not generate a random number"*) exit 0 ;;
		*) exit 1 ;;
	esac
)
assert_true $? "num_randomize: awk failure uses the tool diagnostic"

# Portable range: 2^31-1 is the maximum accepted; one more is rejected.
(
	_out=$(num_randomize 2147483647 2>/dev/null)
	_st=$?
	[ "$_st" -eq 0 ] && num_is_natural "$_out" && [ "$_out" -lt 2147483647 ]
)
assert_true $? "num_randomize: maximum portable limit is accepted"

(
	_out=$(num_randomize 2147483648 2>/dev/null)
	_st=$?
	[ "$_st" -eq 1 ] && [ -z "$_out" ]
)
assert_true $? "num_randomize: limit above the portable maximum is rejected"

(
	_err=$(num_randomize 2147483648 2>&1 >/dev/null)
	[ "$_err" = "poshli: num_randomize: limit out of range (1..2147483647)" ]
)
assert_true $? "num_randomize: out-of-range limit uses the range diagnostic"

(
	_err=$(num_randomize 999999999999999999999999999999 2>&1 >/dev/null)
	[ "$_err" = "poshli: num_randomize: limit out of range (1..2147483647)" ]
)
assert_true $? "num_randomize: huge limit does not leak a shell diagnostic"

unset _out _st _err

test_summary
