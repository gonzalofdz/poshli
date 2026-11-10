#!/bin/sh
#
# POSHLI - Unit tests for num.sh
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

# Argument count validation (returns 2 if no argument)
is_integer
assert_status 2 $? "is_integer requires argument (status 2)"
is_natural
assert_status 2 $? "is_natural requires argument (status 2)"
is_number
assert_status 2 $? "is_number requires argument (status 2)"
is_hex
assert_status 2 $? "is_hex requires argument (status 2)"
is_bin
assert_status 2 $? "is_bin requires argument (status 2)"
is_octal
assert_status 2 $? "is_octal requires argument (status 2)"
is_bool
assert_status 2 $? "is_bool requires argument (status 2)"
randomize
assert_status 2 $? "randomize requires argument (status 2)"

# is_integer tests
is_integer "42"; assert_true $? "is_integer: 42"
is_integer "-42"; assert_true $? "is_integer: -42"
is_integer "+42"; assert_true $? "is_integer: +42"
is_integer "0012"; assert_true $? "is_integer: 0012"
is_integer "0"; assert_true $? "is_integer: 0"

is_integer "+"; assert_false $? "is_integer rejects: +"
is_integer "-"; assert_false $? "is_integer rejects: -"
is_integer "12-3"; assert_false $? "is_integer rejects: 12-3"
is_integer "1+2"; assert_false $? "is_integer rejects: 1+2"
is_integer "12+"; assert_false $? "is_integer rejects: 12+"
is_integer "+12+"; assert_false $? "is_integer rejects: +12+"
is_integer "++1"; assert_false $? "is_integer rejects: ++1"
is_integer "--1"; assert_false $? "is_integer rejects: --1"
is_integer ""; assert_false $? "is_integer rejects: empty string"
is_integer "3.14"; assert_false $? "is_integer rejects: 3.14"
is_integer " "; assert_false $? "is_integer rejects: space"
is_integer "abc"; assert_false $? "is_integer rejects: abc"

# is_natural tests
is_natural "0"; assert_true $? "is_natural: 0"
is_natural "1"; assert_true $? "is_natural: 1"
is_natural "42"; assert_true $? "is_natural: 42"
is_natural "0012"; assert_true $? "is_natural: 0012"

is_natural "-42"; assert_false $? "is_natural rejects: -42"
is_natural "+42"; assert_false $? "is_natural rejects: +42"
is_natural "-1"; assert_false $? "is_natural rejects: -1"
is_natural "+1"; assert_false $? "is_natural rejects: +1"
is_natural ""; assert_false $? "is_natural rejects: empty string"
is_natural "3.14"; assert_false $? "is_natural rejects: 3.14"
is_natural ".5"; assert_false $? "is_natural rejects: .5"
is_natural "abc"; assert_false $? "is_natural rejects: abc"

# is_number tests
is_number "42"; assert_true $? "is_number: 42"
is_number "-42"; assert_true $? "is_number: -42"
is_number "+42"; assert_true $? "is_number: +42"
is_number "0012"; assert_true $? "is_number: 0012"
is_number "0"; assert_true $? "is_number: 0"

is_number ".5"; assert_true $? "is_number: .5"
is_number "-.5"; assert_true $? "is_number: -.5"
is_number "+.5"; assert_true $? "is_number: +.5"
is_number "3."; assert_true $? "is_number: 3."
is_number "3.14"; assert_true $? "is_number: 3.14"
is_number "-3.14"; assert_true $? "is_number: -3.14"
is_number "+0.05"; assert_true $? "is_number: +0.05"
is_number "100.25"; assert_true $? "is_number: 100.25"

# Scientific notation
is_number "1e10"; assert_true $? "is_number: 1e10"
is_number "1E10"; assert_true $? "is_number: 1E10"
is_number "1.5e2"; assert_true $? "is_number: 1.5e2"
is_number "1.e10"; assert_true $? "is_number: 1.e10"
is_number ".5E-2"; assert_true $? "is_number: .5E-2"
is_number "+1e+10"; assert_true $? "is_number: +1e+10"
is_number "-3E-5"; assert_true $? "is_number: -3E-5"

is_number "+"; assert_false $? "is_number rejects: +"
is_number "-"; assert_false $? "is_number rejects: -"
is_number "12-3"; assert_false $? "is_number rejects: 12-3"
is_number "1+2"; assert_false $? "is_number rejects: 1+2"
is_number "12+"; assert_false $? "is_number rejects: 12+"
is_number "+12+"; assert_false $? "is_number rejects: +12+"
is_number "++1"; assert_false $? "is_number rejects: ++1"
is_number "--1"; assert_false $? "is_number rejects: --1"
is_number ""; assert_false $? "is_number rejects: empty string"
is_number "."; assert_false $? "is_number rejects: ."
is_number "-."; assert_false $? "is_number rejects: -."
is_number "+."; assert_false $? "is_number rejects: +."
is_number "3.."; assert_false $? "is_number rejects: 3.."
is_number "1.2.3"; assert_false $? "is_number rejects: 1.2.3"
is_number "e10"; assert_false $? "is_number rejects: e10"
is_number "1e"; assert_false $? "is_number rejects: 1e"
is_number "1e+"; assert_false $? "is_number rejects: 1e+"
is_number "1e-"; assert_false $? "is_number rejects: 1e-"
is_number "1e2e3"; assert_false $? "is_number rejects: multiple exponents"
is_number "1.2.3e4"; assert_false $? "is_number rejects: invalid mantissa"
is_number "NaN"; assert_false $? "is_number rejects: NaN"
is_number "Infinity"; assert_false $? "is_number rejects: Infinity"
is_number " "; assert_false $? "is_number rejects: space"
is_number "abc"; assert_false $? "is_number rejects: abc"

