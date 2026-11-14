# shellcheck shell=sh
#
#  POSHLI - POSIX Shell Library
#  String manipulation and predicates module
#
#  GNU Lesser General Public License v3.0
#

if [ -z "${_POSHLI_STR_LOADED+x}" ]; then
_POSHLI_STR_LOADED=1

# Case mapping in lower/upper converts numeric code points with our own
# generated Unicode data (see src/case_data.sh and tools/gen_case.py), so
# the result is the same in every locale, shell and awk implementation.
# UTF-8 is validated, decoded, mapped and re-encoded through ASCII and
# numbers only (od, awk, printf): no tool ever interprets non-ASCII text.

is_empty() {
#	Returns 0 if no argument is given or the argument is empty.
#
#	Example of use:
#	is_empty "$STR" && echo "String is empty" || echo "String is not empty"
#
	[ $# -eq 0 ] || [ -z "$1" ]
}

trim() {
#	Prints the argument with leading and trailing spaces and tabs removed.
#
#	Example of use:
#	TRIMMED=$(trim "  hello  ")
#
	if [ $# -eq 0 ]; then
		printf '%s\n' ""
		return
	fi
	_trim_str=$1
	_trim_str=${_trim_str#"${_trim_str%%[! 	]*}"}
	_trim_str=${_trim_str%"${_trim_str##*[! 	]}"}
	printf '%s\n' "$_trim_str"
	unset _trim_str
}

_poshli_case_map() {
#	Prints the second argument converted to lower or upper case, as
#	selected by the first argument.
#
#	The mapping covers the Unicode simple case mappings plus the
#	unconditional one-to-many mappings (for example U+00DF uppercases
#	to SS): ASCII, Latin, Greek and Cyrillic letters are guaranteed
#	and tested, and any other code point with a generated mapping is
#	converted too. Code points without a mapping (emoji, CJK, symbols,
#	punctuation, combining marks) are preserved unchanged. Invalid
#	UTF-8 prints nothing, writes a diagnostic to standard error and
#	returns 1, exactly like str_len. Contextual and language-specific
#	rules are not applied: U+03A3 always lowercases to U+03C3 (no
#	contextual final sigma) and upper "i" is I in every locale.
#
#	The conversion is performed over numeric code points with our own
#	generated data (src/case_data.sh), so the result is identical in
#	every locale, shell and awk implementation.
#
#	Example of use:
#	LOWER=$(_poshli_case_map lower "HELLO")
#
	if [ -z "${_POSHLI_CASE_LOADED+x}" ]; then
		printf '%s\n' "poshli: $1: case mapping data not loaded (source src/case_data.sh)" >&2
		return 1
	fi
	case "$1" in
	lower) _poshli_case_table="$_POSHLI_CASE_LOWER" ;;
	upper) _poshli_case_table="$_POSHLI_CASE_UPPER" ;;
	*)
		unset _poshli_case_table
		return 2
		;;
	esac
	#	The mapping table travels on standard input behind a "!"
	#	line, never as an argument (no ARG_MAX exposure), followed by
	#	the input as decimal byte numbers from od. awk only sees
	#	ASCII: numbers, table records and octal escape text. The
	#	whole result is buffered and printed only on success, so a
	#	failed call prints nothing.
	_poshli_case_out=$(
		{
			printf '%s\n' "$_poshli_case_table"
			printf '!\n'
			printf '%s' "$2" | LC_ALL=C od -A n -v -t u1
		} | LC_ALL=C awk '
			function hex2dec(s,   i, n, c) {
				n = 0
				for (i = 1; i <= length(s); i++) {
					c = substr(s, i, 1)
					n = n * 16 + index("0123456789ABCDEF", c) - 1
				}
				return n
			}
			function esc(x) {
				return oct[x]
			}
			function enc(c) {
				# code point -> UTF-8 bytes as octal escapes
				if (c < 128)
					return esc(c)
				if (c < 2048)
					return esc(192 + int(c / 64)) esc(128 + (c % 64))
				if (c < 65536)
					return esc(224 + int(c / 4096)) esc(128 + (int(c / 64) % 64)) esc(128 + (c % 64))
				return esc(240 + int(c / 262144)) esc(128 + (int(c / 4096) % 64)) esc(128 + (int(c / 64) % 64)) esc(128 + (c % 64))
			}
			function mapcp(c) {
				# mapped code point(s) as octal escapes
				if (c in xmap)
					return xmap[c]
				if (c in map)
					return enc(map[c])
				return enc(c)
			}
			BEGIN {
				# precomputed "\0nnn" octal escape for every byte
				for (i = 0; i < 256; i++)
					oct[i] = "\\0" sprintf("%d%d%d", int(i / 64), int(i / 8) % 8, i % 8)
				phase = 0
				ok = 1
				need = 0
				nbuf = 0
			}
			{
				if (phase == 0) {
					if ($0 == "!") {
						for (i = 1; i <= nr; i++)
							for (c = dlo[i]; c <= dhi[i]; c++)
								map[c] = c + ddel[i]
						for (c in ex)
							map[c] = ex[c]
						phase = 1
						next
					}
					if (NF == 0) { next }
					if ($1 == "D") {
						nr++
						dlo[nr] = hex2dec($2)
						dhi[nr] = hex2dec($3)
						ddel[nr] = $4 + 0
						next
					}
					if ($1 == "E") {
						ex[hex2dec($2)] = hex2dec($3)
						next
					}
					if ($1 == "X") {
						s = ""
						for (i = 3; i <= NF; i++)
							s = s enc(hex2dec($i))
						xmap[hex2dec($2)] = s
						next
					}
					ok = 0
					exit 1
				}
				# One buffer slot per od line keeps appending
				# linear; the slots are printed in order at END.
				rec = ""
				for (i = 1; i <= NF; i++) {
					b = $i + 0
					if (need > 0) {
						# continuation byte; nlo/nhi exclude
						# overlongs, surrogates and > U+10FFFF
						if (b < nlo || b > nhi) { ok = 0; exit 1 }
						cp = cp * 64 + (b - 128)
						need--
						if (need == 0)
							rec = rec mapcp(cp)
						else { nlo = 128; nhi = 191 }
						continue
					}
					if (b < 128) { rec = rec mapcp(b); continue }
					if (b < 194) { ok = 0; exit 1 }
					if (b < 224) { cp = b - 192; need = 1; nlo = 128; nhi = 191; continue }
					if (b == 224) { cp = 0; need = 2; nlo = 160; nhi = 191; continue }
					if (b < 237) { cp = b - 224; need = 2; nlo = 128; nhi = 191; continue }
					if (b == 237) { cp = 13; need = 2; nlo = 128; nhi = 159; continue }
					if (b < 240) { cp = b - 224; need = 2; nlo = 128; nhi = 191; continue }
					if (b == 240) { cp = 0; need = 3; nlo = 144; nhi = 191; continue }
					if (b < 244) { cp = b - 240; need = 3; nlo = 128; nhi = 191; continue }
					if (b == 244) { cp = 4; need = 3; nlo = 128; nhi = 143; continue }
					ok = 0
					exit 1
				}
				nbuf++
				buf[nbuf] = rec
			}
			END {
				if (ok && need == 0) {
					for (i = 1; i <= nbuf; i++)
						printf "%s", buf[i]
				} else
					exit 1
			}
		'
	) || {
		unset _poshli_case_table _poshli_case_out
		printf '%s\n' "poshli: $1: input is not valid UTF-8" >&2
		return 1
	}
	printf '%b\n' "$_poshli_case_out"
	unset _poshli_case_table _poshli_case_out
}

