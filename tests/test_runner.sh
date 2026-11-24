#!/bin/sh
#
# POSHLI Test Runner Framework (POSIX-compliant)
#
# SPDX-License-Identifier: LGPL-3.0-only
# Copyright (C) 2017-2018, 2026 Luis Gonzalo Fernández-Díez <humanogonzalo@gmail.com>
# This file is part of POSHLI. See LICENSE for the full license text.
#

TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Under GitHub Actions, emit a workflow-command error annotation for each
# failure. The check-runs annotations API is readable without the job log,
# so a failing test can be identified on every platform. Local runs are
# unchanged: GITHUB_ACTIONS is unset. Percent signs must be escaped in
# workflow commands.
_test_ci_error() {
	[ -n "${GITHUB_ACTIONS:-}" ] || return 0
	_test_ci_msg=$(printf '%s' "$1" | sed 's/%/%25/g')
	printf '::error::%s\n' "$_test_ci_msg"
	unset _test_ci_msg
}

assert_eq() {
	_a_expected="$1"
	_a_actual="$2"
	_a_desc="$3"
	TESTS_TOTAL=$((TESTS_TOTAL + 1))

	if [ "$_a_expected" = "$_a_actual" ]; then
		TESTS_PASSED=$((TESTS_PASSED + 1))
		printf '  [PASS] %s\n' "$_a_desc"
	else
		TESTS_FAILED=$((TESTS_FAILED + 1))
		printf '  [FAIL] %s\n' "$_a_desc"
		printf '         Expected: "%s"\n' "$_a_expected"
		printf '         Actual:   "%s"\n' "$_a_actual"
		_test_ci_error "FAIL: $_a_desc | expected: [$_a_expected] | actual: [$_a_actual]"
	fi
	unset _a_expected _a_actual _a_desc
}

assert_status() {
	_s_expected="$1"
	_s_actual="$2"
	_s_desc="$3"
	TESTS_TOTAL=$((TESTS_TOTAL + 1))

	if [ "$_s_expected" -eq "$_s_actual" ]; then
		TESTS_PASSED=$((TESTS_PASSED + 1))
		printf '  [PASS] %s (status %d)\n' "$_s_desc" "$_s_actual"
	else
		TESTS_FAILED=$((TESTS_FAILED + 1))
		printf '  [FAIL] %s\n' "$_s_desc"
		printf '         Expected status: %d\n' "$_s_expected"
		printf '         Actual status:   %d\n' "$_s_actual"
		_test_ci_error "FAIL: $_s_desc | expected status: [$_s_expected] | actual status: [$_s_actual]"
	fi
	unset _s_expected _s_actual _s_desc
}

assert_true() {
	_t_status="$1"
	_t_desc="$2"
	assert_status 0 "$_t_status" "$_t_desc"
	unset _t_status _t_desc
}

assert_false() {
	_f_status="$1"
	_f_desc="$2"
	TESTS_TOTAL=$((TESTS_TOTAL + 1))

	if [ "$_f_status" -ne 0 ]; then
		TESTS_PASSED=$((TESTS_PASSED + 1))
		printf '  [PASS] %s (non-zero status %d)\n' "$_f_desc" "$_f_status"
	else
		TESTS_FAILED=$((TESTS_FAILED + 1))
		printf '  [FAIL] %s (expected failure, got 0)\n' "$_f_desc"
		_test_ci_error "FAIL: $_f_desc (expected non-zero, got 0)"
	fi
	unset _f_status _f_desc
}

# Install a controlled external shim for awk/od where the shell honours PATH.
# BusyBox resolves these utilities as applets even when PATH is overridden, so
# an equivalent function shim is defined in that case. Keeping the shims out of
# pipelines on PATH-honouring shells avoids shell-specific function statuses
# (ksh93 reports 256 for a function used as the last command of a pipeline).
_test_shim_awk() {
	POSHLI_TEST_AWK_MODE="$1"
	export POSHLI_TEST_AWK_MODE
	case "$(command -v awk)" in
	*/*)
		_test_shim_dir="${TMPDIR:-/tmp}/poshli_shim_awk_$$"
		mkdir -p "$_test_shim_dir" || return 1
		ln -sf "$TEST_DIR/shims/awk" "$_test_shim_dir/awk" || return 1
		PATH="$_test_shim_dir:$PATH"
		export PATH
		;;
	*)
		# shellcheck disable=SC2317  # BusyBox applet shim, invoked indirectly
		awk() {
			case ${POSHLI_TEST_AWK_MODE:-} in
			fail) return 1 ;;
			missing) return 127 ;;
			partial) printf '%s' 'PARTIAL'; return 1 ;;
			invalid) printf '%s' 'INVALID'; return 0 ;;
			garbage) printf '%s' 'GARBAGE'; return 0 ;;
			valid-extra) printf '%s\n%s' 'VALID' 'EXTRA'; return 0 ;;
			empty) return 0 ;;
			*) return 1 ;;
			esac
		}
		;;
	esac
}

_test_shim_od() {
	POSHLI_TEST_OD_MODE="$1"
	export POSHLI_TEST_OD_MODE
	case "$(command -v od)" in
	*/*)
		_test_shim_dir="${TMPDIR:-/tmp}/poshli_shim_od_$$"
		mkdir -p "$_test_shim_dir" || return 1
		ln -sf "$TEST_DIR/shims/od" "$_test_shim_dir/od" || return 1
		PATH="$_test_shim_dir:$PATH"
		export PATH
		;;
	*)
		# shellcheck disable=SC2317  # BusyBox applet shim, invoked indirectly
		od() {
			case ${POSHLI_TEST_OD_MODE:-} in
			fail) return 1 ;;
			missing) return 127 ;;
			partial) printf '%s' '97 98'; return 1 ;;
			empty) return 0 ;;
			truncated) printf '%s' '97 98'; return 0 ;;
			outofrange) printf '%s\n' '97 98 300'; return 0 ;;
			nonnumeric) printf '%s\n' '97 98 x'; return 0 ;;
			extra) printf '%s\n' '97 98 99 100'; return 0 ;;
			*) return 1 ;;
			esac
		}
		;;
	esac
}

