#!/bin/sh
#
# POSHLI - POSIX Shell Library (Single File Bundle)
# GNU Lesser General Public License v3.0
#

[ -n "${_POSHLI_LOADED+x}" ] && return 0
_POSHLI_LOADED=1

#
# POSHLI - POSIX Shell Library
# Core module & version metadata
#
# GNU Lesser General Public License v3.0
#

if [ -z "${_POSHLI_CORE_LOADED+x}" ]; then
_POSHLI_CORE_LOADED=1

POSHLI_VERSION='1.0.0'
fi
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
#
# POSHLI - POSIX Shell Library
# File system checks module
#
# GNU Lesser General Public License v3.0
#

if [ -z "${_POSHLI_FS_LOADED+x}" ]; then
_POSHLI_FS_LOADED=1

is_file() {
	[ $# -ge 1 ] || return 2
	[ -f "$1" ]
}

is_dir() {
	[ $# -ge 1 ] || return 2
	[ -d "$1" ]
}

is_readable() {
	[ $# -ge 1 ] || return 2
	[ -r "$1" ]
}

is_writable() {
	[ $# -ge 1 ] || return 2
	[ -w "$1" ]
}

is_exec() {
	[ $# -ge 1 ] || return 2
	[ -x "$1" ]
}

is_empty_file() {
	[ $# -ge 1 ] || return 2
	[ -f "$1" ] && [ ! -s "$1" ]
}
fi
#
# POSHLI - POSIX Shell Library
# String manipulation and predicates module
#
# GNU Lesser General Public License v3.0
#

if [ -z "${_POSHLI_STR_LOADED+x}" ]; then
_POSHLI_STR_LOADED=1

# Case mapping backend: gawk when available, else awk. gawk is an optional
# dependency that enables Unicode simple case mapping in a UTF-8 locale.
# Otherwise (mawk, BusyBox awk, ...) awk typically leaves non-ASCII bytes
# unchanged in the C and UTF-8 locales; the result still depends on the
# active locale and on the awk implementation.
if command -v gawk >/dev/null 2>&1; then
	_POSHLI_AWK=gawk
else
	_POSHLI_AWK=awk
fi

is_empty() {
	[ $# -eq 0 ] || [ -z "$1" ]
}

trim() {
	[ $# -ge 1 ] || return 2
	printf '%s\n' "$1" | sed -e 's/^[ 	]*//' -e 's/[ 	]*$//'
}

lower() {
	[ $# -ge 1 ] || return 2
	printf '%s\n' "$1" | "$_POSHLI_AWK" '{ print tolower($0) }'
}

upper() {
	[ $# -ge 1 ] || return 2
	printf '%s\n' "$1" | "$_POSHLI_AWK" '{ print toupper($0) }'
}

starts_with() {
	[ $# -ge 2 ] || return 2
	case "$1" in
		"$2"*) return 0 ;;
		*) return 1 ;;
	esac
}

ends_with() {
	[ $# -ge 2 ] || return 2
	case "$1" in
		*"$2") return 0 ;;
		*) return 1 ;;
	esac
}

contains() {
	[ $# -ge 2 ] || return 2
	case "$1" in
		*"$2"*) return 0 ;;
		*) return 1 ;;
	esac
}

# str_len counts Unicode code points in valid UTF-8. It counts UTF-8 leading
# bytes with od and awk, so the result is independent of the shell's native
# ${#1} expansion and of the active locale. Combining marks and the individual
# components of emoji sequences count separately; grapheme clusters are not
# counted. For invalid UTF-8 the result is approximate; use str_len_bytes for
# raw byte data.
str_len() {
	[ $# -ge 1 ] || return 2
	printf '%s' "$1" | od -An -v -tu1 | awk '
		{
			for (i = 1; i <= NF; i++)
				if ($i < 128 || $i >= 192)
					n++
		}
		END { print n + 0 }
	'
}

# str_len_bytes counts bytes exactly, independent of the locale. Some wc
# implementations (for example BSD and macOS wc) pad the count with leading
# blanks, so the first whitespace-separated field is printed to guarantee a
# clean numeric result.
str_len_bytes() {
	[ $# -ge 1 ] || return 2
	printf '%s' "$1" | wc -c | awk '{print $1}'
}

str_replace() {
	[ $# -ge 3 ] || return 2
	[ -n "$1" ] || { printf '%s\n' "$3"; return 0; }
	_sr_search="$1"
	_sr_replace="$2"
	_sr_str="$3"
	_sr_out=""

	while case "$_sr_str" in *"${_sr_search}"*) true ;; *) false ;; esac; do
		_sr_prefix="${_sr_str%%"${_sr_search}"*}"
		_sr_out="${_sr_out}${_sr_prefix}${_sr_replace}"
		_sr_rest="${_sr_str#"${_sr_prefix}""${_sr_search}"}"
		_sr_str="$_sr_rest"
	done
	_sr_out="${_sr_out}${_sr_str}"
	printf '%s\n' "$_sr_out"
	unset _sr_search _sr_replace _sr_str _sr_out _sr_prefix _sr_rest
}
fi