lower() {
#	Prints the argument converted to lowercase.
#
#	Applies Unicode case mapping with the generated POSHLI data:
#	ASCII, Latin, Greek and Cyrillic letters are mapped (any other
#	code point with a generated mapping is converted too), code
#	points without a mapping (emoji, CJK, symbols, punctuation,
#	combining marks) are preserved unchanged, and invalid UTF-8
#	prints nothing, writes a diagnostic to standard error and
#	returns 1. The result is identical in every locale, shell and
#	awk implementation. See Unicode Support in README.md.
#
#	Example of use:
#	LOWER=$(lower "HELLO")
#
	if [ $# -eq 0 ]; then
		printf '%s\n' ""
		return
	fi
	_poshli_case_map lower "$1"
}

upper() {
#	Prints the argument converted to uppercase.
#
#	Same behavior as lower: Unicode case mapping with the generated
#	POSHLI data, including the unconditional one-to-many mappings
#	(for example U+00DF expands to SS and the result can be longer
#	than the input). Code points without a mapping are preserved
#	unchanged, and invalid UTF-8 prints nothing, writes a diagnostic
#	to standard error and returns 1. See Unicode Support in
#	README.md.
#
#	Example of use:
#	UPPER=$(upper "hello")
#
	if [ $# -eq 0 ]; then
		printf '%s\n' ""
		return
	fi
	_poshli_case_map upper "$1"
}

starts_with() {
#	Returns 0 if the first argument begins with the second argument.
#
#	Example of use:
#	starts_with "https://example.com" "https" && echo "URL uses HTTPS" || echo "URL does not use HTTPS"
#
	[ $# -ge 2 ] || return 1
	case "$1" in
		"$2"*) return 0 ;;
		*) return 1 ;;
	esac
}

ends_with() {
#	Returns 0 if the first argument ends with the second argument.
#
#	Example of use:
#	ends_with "script.sh" ".sh" && echo "Shell script" || echo "Not a shell script"
#
	[ $# -ge 2 ] || return 1
	case "$1" in
		*"$2") return 0 ;;
		*) return 1 ;;
	esac
}

