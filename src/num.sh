# shellcheck shell=sh
#
#  POSHLI - POSIX Shell Library
#  Numeric validations module
#
#  SPDX-License-Identifier: LGPL-3.0-only
#  Copyright (C) 2017-2018, 2026 Luis Gonzalo Fernández-Díez <humanogonzalo@gmail.com>
#  This file is part of POSHLI. See LICENSE for the full license text.
#

if [ -z "${_POSHLI_NUM_LOADED+x}" ]; then
_POSHLI_NUM_LOADED=1

num_is_integer() {
#	Returns 0 if the argument is a decimal integer with an optional sign.
#
#	Example of use:
#	num_is_integer "42" && echo "Valid integer" || echo "Invalid integer"
#
	[ $# -ge 1 ] || return 1
	case "${1#[+-]}" in
		"" | *[!0123456789]*) return 1 ;;
	esac
}

num_is_natural() {
#	Returns 0 if the argument is a natural number (including 0).
#
#	Example of use:
#	num_is_natural "42" && echo "Valid natural number" || echo "Invalid natural number"
#
	[ $# -ge 1 ] || return 1
	case "$1" in
		"" | *[!0123456789]*) return 1 ;;
	esac
}

num_is_number() {
#	Returns 0 if the argument is a decimal number with an optional sign and at most one decimal point.
#	Both a leading point (".5") and a trailing point ("3.") are accepted; an isolated point (".") is rejected.
#	Scientific notation is not supported.
#
#	Example of use:
#	num_is_number "3.14" && echo "Valid number" || echo "Invalid number"
#
	[ $# -ge 1 ] || return 1
	case "${1#[+-]}" in
		"" | . | *[!0123456789.]* | *.*.*) return 1 ;;
	esac
}

num_is_hex() {
#	Returns 0 if the argument is a hexadecimal number, optionally prefixed with 0x or 0X.
#
#	Example of use:
#	num_is_hex "0xFF" && echo "Valid hexadecimal" || echo "Invalid hexadecimal"
#
	[ $# -ge 1 ] || return 1
	case "${1#0[xX]}" in
		"" | *[!0123456789abcdefABCDEF]*) return 1 ;;
	esac
}

num_is_bin() {
#	Returns 0 if the argument is a binary number, optionally prefixed with 0b or 0B.
#
#	Example of use:
#	num_is_bin "0b1010" && echo "Valid binary" || echo "Invalid binary"
#
	[ $# -ge 1 ] || return 1
	case "${1#0[bB]}" in
		"" | *[!01]*) return 1 ;;
	esac
}

num_is_octal() {
#	Returns 0 if the argument is an octal number, optionally prefixed with 0o or 0O.
#
#	Example of use:
#	num_is_octal "0o755" && echo "Valid octal" || echo "Invalid octal"
#
	[ $# -ge 1 ] || return 1
	case "${1#0[oO]}" in
		"" | *[!01234567]*) return 1 ;;
	esac
}

num_is_bool() {
#	Returns 0 if the argument is 0, 1, true or false (case-insensitive).
#
#	Example of use:
#	num_is_bool "true" && echo "Valid boolean" || echo "Invalid boolean"
#
	[ $# -ge 1 ] || return 1
	case "$1" in
		0 | 1 | [Tt][Rr][Uu][Ee] | [Ff][Aa][Ll][Ss][Ee])
			return 0
			;;
	esac
	return 1
}

num_randomize() {
#	Prints a random integer from 0 to one less than the given limit.
#	The limit must be a natural number in the portable range
#	1..2147483647.
#
#	Returns 1 if the limit is zero, out of range, or if awk cannot
#	generate the number; 2 if no argument is passed. Fails closed:
#	no partial output is printed when awk fails.
#
#	Example of use:
#	RANDNUM=$(num_randomize 5)
#
	[ $# -ge 1 ] || return 2
	num_is_natural "$1" || return 1

	#	Reject zero without a numeric comparison: [ ] can overflow
	#	on large values in some shells (M2).
	case "$1" in
		*[1-9]*) ;;
		*) return 1 ;;
	esac

	#	awk validates the portable upper bound and keeps the result
	#	strictly below the limit. Capture stdout first so a failing
	#	awk cannot leak partial output (M1).
	_poshli_num_randomize_out=$(LC_ALL=C awk -v limit="$1" '
		BEGIN {
			if (limit + 0 > 2147483647) exit 3
			srand()
			r = int(rand() * limit)
			if (r >= limit || r < 0) r = limit - 1
			printf "%d\n", r
		}' 2>/dev/null)
	_poshli_num_randomize_status=$?

	if [ "$_poshli_num_randomize_status" -eq 3 ]; then
		printf 'poshli: num_randomize: limit out of range (1..2147483647)\n' >&2
		unset _poshli_num_randomize_out _poshli_num_randomize_status
		return 1
	fi
	if [ "$_poshli_num_randomize_status" -ne 0 ] || ! num_is_natural "$_poshli_num_randomize_out"; then
		printf 'poshli: num_randomize: could not generate a random number\n' >&2
		unset _poshli_num_randomize_out _poshli_num_randomize_status
		return 1
	fi

	printf '%s\n' "$_poshli_num_randomize_out" || {
		unset _poshli_num_randomize_out _poshli_num_randomize_status
		return 1
	}
	unset _poshli_num_randomize_out _poshli_num_randomize_status
	return 0
}

fi
