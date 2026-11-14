# shellcheck shell=sh
#
#  POSHLI - Isolated technical spike: portable UTF-8 byte transport
#
#  GNU Lesser General Public License v3.0
#
#  PURPOSE
#  -------
#  Prove (or refute) that the future Unicode support of lower/upper in
#  src/str.sh can rest on this transport layer, using only POSIX Shell and
#  POSIX utilities:
#
#	UTF-8 input bytes
#	    |  printf '%s' "$str"        (bytes, never interpreted)
#	    |  od -A n -v -t u1          (every byte becomes an ASCII number)
#	    v
#	ASCII numbers + a small ASCII data table (stdin, after a sentinel)
#	    |  awk                       (ASCII only: digits, records, arithmetic)
#	    |  (validate UTF-8, decode to code points, look up the table,
#	    |   re-encode to UTF-8, render every output byte as an octal escape)
#	    v
#	ASCII octal escapes
#	    |  printf '%b'               (escapes become exact bytes)
#	    v
#	output bytes, identical to the input for valid UTF-8
#
#  The only places where non-ASCII bytes exist are the pipe from printf to
#  od and the final printf write: awk, the data table and every shell
#  variable carry ASCII text and numbers only.
#
#  SCOPE (deliberately NOT here)
#  -----------------------------
#  No lower/upper, no Unicode case table, no case_data.sh, no generator.
#  The demo table contains one toy ASCII mapping record (U+0041 -> U+0061)
#  whose only purpose is proving the lookup stage of the pipeline; it is
#  not Unicode case mapping. This file is UTF-8 (see the fixtures below).
#
#  UTILITIES USED (all POSIX)
#  --------------------------
#  printf, od, awk. Nothing else. No GNU, BSD or BusyBox extension, no
#  Python/Perl, no gawk, no locale Unicode support.
#
#  NUL: EXPLICIT LIMITS
#  --------------------
#  - A POSIX shell argument (or variable) can never contain a NUL byte.
#    That is a fundamental limit of the shell itself and applies to every
#    string API, so the future lower/upper (which take a string argument)
#    can never be handed U+0000 either way.
#  - The transport layer itself is NUL-transparent: od reports NUL as the
#    number 0, awk and the shell only move ASCII text, and printf '%b'
#    writes the NUL byte back. This is demonstrated through stdin (the
#    only way a process can receive NUL) by the "NUL bytes on stdin" test.
#  - So NUL is unreachable through the string API by construction, not
#    because of a limitation of this architecture.
#
#  ARG_MAX
#  -------
#  The data table travels on stdin behind a sentinel line, never as an
#  argument, so table size cannot hit ARG_MAX. The octal escape text is
#  passed to printf '%b', which is a shell builtin in dash, BusyBox ash
#  and bash (no exec, no argument limit); if printf were an external
#  utility the escape text (at most 4x the input) would face the system
#  argument limit, which would be mitigated by emitting in chunks. Not
#  needed for this spike.
#
#  LOCALE
#  ------
#  The active locale is never modified for the caller: the pipeline runs
#  inside a subshell that exports LC_ALL=C only for itself. The result is
#  locale-independent by construction (awk only sees ASCII).
#
#  SECURITY
#  --------
#  Input is data everywhere: no eval, no generated code, no command names
#  derived from input. printf '%b' receives escapes built from numeric
#  byte values, so input bytes can never forge escapes or format directives
#  (a backslash in the input is emitted as \134). No temporary files.
#

# --- transport layer ------------------------------------------------------

_poshli_spike_table() {
#	Emits the placeholder data table: a version record, optional
#	mapping records, and the sentinel line that ends the table. The
#	records are plain ASCII ("M <decimal> <decimal>"); the real Unicode
#	table will travel the same way, never as an argument.
#
	printf '%s\n' 'V spike-1'
	case ${1:-identity} in
	demo)
		# Toy record U+0041 -> U+0061 to exercise the lookup stage.
		printf '%s\n' 'M 65 97'
		;;
	esac
	printf '%s\n' '!'
}

