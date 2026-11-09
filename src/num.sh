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

# Returns 0 if the argument is a decimal integer with an optional sign.
# Returns 1 if it is not an integer, or 2 if no argument is provided.
is_integer() {
	[ $# -ge 1 ] || return 2
	case "${1#[+-]}" in
		"" | *[!0-9]*) return 1 ;;
		*) return 0 ;;
	esac
}

# Returns 0 if the argument is a natural number (including 0).
# Returns 1 if it is not a natural number, or 2 if no argument is provided.
is_natural() {
	[ $# -ge 1 ] || return 2
	case "$1" in
		"" | *[!0-9]*) return 1 ;;
		*) return 0 ;;
	esac
}

# Returns 0 if the argument is a valid decimal number with an optional sign
# and optional scientific notation.
# Examples: 42, -42, .5, 1., 1.5, 1e10, 1.5e-3.
# Returns 1 if invalid, or 2 if no argument is provided.
is_number() {
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

# Returns 0 if the argument contains valid hexadecimal digits, optionally
# prefixed with 0x or 0X.
# Returns 1 if invalid, or 2 if no argument is provided.
is_hex() {
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

# Returns 0 if the argument contains valid binary digits, optionally
# prefixed with 0b or 0B.
# Returns 1 if invalid, or 2 if no argument is provided.
is_bin() {
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

# Returns 0 if the argument contains valid octal digits, optionally
# prefixed with 0o or 0O.
# Returns 1 if invalid, or 2 if no argument is provided.
is_octal() {
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

# Returns 0 if the argument is 0, 1, true or false.
# true and false are matched case-insensitively for ASCII letters.
# Returns 1 if invalid, or 2 if no argument is provided.
is_bool() {
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

fi
