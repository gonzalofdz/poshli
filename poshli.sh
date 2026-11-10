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
	[ $# -ge 1 ] || return 2
	case "${1#[+-]}" in
		"" | *[!0-9]*) return 1 ;;
	esac
}

is_natural() {
	[ $# -ge 1 ] || return 2
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
	[ $# -ge 1 ] || return 2

	case "${1#0[xX]}" in
		"" | *[!0-9a-fA-F]*) return 1 ;;
	esac
}

is_bin() {
	[ $# -ge 1 ] || return 2

	case "${1#0[bB]}" in
		"" | *[!01]*) return 1 ;;
	esac
}

is_octal() {
	[ $# -ge 1 ] || return 2

	case "${1#0[oO]}" in
		"" | *[!0-7]*) return 1 ;;
	esac
}

is_bool() {
	[ $# -ge 1 ] || return 2

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

if [ -z "${_POSHLI_ENCODING_LOADED+x}" ]; then
_POSHLI_ENCODING_LOADED=1

base64_enc() {
	[ $# -ge 1 ] || return 2

	printf '%s' "${*}" | base64 | tr -d '\n'
}

base64_dec() {
	[ $# -ge 1 ] || return 2
	printf '%s' "${*}" | base64 -d || return 1
	return 0
}
fi