_poshli_spike_rt() {
#	Prints on stdout the exact bytes read on stdin: UTF-8 -> ASCII
#	numbers -> numeric processing -> octal escapes -> exact bytes.
#	The first argument selects the table mode (identity or demo).
#	For valid UTF-8 the output is byte-identical to the input; invalid
#	UTF-8 prints nothing, writes a diagnostic to stderr and returns 1.
#
	_poshli_spike_esc=$(
		(
			export LC_ALL=C
			{
				_poshli_spike_table "${1:-identity}"
				od -A n -v -t u1
			} | awk '
				# ASCII only: decimal byte numbers in, octal
				# escape text out. No byte >= 0x80 is ever seen.
				function oct3(x) {
					return sprintf("%d%d%d", int(x / 64), int(x / 8) % 8, x % 8)
				}
				function esc(x) {
					return "\\0" oct3(x)
				}
				function enc(c) {
					# code point -> UTF-8 bytes as escapes
					if (c < 128)
						return esc(c)
					if (c < 2048)
						return esc(192 + int(c / 64)) esc(128 + (c % 64))
					if (c < 65536)
						return esc(224 + int(c / 4096)) esc(128 + (int(c / 64) % 64)) esc(128 + (c % 64))
					return esc(240 + int(c / 262144)) esc(128 + (int(c / 4096) % 64)) esc(128 + (int(c / 64) % 64)) esc(128 + (c % 64))
				}
				BEGIN {
					phase = 0
					ok = 1
					need = 0
					buf = ""
				}
				{
					if (phase == 0) {
						if ($0 == "!") { phase = 1; next }
						if ($1 == "V") { next }
						if ($1 == "M") { cmap[$2 + 0] = $3 + 0; next }
						ok = 0
						exit 1
					}
					for (i = 1; i <= NF; i++) {
						b = $i + 0
						if (need > 0) {
							# continuation byte; lo/hi exclude
							# overlongs, surrogates and > U+10FFFF
							if (b < lo || b > hi) { ok = 0; exit 1 }
							cp = cp * 64 + (b - 128)
							need--
							if (need == 0) {
								if (cp in cmap) { cp = cmap[cp] }
								buf = buf enc(cp)
							} else {
								lo = 128
								hi = 191
							}
							continue
						}
						if (b < 128) {
							if (b in cmap) { b = cmap[b] }
							buf = buf enc(b)
							continue
						}
						if (b < 194) { ok = 0; exit 1 }
						if (b < 224) { cp = b - 192; need = 1; lo = 128; hi = 191; continue }
						if (b == 224) { cp = 0; need = 2; lo = 160; hi = 191; continue }
						if (b < 237) { cp = b - 224; need = 2; lo = 128; hi = 191; continue }
						if (b == 237) { cp = 13; need = 2; lo = 128; hi = 159; continue }
						if (b < 240) { cp = b - 224; need = 2; lo = 128; hi = 191; continue }
						if (b == 240) { cp = 0; need = 3; lo = 144; hi = 191; continue }
						if (b < 244) { cp = b - 240; need = 3; lo = 128; hi = 191; continue }
						if (b == 244) { cp = 4; need = 3; lo = 128; hi = 143; continue }
						ok = 0
						exit 1
					}
				}
				END {
					if (ok && need == 0)
						printf "%s", buf
					else
						exit 1
				}
			'
		)
	) || return 1
	printf '%b' "$_poshli_spike_esc"
	unset _poshli_spike_esc
}

# --- minimal test harness -------------------------------------------------

_sp_tests=0
_sp_failed=0

_sp_assert_eq() {
#	$1 label, $2 got, $3 want
#
	_sp_tests=$((_sp_tests + 1))
	if [ "$2" = "$3" ]; then
		printf 'ok   %s\n' "$1"
	else
		_sp_failed=$((_sp_failed + 1))
		printf 'FAIL %s\n' "$1"
		printf '     got:  %s\n' "$2"
		printf '     want: %s\n' "$3"
	fi
}

_sp_rt() {
#	$1 label, $2 table mode, $3 string: output bytes must be exactly
#	the input bytes. Comparison goes through od text (ASCII), which is
#	safe to capture in $(...), unlike raw bytes.
#
	_sp_got=$(printf '%s' "$3" | _poshli_spike_rt "$2" | od -A n -v -t x1)
	_sp_want=$(printf '%s' "$3" | od -A n -v -t x1)
	_sp_assert_eq "$1" "$_sp_got" "$_sp_want"
	printf '%s' "$3" | _poshli_spike_rt "$2" >/dev/null 2>&1
	_sp_assert_eq "$1: status 0" "$?" 0
}

_sp_rt_reject() {
#	$1 label, $2 string: invalid UTF-8 must print zero bytes and
#	return 1 (the awk validator rejects it).
#
	_sp_got=$(printf '%s' "$2" | _poshli_spike_rt identity 2>/dev/null | od -A n -v -t x1)
	_sp_assert_eq "$1: no output bytes" "$_sp_got" ""
	printf '%s' "$2" | _poshli_spike_rt identity >/dev/null 2>&1
	_sp_assert_eq "$1: status 1" "$?" 1
}

# --- tests ----------------------------------------------------------------

printf '%s\n' '--- roundtrip_spike: UTF-8 byte transport ---'

