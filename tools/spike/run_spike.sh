# shellcheck shell=sh
#
#  POSHLI - Spike matrix runner
#
#  GNU Lesser General Public License v3.0
#
#  Runs tools/spike/roundtrip_spike.sh under every supported shell
#  (dash, BusyBox sh, bash --posix), under an explicit C locale and under
#  an installed UTF-8 locale when available. Also runs the spike against
#  the BusyBox od/awk applets, since those are the least capable POSIX
#  implementations of the utilities involved.
#
#  Utilities used (all POSIX): command, env, locale, grep, mkdir, ln, rm.
#  The shim directory used for the BusyBox applet run is removed on exit.
#

SPIKE_DIR=$(cd "$(dirname "$0")" && pwd)
SPIKE=$SPIKE_DIR/roundtrip_spike.sh
fail=0

_run() {
	_label=$1
	shift
	printf '\n=== %s\n' "$_label"
	"$@" || fail=1
}

# Find an installed UTF-8 locale (may be empty).
utf8=""
if command -v locale >/dev/null 2>&1; then
	for loc in C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8; do
		if locale -a 2>/dev/null | grep -i -x -F "$loc" >/dev/null 2>&1; then
			utf8=$loc
			break
		fi
	done
fi

if command -v dash >/dev/null 2>&1; then
	_run "dash (LC_ALL=C)" env LC_ALL=C dash "$SPIKE"
	if [ -n "$utf8" ]; then
		_run "dash (LC_ALL=$utf8)" env LC_ALL="$utf8" dash "$SPIKE"
	fi
else
	printf '\nFAIL: dash is not installed\n'
	fail=1
fi

if command -v busybox >/dev/null 2>&1; then
	_run "busybox sh (LC_ALL=C)" env LC_ALL=C busybox sh "$SPIKE"
	if [ -n "$utf8" ]; then
		_run "busybox sh (LC_ALL=$utf8)" env LC_ALL="$utf8" busybox sh "$SPIKE"
	fi
else
	printf '\nFAIL: busybox is not installed\n'
	fail=1
fi

if command -v bash >/dev/null 2>&1; then
	_run "bash --posix (LC_ALL=C)" env LC_ALL=C bash --posix "$SPIKE"
	if [ -n "$utf8" ]; then
		_run "bash --posix (LC_ALL=$utf8)" env LC_ALL="$utf8" bash --posix "$SPIKE"
	fi
else
	printf '\nFAIL: bash is not installed\n'
	fail=1
fi

# BusyBox od/awk applets: a PATH shim makes "od" and "awk" resolve to the
# BusyBox applets without changing the spike script.
if command -v busybox >/dev/null 2>&1; then
	shim=${TMPDIR:-/tmp}/poshli-spike-shim.$$
	trap 'rm -rf "$shim"' 0 1 2 15
	rm -rf "$shim"
	mkdir -p "$shim" || fail=1
	ln -s "$(command -v busybox)" "$shim/od"
	ln -s "$(command -v busybox)" "$shim/awk"
	_run "busybox sh + busybox od/awk (LC_ALL=C)" \
		env LC_ALL=C PATH="$shim:$PATH" busybox sh "$SPIKE"
	if command -v dash >/dev/null 2>&1; then
		_run "dash + busybox od/awk (LC_ALL=C)" \
			env LC_ALL=C PATH="$shim:$PATH" dash "$SPIKE"
	fi
	rm -rf "$shim"
	trap - 0 1 2 15
fi

printf '\n=== spike matrix summary: '
if [ "$fail" -eq 0 ]; then
	printf 'ALL OK\n'
else
	printf 'FAILURES\n'
fi
exit "$fail"
