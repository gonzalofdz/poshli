#
# POSHLI - POSIX Shell Library
# Encoding module (Base64)
#
# Base64 is an encoding, not an encryption: it provides no confidentiality.
#
# GNU Lesser General Public License v3.0
#

if [ -z "${_POSHLI_ENCODING_LOADED+x}" ]; then
_POSHLI_ENCODING_LOADED=1

#	Prints the input string base64 encoded.
#
#	Example:	encoded=$(base64_enc "String")
#
base64_enc() {
	[ $# -ge 1 ] || return 2

	#	GNU coreutils and BusyBox wrap their output at 76 columns; drop
	#	the line breaks so the result is always a single line.
	printf '%s' "${*}" | base64 | tr -d '\n'
}

#	Prints the input string base64 decoded.
#
#	Example:	decoded=$(base64_dec "$encoded")
#
base64_dec() {
	[ $# -ge 1 ] || return 2
	printf '%s' "${*}" | base64 -d || return 1
	return 0
}
fi