_test_shim_wc() {
	POSHLI_TEST_WC_MODE="$1"
	export POSHLI_TEST_WC_MODE
	case "$(command -v wc)" in
	*/*)
		_test_shim_dir="${TMPDIR:-/tmp}/poshli_shim_wc_$$"
		mkdir -p "$_test_shim_dir" || return 1
		ln -sf "$TEST_DIR/shims/wc" "$_test_shim_dir/wc" || return 1
		PATH="$_test_shim_dir:$PATH"
		export PATH
		;;
	*)
		# shellcheck disable=SC2317  # BusyBox applet shim, invoked indirectly
		wc() {
			case ${POSHLI_TEST_WC_MODE:-} in
			missing) return 127 ;;
			wrong) printf '%s\n' '3'; return 0 ;;
			*) return 1 ;;
			esac
		}
		;;
	esac
}

_test_cleanup_shims() {
	rm -rf "${TMPDIR:-/tmp}/poshli_shim_awk_$$" "${TMPDIR:-/tmp}/poshli_shim_od_$$" "${TMPDIR:-/tmp}/poshli_shim_wc_$$"
}

trap '_test_cleanup_shims' 0 INT TERM HUP

# The closed-stdout write-failure tests can only observe anything when the
# shell's printf reports write errors. POSIX requires the printf utility to
# exit non-zero on a write error, but some shells (notably FreeBSD /bin/sh)
# silently ignore it and return 0. The probe closes stdout inside a subshell
# and reports the printf status through fd 3, so it never touches the caller's
# stdout. The failing printf is guarded with "||" so the probe also works when
# a suite runs under "set -e": without that guard the subshell would exit
# before reporting and the probe would misclassify the shell. A non-zero
# printf status (not only 1) is enough, because the library maps any failure
# to its documented status 1. POSHLI_TEST_PRINTF_WERR=1/0 forces the result;
# the harness self-check uses it to exercise the skip branch.
_test_write_fail_probe() {
	case ${POSHLI_TEST_PRINTF_WERR:-} in
	1) return 0 ;;
	0) return 1 ;;
	esac
	_test_wfail_st=$( (
		exec 1>&-
		printf x 2>/dev/null || _test_wfail_printf_status=$?
		printf '%s' "${_test_wfail_printf_status:-0}" >&3
	) 3>&1 )
	[ "$_test_wfail_st" != 0 ] || {
		unset _test_wfail_st _test_wfail_printf_status
		return 1
	}
	unset _test_wfail_st _test_wfail_printf_status
	return 0
}

# Assert a closed-stdout write failure, or record a documented skip when the
# shell's printf cannot report write errors (see _test_write_fail_probe).
# A skip prints one line and does not count as a test, like the existing root
# and locale skips.
_test_assert_write_failure() {
	_test_wfail_actual=$1
	_test_wfail_desc=$2
	if _test_write_fail_probe; then
		assert_status 1 "$_test_wfail_actual" "$_test_wfail_desc"
	else
		printf '  [SKIP] %s [shell printf does not report write errors]\n' "$_test_wfail_desc"
	fi
	unset _test_wfail_actual _test_wfail_desc
}

test_summary() {
	_test_cleanup_shims
	printf '\n========================================\n'
	printf 'Tests run: %d | Passed: %d | Failed: %d\n' \
		"$TESTS_TOTAL" "$TESTS_PASSED" "$TESTS_FAILED"
	printf '========================================\n'

	if [ "$TESTS_FAILED" -eq 0 ]; then
		printf 'ALL TESTS PASSED\n'
		return 0
	else
		printf 'SOME TESTS FAILED\n'
		return 1
	fi
}
