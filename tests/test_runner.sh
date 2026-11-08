#!/bin/sh
#
# POSHLI Test Runner Framework (POSIX-compliant)
#

TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

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
	fi
	unset _f_status _f_desc
}

test_summary() {
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