# is_hex tests
is_hex "0"; assert_true $? "is_hex: 0"
is_hex "1a"; assert_true $? "is_hex: 1a"
is_hex "DEADBEEF"; assert_true $? "is_hex: DEADBEEF"
is_hex "0xFF"; assert_true $? "is_hex: 0xFF"
is_hex "0XFF"; assert_true $? "is_hex: 0XFF"
is_hex "0x10"; assert_true $? "is_hex: 0x10"
is_hex "abc"; assert_true $? "is_hex: abc"
is_hex "0b101"; assert_true $? "is_hex: 0b101"

is_hex ""; assert_false $? "is_hex rejects: empty string"
is_hex "0x"; assert_false $? "is_hex rejects: 0x"
is_hex "0X"; assert_false $? "is_hex rejects: 0X"
is_hex "12G"; assert_false $? "is_hex rejects: 12G"
is_hex "xyz"; assert_false $? "is_hex rejects: xyz"

# is_bin tests
is_bin "0"; assert_true $? "is_bin: 0"
is_bin "1"; assert_true $? "is_bin: 1"
is_bin "10110"; assert_true $? "is_bin: 10110"
is_bin "0b1010"; assert_true $? "is_bin: 0b1010"
is_bin "0B1"; assert_true $? "is_bin: 0B1"

is_bin ""; assert_false $? "is_bin rejects: empty string"
is_bin "0b"; assert_false $? "is_bin rejects: 0b"
is_bin "0B"; assert_false $? "is_bin rejects: 0B"
is_bin "102"; assert_false $? "is_bin rejects: 102"
is_bin "abc"; assert_false $? "is_bin rejects: abc"

# is_octal tests
is_octal "0"; assert_true $? "is_octal: 0"
is_octal "7"; assert_true $? "is_octal: 7"
is_octal "755"; assert_true $? "is_octal: 755"
is_octal "0777"; assert_true $? "is_octal: 0777"
is_octal "0o755"; assert_true $? "is_octal: 0o755"
is_octal "0O755"; assert_true $? "is_octal: 0O755"

is_octal ""; assert_false $? "is_octal rejects: empty string"
is_octal "0o"; assert_false $? "is_octal rejects: 0o"
is_octal "0O"; assert_false $? "is_octal rejects: 0O"
is_octal "8"; assert_false $? "is_octal rejects: 8"
is_octal "09"; assert_false $? "is_octal rejects: 09"
is_octal "0o8"; assert_false $? "is_octal rejects: 0o8"

# is_bool tests
is_bool "0"; assert_true $? "is_bool: 0"
is_bool "1"; assert_true $? "is_bool: 1"

is_bool "true"; assert_true $? "is_bool: true"
is_bool "TRUE"; assert_true $? "is_bool: TRUE"
is_bool "True"; assert_true $? "is_bool: True"
is_bool "tRuE"; assert_true $? "is_bool: tRuE"

is_bool "false"; assert_true $? "is_bool: false"
is_bool "FALSE"; assert_true $? "is_bool: FALSE"
is_bool "False"; assert_true $? "is_bool: False"
is_bool "fAlSe"; assert_true $? "is_bool: fAlSe"

is_bool ""; assert_false $? "is_bool rejects: empty string"
is_bool "yes"; assert_false $? "is_bool rejects: yes"
is_bool "no"; assert_false $? "is_bool rejects: no"
is_bool "on"; assert_false $? "is_bool rejects: on"
is_bool "off"; assert_false $? "is_bool rejects: off"
is_bool "y"; assert_false $? "is_bool rejects: y"
is_bool "n"; assert_false $? "is_bool rejects: n"
is_bool "2"; assert_false $? "is_bool rejects: 2"
is_bool "-1"; assert_false $? "is_bool rejects: -1"

# randomize tests
randomize 0; assert_status 1 $? "randomize rejects limit 0 (status 1)"
randomize -1; assert_status 1 $? "randomize rejects negative limit (status 1)"
randomize abc; assert_status 1 $? "randomize rejects non-natural limit (status 1)"
randomize 1.5; assert_status 1 $? "randomize rejects decimal limit (status 1)"
randomize ""; assert_status 1 $? "randomize rejects empty limit (status 1)"

# Valid limit: prints a natural number below the limit
res=$(randomize 5); assert_true $? "randomize 5 succeeds"
is_natural "$res"; assert_true $? "randomize 5 prints a natural number"
[ "$res" -lt 5 ]; assert_true $? "randomize 5 result is below the limit"

# Result always stays within [0, limit) over repeated calls
_i=0
_rand_ok=0
while [ "$_i" -lt 20 ]; do
	_r=$(randomize 10)
	is_natural "$_r" && [ "$_r" -lt 10 ] && _rand_ok=$((_rand_ok + 1))
	_i=$((_i + 1))
done
assert_eq 20 "$_rand_ok" "randomize: 20 results all within [0, 10)"
unset _i _rand_ok _r

# Limit 1 can only produce 0
_i=0
_rand_one=0
while [ "$_i" -lt 10 ]; do
	_r=$(randomize 1)
	[ "$_r" = "0" ] && _rand_one=$((_rand_one + 1))
	_i=$((_i + 1))
done
assert_eq 10 "$_rand_one" "randomize: limit 1 always returns 0"
unset _i _rand_one _r

test_summary
