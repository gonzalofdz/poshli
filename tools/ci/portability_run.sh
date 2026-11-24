#!/bin/sh
#
#  POSHLI - CI helper for the macOS/FreeBSD portability workflow
#
#  Usage: portability_run.sh <label> <command> [arguments...]
#
#  Runs one suite configuration, echoes its output and verifies that the
#  suite printed its final "Tests run:" summary. A configuration that
#  aborts before the summary is a hard failure: an abort must never look
#  like a skip or a clean run. When GITHUB_STEP_SUMMARY is set, the
#  configuration totals and skips are appended to the job summary.
#
#  SPDX-License-Identifier: LGPL-3.0-only
#  Copyright (C) 2017-2018, 2026 Luis Gonzalo Fernández-Díez <humanogonzalo@gmail.com>
#  This file is part of POSHLI. See LICENSE for the full license text.
#

if [ "$#" -lt 2 ]; then
	printf 'usage: %s <label> <command> [arguments...]\n' "$0" >&2
	exit 2
fi

_label=$1
shift
_log=${TMPDIR:-/tmp}/poshli_ci_run.$$.log
trap 'rm -f "$_log"' 0 1 2 3 15

# The command's output is captured so the summary line can be checked
# without relying on pipefail (a POSIX pipeline reports only the last
# command's status). The captured text is echoed afterwards, so the CI log
# still shows every suite and assertion.
"$@" > "$_log" 2>&1
_status=$?
cat "$_log"

_aborted=0
if ! grep -q 'Tests run:' "$_log"; then
	printf 'ABORTED CONFIGURATION: %s (exit %d) produced no "Tests run:" summary\n' \
		"$_label" "$_status" >&2
	_aborted=1
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
	{
		printf '### %s\n\n' "$_label"
		if [ "$_aborted" -eq 0 ]; then
			printf '```text\n'
			grep -E 'Tests run:|\[SKIP\]|ABORTED' "$_log"
			printf '```\n\n'
		else
			printf '**ABORTED BEFORE SUMMARY (exit %d)**\n\n' "$_status"
		fi
	} >> "$GITHUB_STEP_SUMMARY"
fi

if [ "$_aborted" -eq 1 ]; then
	exit 1
fi
exit "$_status"
