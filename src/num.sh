#!/bin/sh
#
# POSHLI - POSIX Shell Library
# Numeric validations module
#
# Copyright (C) 2026 Gonzalo Fernández-Díez
#
# GNU Lesser General Public License v3.0
#

if [ -z "${_POSHLI_NUM_LOADED+x}" ]; then
_POSHLI_NUM_LOADED=1

is_integer() {
#	Returns 0 if the argument is a decimal integer with an optional sign.
#
#	Example of use:
#	is_integer "42" && echo "Valid integer" || echo "Invalid integer"
#
	[ $# -ge 1 ] || return 1
	case "${1#[+-]}" in
		"" | *[!0-9]*) return 1 ;;
	esac
}

is_natural() {
#	Returns 0 if the argument is a natural number (including 0).
#
#	Example of use:
#	is_natural "42" && echo "Valid natural number" || echo "Invalid natural number"
#
	[ $# -ge 1 ] || return 1
	case "$1" in
		"" | *[!0-9]*) return 1 ;;
	esac
}

is_number() {
#	Returns 0 if the argument is a decimal number with an optional sign and at most one decimal point.
#	Both a leading point (".5") and a trailing point ("3.") are accepted; an isolated point (".") is rejected.
#	Scientific notation is not supported.
#
#	Example of use:
#	is_number "3.14" && echo "Valid number" || echo "Invalid number"
#
	[ $# -ge 1 ] || return 1
	case "${1#[+-]}" in
		"" | . | *[!0-9.]* | *.*.*) return 1 ;;
	esac
}

is_hex() {
#	Returns 0 if the argument is a hexadecimal number, optionally prefixed with 0x or 0X.
#
#	Example of use:
#	is_hex "0xFF" && echo "Valid hexadecimal" || echo "Invalid hexadecimal"
#
	[ $# -ge 1 ] || return 1
	case "${1#0[xX]}" in
		"" | *[!0-9a-fA-F]*) return 1 ;;
	esac
}

is_bin() {
#	Returns 0 if the argument is a binary number, optionally prefixed with 0b or 0B.
#
#	Example of use:
#	is_bin "0b1010" && echo "Valid binary" || echo "Invalid binary"
#
	[ $# -ge 1 ] || return 1
	case "${1#0[bB]}" in
		"" | *[!01]*) return 1 ;;
	esac
}

is_octal() {
#	Returns 0 if the argument is an octal number, optionally prefixed with 0o or 0O.
#
#	Example of use:
#	is_octal "0o755" && echo "Valid octal" || echo "Invalid octal"
#
	[ $# -ge 1 ] || return 1
	case "${1#0[oO]}" in
		"" | *[!0-7]*) return 1 ;;
	esac
}

is_bool() {
#	Returns 0 if the argument is 0, 1, true or false (case-insensitive).
#
#	Example of use:
#	is_bool "true" && echo "Valid boolean" || echo "Invalid boolean"
#
	[ $# -ge 1 ] || return 1
	case "$1" in
		0 | 1 | [Tt][Rr][Uu][Ee] | [Ff][Aa][Ll][Ss][Ee])
			return 0
			;;
	esac
	return 1
}

randomize() {
#	Prints a random integer from 0 to one less than the given limit.
#
#	Example of use:
#	RANDNUM=$(randomize 5)
#
	[ $# -ge 1 ] || return 2
	is_natural "$1" || return 1
	[ "$1" -gt 0 ] || return 1

	awk -v limit="$1" 'BEGIN {
		srand()
		printf "%d\n", int(rand() * limit)
	}'
}

fi
