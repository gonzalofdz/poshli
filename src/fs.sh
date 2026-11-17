# shellcheck shell=sh
#
#  POSHLI - POSIX Shell Library
#  File system checks module
#
#  SPDX-License-Identifier: LGPL-3.0-only
#  Copyright (C) 2017-2018, 2026 Luis Gonzalo Fernández-Díez <humanogonzalo@gmail.com>
#  This file is part of POSHLI. See LICENSE for the full license text.
#

if [ -z "${_POSHLI_FS_LOADED+x}" ]; then
_POSHLI_FS_LOADED=1

fs_is_file() {
#	Returns 0 if the path exists and is a regular file.
#
#	Example of use:
#	fs_is_file "$HOME/.profile" && echo "File exists" || echo "File does not exist"
#
	[ $# -ge 1 ] || return 2
	[ -f "$1" ]
}

fs_is_dir() {
#	Returns 0 if the path exists and is a directory.
#
#	Example of use:
#	fs_is_dir "$HOME" && echo "Directory exists" || echo "Directory does not exist"
#
	[ $# -ge 1 ] || return 2
	[ -d "$1" ]
}

fs_is_readable() {
#	Returns 0 if the path exists and is readable.
#
#	Example of use:
#	fs_is_readable "$HOME/.profile" && echo "File is readable" || echo "File is not readable"
#
	[ $# -ge 1 ] || return 2
	[ -r "$1" ]
}

fs_is_writable() {
#	Returns 0 if the path exists and is writable.
#
#	Example of use:
#	fs_is_writable "/tmp" && echo "Directory is writable" || echo "Directory is not writable"
#
	[ $# -ge 1 ] || return 2
	[ -w "$1" ]
}

fs_is_exec() {
#	Returns 0 if the path exists and is executable.
#
#	Example of use:
#	fs_is_exec "/bin/sh" && echo "File is executable" || echo "File is not executable"
#
	[ $# -ge 1 ] || return 2
	[ -x "$1" ]
}

fs_is_empty_file() {
#	Returns 0 if the path is an existing regular file of size 0.
#
#	Example of use:
#	fs_is_empty_file "/tmp/empty" && echo "File is empty" || echo "File is not empty or does not exist"
#
	[ $# -ge 1 ] || return 2
	[ -f "$1" ] && [ ! -s "$1" ]
}

fs_is_plain_text() {
#	Returns 0 if the path is a regular readable file whose first 4096
#	bytes are plain text: a valid UTF-8 sequence with no NUL bytes and
#	no control characters other than TAB (0x09), LF (0x0A) and CR
#	(0x0D). DEL (0x7F) and the C1 controls (U+0080-U+009F) are rejected
#	as control characters too: the only control characters accepted are
#	TAB, LF and CR. An empty file is plain text.
#
#	Only the first 4096 bytes are inspected. Binary content appearing
#	after that limit can go unnoticed, and a UTF-8 character cut by the
#	limit is assumed to continue beyond it. This is a deterministic byte
#	heuristic built on the POSIX utilities od and awk: the result is
#	independent of the locale and never uses file(1) or any optional
#	tool. UTF-8 is validated explicitly over bytes (overlong forms,
#	surrogates and code points above U+10FFFF are rejected).
#
#	Returns 1 if the inspected content is not plain text (invalid UTF-8,
#	NUL byte, forbidden control character) and also when the file cannot
#	be evaluated (missing, unreadable, not a regular file, or read
#	error); 2 if no argument is passed.
#
#	Example of use:
#	fs_is_plain_text "$HOME/.profile" && echo "Plain text file" || echo "Not a plain text file"
#
	[ $# -ge 1 ] || return 2
	#	Regular and readable; -f also keeps od away from FIFOs and
	#	devices, where it could block forever.
	[ -f "$1" ] && [ -r "$1" ] || return 1

	#	od would parse a leading '-' operand as an option.
	case $1 in -*) set -- "./$1" ;; esac

	#	od reports the first 4096 bytes as decimal byte numbers, so
	#	the validator below only ever sees ASCII digits and spaces.
	#	The command substitution keeps od's exit status visible: a
	#	failed read must return 1, never look like empty text.
	if ! _pt_raw=$(LC_ALL=C od -A n -v -t u1 -N 4096 "$1" 2>/dev/null); then
		unset _pt_raw
		return 1
	fi

	#	awk consumes all of its input (no early exit) so the writing
	#	builtin never hits a closed pipe; the input is bounded anyway.
	if printf '%s\n' "$_pt_raw" | LC_ALL=C awk '
		BEGIN {
			ok = 1
			need = 0
			n = 0
			nlo = 128
			nhi = 191
		}
		{
			for (i = 1; i <= NF; i++) {
				if (!ok) continue
				b = $i + 0
				n++
				if (need > 0) {
					# continuation byte; nlo/nhi reject
					# overlongs, surrogates and > U+10FFFF
					if (b < nlo || b > nhi) { ok = 0; continue }
					cp = cp * 64 + (b - 128)
					need--
					if (need == 0) {
						# C1 controls (U+0080-U+009F)
						if (cp >= 128 && cp <= 159) ok = 0
					} else { nlo = 128; nhi = 191 }
					continue
				}
				if (b < 128) {
					# ASCII: TAB, LF, CR and printable only
					if (b == 9 || b == 10 || b == 13 || (b >= 32 && b <= 126)) continue
					ok = 0
					continue
				}
				if (b < 194) { ok = 0; continue }
				if (b < 224) { cp = b - 192; need = 1; nlo = 128; nhi = 191; continue }
				if (b == 224) { cp = 0; need = 2; nlo = 160; nhi = 191; continue }
				if (b < 237) { cp = b - 224; need = 2; nlo = 128; nhi = 191; continue }
				if (b == 237) { cp = 13; need = 2; nlo = 128; nhi = 159; continue }
				if (b < 240) { cp = b - 224; need = 2; nlo = 128; nhi = 191; continue }
				if (b == 240) { cp = 0; need = 3; nlo = 144; nhi = 191; continue }
				if (b < 244) { cp = b - 240; need = 3; nlo = 128; nhi = 191; continue }
				if (b == 244) { cp = 4; need = 3; nlo = 128; nhi = 143; continue }
				ok = 0
			}
		}
		END {
			# an incomplete sequence at the 4096-byte window
			# edge is tolerated: it may continue beyond it
			if (ok && (need == 0 || n == 4096)) exit 0
			exit 1
		}
	'; then
		unset _pt_raw
		return 0
	fi
	unset _pt_raw
	return 1
}
fi
