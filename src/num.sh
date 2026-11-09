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
	case "${1#[+-]}" in
		"" | *[!0-9]*) return 1 ;;
		*) return 0 ;;
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
		[+-]*) _n_val="${1#[+-]}" ;;
		*) _n_val="$1" ;;
	esac
	case "$_n_val" in
		"" | . | *.*.* | *[!0-9.]* | *.)
			unset _n_val
			return 1
			;;
		*)
			unset _n_val
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
