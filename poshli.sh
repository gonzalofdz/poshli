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
#
# POSHLI - POSIX Shell Library
# Numeric validations module
#
# GNU Lesser General Public License v3.0
#

if [ -z "${_POSHLI_NUM_LOADED+x}" ]; then
_POSHLI_NUM_LOADED=1

is_integer() {
	[ $# -ge 1 ] || return 2
	case "$1" in
		"" | [+-]) return 1 ;;
		[+-]*)
			case "${1#[+-]}" in
				"" | *[!0-9]*) return 1 ;;
				*) return 0 ;;
			esac
			;;
		*)
			case "$1" in
				*[!0-9]*) return 1 ;;
				*) return 0 ;;
			esac
			;;
	esac
}

is_natural() {
	[ $# -ge 1 ] || return 2
	case "$1" in
		"" | *[!0-9]*) return 1 ;;
		*) return 0 ;;
	esac
}

is_number() {
	[ $# -ge 1 ] || return 2
	case "$1" in
		"" | [+-]) return 1 ;;
		[+-]*) _in_val="${1#[+-]}" ;;
		*) _in_val="$1" ;;
	esac
	case "$_in_val" in
		"" | *.*.* | . | *[!0-9.]*)
			unset _in_val
			return 1
			;;
		*.)
			unset _in_val
			return 1
			;;
		.*)
			case "${_in_val#.}" in
				"" | *[!0-9]*)
					unset _in_val
					return 1
					;;
				*)
					unset _in_val
					return 0
					;;
			esac
			;;
		*.*)
			_in_int="${_in_val%.*}"
			_in_dec="${_in_val#*.}"
			case "$_in_int" in
				"" | *[!0-9]*)
					unset _in_val _in_int _in_dec
					return 1
					;;
			esac
			case "$_in_dec" in
				"" | *[!0-9]*)
					unset _in_val _in_int _in_dec
					return 1
					;;
				*)
					unset _in_val _in_int _in_dec
					return 0
					;;
			esac
			;;
		*[!0-9]*)
			unset _in_val
			return 1
			;;
		*)
			unset _in_val
			return 0
			;;
	esac
}

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

is_bool() {
	[ $# -ge 1 ] || return 2
	case "$1" in
		0 | 1 | true | false | TRUE | FALSE) return 0 ;;
		*) return 1 ;;
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

is_empty() {
	[ $# -eq 0 ] || [ -z "$1" ]
}

trim() {
	[ $# -ge 1 ] || return 2
	printf '%s\n' "$1" | sed -e 's/^[ 	]*//' -e 's/[ 	]*$//'
}

lower() {
	[ $# -ge 1 ] || return 2
	printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]'
}

upper() {
	[ $# -ge 1 ] || return 2
	printf '%s\n' "$1" | tr '[:lower:]' '[:upper:]'
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

str_len() {
	[ $# -ge 1 ] || return 2
	printf '%s\n' "${#1}"
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
