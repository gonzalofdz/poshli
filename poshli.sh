#!/bin/sh
#
# POSHLI
#
# GNU Lesser General Public License v3.0

[ -n "${_POSHLI_LOADED+x}" ] && return 0
_POSHLI_LOADED=1

if [ -z "${_POSHLI_CORE_LOADED+x}" ]; then
_POSHLI_CORE_LOADED=1

POSHLI_VERSION='1.0.0'
fi

if [ -z "${_POSHLI_NUM_LOADED+x}" ]; then
_POSHLI_NUM_LOADED=1

is_integer() {
	[ $# -ge 1 ] || return 1
	case "${1#[+-]}" in
		"" | *[!0-9]*) return 1 ;;
	esac
}

is_natural() {
	[ $# -ge 1 ] || return 1
	case "$1" in
		"" | *[!0-9]*) return 1 ;;
	esac
}

is_number() {
	[ $# -ge 1 ] || return 1
	case "${1#[+-]}" in
		"" | . | *[!0-9.]* | *.*.*) return 1 ;;
	esac
}

is_hex() {
	[ $# -ge 1 ] || return 1
	case "${1#0[xX]}" in
		"" | *[!0-9a-fA-F]*) return 1 ;;
	esac
}

is_bin() {
	[ $# -ge 1 ] || return 1
	case "${1#0[bB]}" in
		"" | *[!01]*) return 1 ;;
	esac
}

is_octal() {
	[ $# -ge 1 ] || return 1
	case "${1#0[oO]}" in
		"" | *[!0-7]*) return 1 ;;
	esac
}

is_bool() {
	[ $# -ge 1 ] || return 1
	case "$1" in
		0 | 1 | [Tt][Rr][Uu][Ee] | [Ff][Aa][Ll][Ss][Ee])
			return 0
			;;
	esac
	return 1
}

randomize() {
	[ $# -ge 1 ] || return 2
	is_natural "$1" || return 1
	[ "$1" -gt 0 ] || return 1

	awk -v limit="$1" 'BEGIN {
		srand()
		printf "%d\n", int(rand() * limit)
	}'
}

fi

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

is_plain_text() {
	[ $# -ge 1 ] || return 2
	[ -r "$1" ] || return 1

	LC_ALL=C file -b "$1" | grep -q 'text'
}
fi

if [ -z "${_POSHLI_STR_LOADED+x}" ]; then
_POSHLI_STR_LOADED=1

if command -v gawk >/dev/null 2>&1; then
	_POSHLI_AWK=gawk
else
	_POSHLI_AWK=awk
fi

is_empty() {
	[ $# -eq 0 ] || [ -z "$1" ]
}

trim() {
	if [ $# -eq 0 ]; then
		printf '%s\n' ""
		return
	fi
	printf '%s\n' "$1" | sed -e 's/^[ 	]*//' -e 's/[ 	]*$//'
}

lower() {
	if [ $# -eq 0 ]; then
		printf '%s\n' ""
		return
	fi
	printf '%s\n' "$1" | "$_POSHLI_AWK" '{ print tolower($0) }'
}

upper() {
	if [ $# -eq 0 ]; then
		printf '%s\n' ""
		return
	fi
	printf '%s\n' "$1" | "$_POSHLI_AWK" '{ print toupper($0) }'
}

starts_with() {
	[ $# -ge 2 ] || return 1
	case "$1" in
		"$2"*) return 0 ;;
		*) return 1 ;;
	esac
}

ends_with() {
	[ $# -ge 2 ] || return 1
	case "$1" in
		*"$2") return 0 ;;
		*) return 1 ;;
	esac
}

contains() {
	[ $# -ge 2 ] || return 1
	case "$1" in
		*"$2"*) return 0 ;;
		*) return 1 ;;
	esac
}

str_len() {
	if [ $# -eq 0 ]; then
		printf '0\n'
		return
	fi
	printf '%s' "$1" | od -An -v -tu1 | awk '
		{
			for (i = 1; i <= NF; i++)
				if ($i < 128 || $i >= 192)
					n++
		}
		END { print n + 0 }
	'
}

str_len_bytes() {
	if [ $# -eq 0 ]; then
		printf '0\n'
		return
	fi
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

if [ -z "${_POSHLI_ENCODING_LOADED+x}" ]; then
_POSHLI_ENCODING_LOADED=1

_poshli_base64_dec_flag=''
if command -v base64 >/dev/null 2>&1; then
	_poshli_base64_probe=$(printf '%s' 'QQ==' | base64 -d 2>/dev/null) && [ "$_poshli_base64_probe" = 'A' ] && _poshli_base64_dec_flag='-d'
	if [ -z "$_poshli_base64_dec_flag" ]; then
		_poshli_base64_probe=$(printf '%s' 'QQ==' | base64 -D 2>/dev/null) && [ "$_poshli_base64_probe" = 'A' ] && _poshli_base64_dec_flag='-D'
	fi
	unset _poshli_base64_probe
fi

base64_enc() {
	[ $# -ge 1 ] || return 2
	command -v base64 >/dev/null 2>&1 || return 1

	_poshli_base64_out=$(printf '%s' "$1" | base64 2>/dev/null) || {
		unset _poshli_base64_out
		return 1
	}
	printf '%s' "$_poshli_base64_out" | tr -d '\n'
	unset _poshli_base64_out
}

base64_dec() {
	[ $# -ge 1 ] || return 2
	[ -n "$_poshli_base64_dec_flag" ] || return 1

	[ -n "$1" ] || return 0

	case $1 in
		*[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=]*)
			return 1
			;;
	esac
	[ $(( ${#1} % 4 )) -eq 0 ] || return 1
	case $1 in
		*==)
			_poshli_b64_prefix=${1%??}
			;;
		*=)
			_poshli_b64_prefix=${1%?}
			;;
		*)
			_poshli_b64_prefix=$1
			;;
	esac
	case $_poshli_b64_prefix in
		*=*)
			unset _poshli_b64_prefix
			return 1
			;;
	esac
	unset _poshli_b64_prefix

	printf '%s' "$1" | base64 "$_poshli_base64_dec_flag" 2>/dev/null || return 1
}
fi