# Emission primitive: printf "%b" must reproduce every byte 0x00-0xFF
# exactly (this is the only step where raw bytes are written).
_sp_esc=$(awk 'BEGIN { for (i = 0; i < 256; i++) printf "\\0%d%d%d", int(i / 64), int(i / 8) % 8, i % 8 }')
_sp_got=$(printf '%b' "$_sp_esc" | od -A n -v -t u1 | awk '
	{ for (i = 1; i <= NF; i++) {
		if ($i + 0 != n) { bad = 1; exit 1 }
		n++
	} }
	END { if (!bad && n == 256) print "ok" }
')
_sp_assert_eq "emitter: printf %b reproduces bytes 0x00-0xFF exactly" "$_sp_got" "ok"

# Required round-trip cases.
_sp_rt "round trip: Espana" identity 'España'
_sp_rt "round trip: CJK" identity '你好'
_sp_rt "round trip: Cyrillic" identity 'ПРИВЕТ'
_sp_rt "round trip: emoji" identity '😀'

# Empty input.
_sp_rt "round trip: empty string" identity ''

# Newlines. Fixtures with trailing newlines are multi-line literals
# because $(...) strips trailing newlines and cannot hold them.
_sp_rt "round trip: embedded newline" identity 'a
b'
_sp_trail='abc
'
_sp_rt "round trip: trailing newline" identity "$_sp_trail"
_sp_nls='
'
_sp_rt "round trip: single newline" identity "$_sp_nls"

# Repeated data: without "od -v" repeated lines are elided with "*" and
# the round trip silently corrupts; 200 identical bytes catch that.
_sp_rep=''
_sp_i=0
while [ "$_sp_i" -lt 200 ]; do
	_sp_rep=${_sp_rep}m
	_sp_i=$((_sp_i + 1))
done
_sp_rt "round trip: 200 identical bytes (od -v)" identity "$_sp_rep"

# UTF-8 boundary code points, from U+007F up to the longest valid
# sequence (U+10FFFF, 4 bytes).
_sp_rt "round trip: U+007F" identity "$(printf '\177')"
_sp_rt "round trip: U+0080" identity "$(printf '\302\200')"
_sp_rt "round trip: U+07FF" identity "$(printf '\337\277')"
_sp_rt "round trip: U+0800" identity "$(printf '\340\240\200')"
_sp_rt "round trip: U+FFFF" identity "$(printf '\357\277\277')"
_sp_rt "round trip: U+10000" identity "$(printf '\360\220\200\200')"
_sp_rt "round trip: U+10FFFF" identity "$(printf '\364\217\277\277')"

# Long mixed-script text (~6 KB) over many od lines and a large escape
# buffer.
_sp_block='ΠΡΙΒΕΤ πριβετ ПРИВЕТ привет 你好 😀 España — 50 € '
_sp_long=''
_sp_i=0
while [ "$_sp_i" -lt 80 ]; do
	_sp_long=${_sp_long}${_sp_block}
	_sp_i=$((_sp_i + 1))
done
_sp_rt "round trip: long mixed text" identity "$_sp_long"

# Input is data only: shell metacharacters, printf directives and lines
# that look like table records or the sentinel must round-trip unchanged.
_sp_rt "round trip: metacharacters are data" identity '`id` $(id) ${x} \ %s %b %n'
_sp_rt "round trip: record-like and sentinel-like input" identity '! M 65 97 V spike-1'
_sp_rt "round trip: leading -n" identity '-n'

# Invalid UTF-8: detected by the numeric validator inside awk
# (same rules as str_len: overlongs, surrogates and > U+10FFFF are out).
_sp_rt_reject "reject: lone continuation byte" "$(printf '\200')"
_sp_rt_reject "reject: truncated sequence" "$(printf '\303')"
_sp_rt_reject "reject: overlong sequence" "$(printf '\300\257')"
_sp_rt_reject "reject: UTF-8 surrogate" "$(printf '\355\240\200')"
_sp_rt_reject "reject: beyond U+10FFFF" "$(printf '\364\220\200\200')"
_sp_rt_reject "reject: invalid byte embedded in text" "$(printf 'a\200b')"

# NUL bytes: unreachable through a shell argument (see header), but the
# transport carries them exactly when they arrive on stdin.
_sp_got=$(printf 'a\000b\000c' | _poshli_spike_rt identity | od -A n -v -t x1)
_sp_want=$(printf 'a\000b\000c' | od -A n -v -t x1)
_sp_assert_eq "round trip: NUL bytes on stdin" "$_sp_got" "$_sp_want"

# Lookup stage plumbing: one toy ASCII record through the stdin data
# channel (this is NOT Unicode case mapping).
_sp_got=$(printf '%s' 'AZ' | _poshli_spike_rt demo | od -A n -v -t x1)
_sp_want=$(printf '%s' 'aZ' | od -A n -v -t x1)
_sp_assert_eq "lookup stage: toy ASCII map record" "$_sp_got" "$_sp_want"

# --- summary --------------------------------------------------------------

printf '\n%s\n' "--- result: $_sp_tests tests, $_sp_failed failures ---"
[ "$_sp_failed" -eq 0 ]
