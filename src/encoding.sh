# shellcheck shell=sh
#
#  POSHLI - POSIX Shell Library
#  Encoding module
#
#  GNU Lesser General Public License v3.0
#

if [ -z "${_POSHLI_ENCODING_LOADED+x}" ]; then
_POSHLI_ENCODING_LOADED=1

encoding_base64_encode() {
#	Encodes "$1" as standard Base64 and prints the result as a single
#	line with no trailing line break.
#
#	Returns:
#		0 on success
#		1 if encoding fails, including od or wc unavailable or
#		  producing inconsistent output (no partial Base64 output
#		  is emitted on error), or a write error while printing
#		  the result
#		2 if no argument is passed
#
#	Extra arguments are ignored. The output is standard Base64
#	(RFC 4648: alphabet A-Z, a-z, 0-9, +, / and "=" padding) written
#	as one unwrapped line: no line breaks are inserted, and no
#	trailing newline is appended to the output.
#
#	Implemented with POSIX shell and the POSIX utilities od, wc and
#	awk only (no external base64 command): od turns the bytes of "$1"
#	into decimal byte numbers and awk maps every 3-byte group to 4
#	Base64 characters with plain arithmetic. NUL bytes cannot appear
#	in "$1" because a shell argument cannot hold NUL; that is a limit
#	of the shell string API, not of the encoding.
#
#	Memory: awk streams instead of buffering. Each complete 3-byte
#	group is encoded as soon as its bytes arrive and at most 2 bytes
#	are held back, so the awk stage uses constant memory and peak
#	memory no longer scales with the awk-side buffering of the input.
#	The Base64 result is captured in a shell variable before anything
#	is printed, so a failing od or awk discards the partial capture
#	and no partial Base64 output reaches stdout. That capture (about
#	4/3 of the input size) is the one buffer that still grows with
#	the input, together with the unavoidable "$1" itself: writing
#	straight to stdout would use constant memory too but would give
#	up the "no partial output on error" guarantee, and buffering
#	through temporary files would trade memory for new failure modes
#	(disk space, cleanup, read-only TMPDIR). The capture is the
#	deliberate compromise: peak memory is a small multiple of the
#	input size instead of tens or hundreds of times it.
#
#	Performance and size scope: benchmarked with inputs up to 5 MB
#	in one environment (about 0.5 s for 1 MB and about 2.8 s for 5 MB
#	with GNU awk; observed peak memory about 10 MB and about 44 MB
#	respectively, and about 44 MB for 5 MB with mawk). These are
#	indicative figures from specific runs, not performance
#	guarantees and not maximum input limits.
#
#	Example of use:
#
#		encoded=$(encoding_base64_encode "$text")
#		status=$?
#		case $status in
#			0) printf '%s\n' "$encoded" ;;
#			1) printf '%s\n' "Base64 encoding failed" >&2 ;;
#			2) printf '%s\n' "Missing argument" >&2 ;;
#		esac
#
	[ $# -ge 1 ] || return 2
	[ -n "$1" ] || return 0

	#	POSIX pipelines report the status of their last command
	#	only, so a failure of od could be hidden by a successful
	#	awk. Validate what od actually produced instead of trusting
	#	the pipeline status: wc counts the expected input bytes and
	#	awk rejects fields that are not integers in 0..255 and any
	#	byte-count mismatch. The Base64 that awk produces is
	#	captured first and only printed on success, so a rejected
	#	input never emits partial Base64 to stdout.
	_poshli_b64_want=$(printf '%s' "$1" | LC_ALL=C wc -c) || {
		unset _poshli_b64_want
		return 1
	}

	#	The bytes of "$1" become decimal numbers (od -A n: no
	#	offsets, -v: no elision of repeated lines) and awk maps
	#	each 3-byte group onto 4 Base64 characters using only
	#	int(), % and division (POSIX awk has no bitwise
	#	operators). awk streams: every complete 3-byte group is
	#	printed as soon as its bytes arrive, keeping at most 2
	#	bytes pending, so the awk stage holds no input-sized
	#	buffer. awk consumes all of its input (no early exit) so
	#	the writing builtin never hits a closed pipe; the
	#	validation at END (byte count and field values) happens
	#	before the pending remainder is flushed. awk only sees
	#	ASCII digits and prints ASCII Base64, so the result does
	#	not depend on the locale; LC_ALL=C keeps od's numeric
	#	output deterministic too.
	_poshli_base64_out=$(printf '%s' "$1" | LC_ALL=C od -A n -v -t u1 | LC_ALL=C awk -v want="$_poshli_b64_want" '
		BEGIN {
			alph = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
			seen = 0
			n = 0
		}
		{
			for (i = 1; i <= NF; i++) {
				if ($i !~ /^[0-9]+$/ || $i + 0 > 255) bad = 1
				seen++
				n++
				b[n] = $i + 0
				if (n == 3) {
					printf "%s%s%s%s", substr(alph, int(b[1] / 4) + 1, 1), substr(alph, (b[1] % 4) * 16 + int(b[2] / 16) + 1, 1), substr(alph, (b[2] % 16) * 4 + int(b[3] / 64) + 1, 1), substr(alph, (b[3] % 64) + 1, 1)
					n = 0
				}
			}
		}
		END {
			if (bad || seen != want + 0) exit 1
			if (n == 1) {
				printf "%s%s==", substr(alph, int(b[1] / 4) + 1, 1), substr(alph, (b[1] % 4) * 16 + 1, 1)
			} else if (n == 2) {
				printf "%s%s%s=", substr(alph, int(b[1] / 4) + 1, 1), substr(alph, (b[1] % 4) * 16 + int(b[2] / 16) + 1, 1), substr(alph, (b[2] % 16) * 4 + 1, 1)
			}
		}
	') || {
		unset _poshli_b64_want _poshli_base64_out
		return 1
	}
	unset _poshli_b64_want
	#	A write error of printf must not be hidden by the cleanup
	#	unset below: the status is tested before unsetting and
	#	returned, and the temporaries are cleaned on both paths.
	printf '%s' "$_poshli_base64_out" || {
		unset _poshli_base64_out
		return 1
	}
	unset _poshli_base64_out
	return 0
}

encoding_base64_decode() {
#	Decodes strict standard Base64 (RFC 4648) from "$1" and writes the
#	decoded bytes directly to stdout.
#
#	Returns:
#		0 on success, including an empty string, which produces no output
#		1 if the input is invalid, decoding fails, or a write error
#		  occurs while writing the decoded bytes
#		2 if no argument is passed
#
#	Extra arguments are ignored. Input must use the standard alphabet
#	(A-Z, a-z, 0-9, +, /), correct "=" padding, and a length that is a
#	multiple of 4. Whitespace, line breaks, base64url (- and _), missing
#	padding, and malformed padding are rejected. When POSHLI validation
#	rejects the input, no output is produced.
#
#	Implemented with POSIX shell and POSIX awk only (no external base64
#	command): awk maps every 4-character group to its 1-3 decoded bytes
#	as octal escapes, and the shell printf %b writes the exact bytes.
#	The escape text is captured before anything is printed, so a
#	failing awk never emits partial output; that capture (about three
#	times the input text) is the buffer that grows with the input. It
#	cannot be avoided portably: POSIX awk cannot write raw bytes
#	(the numeric argument of %c is not portable), so the bytes must
#	travel as escapes through a shell printf. Capturing output with
#	$(...) is not suitable for binary or NUL data and removes
#	trailing newlines; redirect stdout to a file for binary output.
#
#	Example of use:
#
#		decoded=$(encoding_base64_decode "$encoded")
#		status=$?
#		case $status in
#			0) printf '%s\n' "$decoded" ;;
#			1) printf '%s\n' "Not valid Base64" >&2 ;;
#			2) printf '%s\n' "Missing argument" >&2 ;;
#		esac
#
	[ $# -ge 1 ] || return 2

	#	Empty string is valid Base64 and decodes to no bytes.
	[ -n "$1" ] || return 0

	#	Strict RFC 4648 form: standard alphabet, length multiple of 4,
	#	padding only as final "=" or "==", no "=" outside padding, and
	#	zero padding bits (canonical form).
	case $1 in
		*[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=]*)
			return 1
			;;
	esac
	[ $(( ${#1} % 4 )) -eq 0 ] || return 1
	#	Canonical form: zero padding bits restrict the last data character.
	case $1 in
		*[!AQgw]==) return 1 ;;
		*==)
			_poshli_b64_prefix=${1%??}
			;;
		*[!AEIMQUYcgkosw048]=) return 1 ;;
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

	#	The input is validated ASCII above, so awk sees one plain
	#	record. Each 4-character group yields its 1-3 decoded bytes
	#	as "\0nnn" octal escapes (arithmetic only: POSIX awk has no
	#	bitwise operators), and printf %b turns the escapes back
	#	into the exact bytes. The escape text contains no real line
	#	breaks, so capturing it with $(...) cannot lose data. The
	#	output bytes are raw: no trailing newline is appended.
	_poshli_b64_esc=$(printf '%s' "$1" | LC_ALL=C awk '
		BEGIN {
			alph = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
			for (i = 0; i < 256; i++)
				oct[i] = sprintf("\\0%d%d%d", int(i / 64), int(i / 8) % 8, i % 8)
		}
		{ s = s $0 }
		END {
			len = length(s)
			for (i = 1; i <= len; i += 4) {
				c3 = substr(s, i + 2, 1)
				c4 = substr(s, i + 3, 1)
				v1 = index(alph, substr(s, i, 1)) - 1
				v2 = index(alph, substr(s, i + 1, 1)) - 1
				v3 = 0
				printf "%s", oct[v1 * 4 + int(v2 / 16)]
				if (c3 != "=") {
					v3 = index(alph, c3) - 1
					printf "%s", oct[(v2 % 16) * 16 + int(v3 / 4)]
				}
				if (c4 != "=") {
					v4 = index(alph, c4) - 1
					printf "%s", oct[(v3 % 4) * 64 + v4]
				}
			}
		}
	') || {
		unset _poshli_b64_esc
		return 1
	}
	#	A write error of printf must not be hidden by the cleanup
	#	unset below: the status is tested before unsetting and
	#	returned, and the temporaries are cleaned on both paths.
	printf '%b' "$_poshli_b64_esc" || {
		unset _poshli_b64_esc
		return 1
	}
	unset _poshli_b64_esc
	return 0
}
fi
