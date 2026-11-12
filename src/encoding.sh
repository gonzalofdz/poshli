#
# POSHLI - POSIX Shell Library
# Encoding module (Base64)
#
# Base64 is an encoding, not an encryption: it provides no confidentiality.
#
# base64 is not part of POSIX; it is treated as a documented external
# dependency. No non-POSIX fallback (openssl, Python, uudecode, etc.) is
# added. The decode flag is selected once at load time by functional
# detection.
#
# GNU Lesser General Public License v3.0
#

if [ -z "${_POSHLI_ENCODING_LOADED+x}" ]; then
_POSHLI_ENCODING_LOADED=1

#	Detect a usable base64 backend and decode flag at load time. A flag is
#	accepted only if it decodes a known vector correctly.
_poshli_base64_dec_flag=''
if command -v base64 >/dev/null 2>&1; then
	_poshli_base64_probe=$(printf '%s' 'QQ==' | base64 -d 2>/dev/null) && [ "$_poshli_base64_probe" = 'A' ] && _poshli_base64_dec_flag='-d'
	if [ -z "$_poshli_base64_dec_flag" ]; then
		_poshli_base64_probe=$(printf '%s' 'QQ==' | base64 -D 2>/dev/null) && [ "$_poshli_base64_probe" = 'A' ] && _poshli_base64_dec_flag='-D'
	fi
	unset _poshli_base64_probe
fi

base64_enc() {
#	Prints "$1" encoded in standard Base64 as a single line.
#
#	Returns:
#		0 on success
#		1 if encoding fails or if no usable base64 backend is available
#		2 if no argument is passed
#
#	Extra arguments are ignored. Some base64 implementations wrap output at
#	76 columns; line breaks are removed so the result is always one line.
#
#	Example of use:
#
#		encoded=$(base64_enc "$text")
#		status=$?
#		case $status in
#			0) printf '%s\n' "$encoded" ;;
#			1) printf '%s\n' "Base64 encoding failed" >&2 ;;
#			2) printf '%s\n' "Missing argument" >&2 ;;
#		esac
#
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
#	Decodes strict standard Base64 (RFC 4648) from "$1" and writes the
#	decoded bytes directly to stdout.
#
#	Returns:
#		0 on success (including an empty string, which produces no output)
#		1 if the input is invalid, decoding fails, or no usable base64
#		  backend is available
#		2 if no argument is passed
#
#	Extra arguments are ignored. Accepted input uses the standard alphabet
#	(A-Z a-z 0-9 + /), correct "=" padding, and a length that is a multiple
#	of 4. Spaces, line breaks, base64url (- and _), missing padding, and
#	malformed padding are rejected. When POSHLI's validation rejects the
#	input, no output is produced.
#
#	Capturing output with $(...) is not suitable for binary/NUL data and
#	removes trailing newlines; redirect to a file for binary output.
#
#	Example of use:
#
#		decoded=$(base64_dec "$encoded")
#		status=$?
#		case $status in
#			0) printf '%s\n' "$decoded" ;;
#			1) printf '%s\n' "Not valid Base64" >&2 ;;
#			2) printf '%s\n' "Missing argument" >&2 ;;
#		esac
#
	[ $# -ge 1 ] || return 2
	[ -n "$_poshli_base64_dec_flag" ] || return 1

	#	Empty string is valid Base64 and decodes to no bytes.
	[ -n "$1" ] || return 0

	#	Strict RFC 4648 form: standard alphabet, length multiple of 4,
	#	padding only as final "=" or "==", and no "=" outside padding.
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
