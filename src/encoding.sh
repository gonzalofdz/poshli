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

base64_enc() {
#	Prints the argument encoded in Base64 as a single line.
#
#	Example of use:
#	encoded=$(base64_enc "String")
#
	[ $# -ge 1 ] || return 2

	#	GNU coreutils and BusyBox wrap their output at 76 columns; drop
	#	the line breaks so the result is always a single line.
	printf '%s' "${*}" | base64 | tr -d '\n'
}

base64_dec() {
#	Prints the argument decoded from Base64.
#
#	Example of use:
#	decoded=$(base64_dec "$encoded")
#
	[ $# -ge 1 ] || return 2
	printf '%s' "${*}" | base64 -d || return 1
	return 0
}
fi