contains() {
#	Returns 0 if the first argument contains the second argument.
#
#	Example of use:
#	contains "hello world" "world" && echo "Substring found" || echo "Substring not found"
#
	[ $# -ge 2 ] || return 1
	case "$1" in
		*"$2"*) return 0 ;;
		*) return 1 ;;
	esac
}

str_len() {
#	Prints the number of Unicode code points in the argument.
#
#	The argument must be valid UTF-8. Invalid input produces no count, a
#	diagnostic on standard error, and status 1.
#
#	Example of use:
#	LEN=$(str_len "España")
#
	if [ $# -eq 0 ]; then
		printf '0\n'
		return
	fi
	if ! printf '%s' "$1" | LC_ALL=C od -A n -v -t u1 | LC_ALL=C awk '
		BEGIN {
			n = 0
			need = 0
			ok = 1
			lo = 128
			hi = 191
		}
		{
			for (i = 1; i <= NF; i++) {
				b = $i + 0
				if (need > 0) {
					if (b < lo || b > hi) {
						ok = 0
						exit 1
					}
					need--
					lo = 128
					hi = 191
					continue
				}
				if (b < 128) {
					n++
					continue
				}
				if (b >= 194 && b <= 223) {
					n++
					need = 1
					continue
				}
				if (b == 224) {
					n++
					need = 2
					lo = 160
					hi = 191
					continue
				}
				if (b >= 225 && b <= 236) {
					n++
					need = 2
					continue
				}
				if (b == 237) {
					n++
					need = 2
					lo = 128
					hi = 159
					continue
				}
				if (b >= 238 && b <= 239) {
					n++
					need = 2
					continue
				}
				if (b == 240) {
					n++
					need = 3
					lo = 144
					hi = 191
					continue
				}
				if (b >= 241 && b <= 243) {
					n++
					need = 3
					continue
				}
				if (b == 244) {
					n++
					need = 3
					lo = 128
					hi = 143
					continue
				}
				ok = 0
				exit 1
			}
		}
		END {
			if (ok && need == 0)
				print n
			else
				exit 1
		}
	'; then
		printf '%s\n' "poshli: str_len: input is not valid UTF-8" >&2
		return 1
	fi
	return 0
}

str_len_bytes() {
#	Prints the exact number of bytes in the argument.
#
#	Example of use:
#	BYTES=$(str_len_bytes "España")
#
	if [ $# -eq 0 ]; then
		printf '0\n'
		return
	fi
	printf '%s' "$1" | wc -c | awk '{print $1}'
}

str_replace() {
#	Prints the third argument with every occurrence of the first replaced by the second.
#
#	Example of use:
#	RESULT=$(str_replace "foo" "bar" "foo baz")
#
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
