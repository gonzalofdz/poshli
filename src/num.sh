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
#	is_integer "42" && echo "Valid integer"
#
	[ $# -ge 1 ] || return 2
	case "${1#[+-]}" in
		"" | *[!0-9]*) return 1 ;;
		*) return 0 ;;
	esac
}

is_natural() {
#	Returns 0 if the argument is a natural number (including 0).
#
#	Example of use:
#	is_natural "42" && echo "Valid natural number"
#
	[ $# -ge 1 ] || return 2
	case "$1" in
		"" | *[!0-9]*) return 1 ;;
		*) return 0 ;;
	esac
}

is_number() {
#	Returns 0 if the argument is a valid decimal number with optional sign and scientific notation.
#
#	Example of use:
#	is_number "3.14" && echo "Valid number"
#
	[ $# -ge 1 ] || return 2

	case "$1" in
		"" | [+-]) return 1 ;;
		[+-]*) _n_val="${1#[+-]}" ;;
		*) _n_val="$1" ;;
	esac

	case "$_n_val" in
		*[eE]*)
			case "$_n_val" in
				*[eE]*[eE]*)
					unset _n_val
					return 1
					;;
			esac

			_n_mantissa="${_n_val%%[eE]*}"
			_n_exponent="${_n_val#*[eE]}"

			case "$_n_exponent" in
				[+-]*) _n_exponent="${_n_exponent#[+-]}" ;;
			esac

			case "$_n_mantissa" in
				"" | . | *.*.* | *[!0-9.]*)
					unset _n_val _n_mantissa _n_exponent
					return 1
					;;
			esac

			case "$_n_exponent" in
				"" | *[!0-9]*)
					unset _n_val _n_mantissa _n_exponent
					return 1
					;;
			esac

			unset _n_val _n_mantissa _n_exponent
			return 0
			;;
	esac

	case "$_n_val" in
		"" | . | *.*.* | *[!0-9.]*)
			unset _n_val
			return 1
			;;
	esac

	unset _n_val
	return 0
}

is_hex() {
#	Returns 0 if the argument contains valid hexadecimal digits, optionally prefixed with 0x or 0X.
#
#	Example of use:
#	is_hex "0xFF" && echo "Valid hexadecimal"
#
	[ $# -ge 1 ] || return 2

	case "$1" in
		0[xX]*) _hex_val="${1#0[xX]}" ;;
		*) _hex_val="$1" ;;
	esac

	case "$_hex_val" in
		"" | *[!0-9a-fA-F]*)
			unset _hex_val
			return 1
			;;
		*)
			unset _hex_val
			return 0
			;;
	esac
}

is_bin() {
#	Returns 0 if the argument contains valid binary digits, optionally prefixed with 0b or 0B.
#
#	Example of use:
#	is_bin "0b1010" && echo "Valid binary"
#
	[ $# -ge 1 ] || return 2

	case "$1" in
		0[bB]*) _bin_val="${1#0[bB]}" ;;
		*) _bin_val="$1" ;;
	esac

	case "$_bin_val" in
		"" | *[!01]*)
			unset _bin_val
			return 1
			;;
		*)
			unset _bin_val
			return 0
			;;
	esac
}

is_octal() {
#	Returns 0 if the argument contains valid octal digits, optionally prefixed with 0o or 0O.
#
#	Example of use:
#	is_octal "0o755" && echo "Valid octal"
#
	[ $# -ge 1 ] || return 2

	case "$1" in
		0[oO]*) _octal_val="${1#0[oO]}" ;;
		*) _octal_val="$1" ;;
	esac

	case "$_octal_val" in
		"" | *[!0-7]*)
			unset _octal_val
			return 1
			;;
		*)
			unset _octal_val
			return 0
			;;
	esac
}

is_bool() {
#	Returns 0 if the argument is 0, 1, true or false (case-insensitive).
#
#	Example of use:
#	is_bool "true" && echo "Valid boolean"
#
	[ $# -ge 1 ] || return 2

	case "$1" in
		0 | 1 | [Tt][Rr][Uu][Ee] | [Ff][Aa][Ll][Ss][Ee])
			return 0
			;;
		*)
			return 1
			;;
	esac
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
