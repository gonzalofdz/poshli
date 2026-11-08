# POSHLI Developer Documentation

## 1. Welcome

Thank you for contributing to the **POSHLI** project. All contributions that align with our core principles—clarity, portability, simplicity, and ergonomics—are warmly welcomed.

---

## 2. Target Shell and Platform

- **Primary Target**: Linux with `/bin/sh` (typically DASH or BusyBox `sh`).
- **Standard**: Strict conformance to the POSIX Shell Command Language (IEEE Std 1003.1).
- **Secondary Goal**: Compatibility across other POSIX-compliant systems (FreeBSD, OpenBSD, NetBSD, macOS) whenever it does not add unnecessary complexity.

---

## 3. Function Design Principles

Every POSHLI function must strictly follow one of two predictable behaviors:

1. **Predicate Functions** (`is_*`, `starts_with`, `ends_with`, `contains`):
   - Silent: do not print anything to `stdout` or `stderr`.
   - Return `0` for true / condition met.
   - Return `1` for false / condition not met.
   - Return `2` if required arguments are missing.

2. **Transformer / Producer Functions** (`trim`, `lower`, `upper`, `str_len`, `str_replace`):
   - Print the processed result to `stdout` using `printf '%s\n'`.
   - Return `0` on success.
   - Return `2` if required arguments are missing.

---

## 4. Use of Standard Tools & Built-ins

- **Pragmatic POSIX**: Leverage standard POSIX utilities (`tr`, `sed`, `od`, `test`) when they provide a clean, tested, and reliable solution.
- **Pure Shell When Practical**: Use standard shell built-in expansions (`case`, `${#var}`, `${var#pattern}`, `${var%pattern}`) for operations that are faster, simpler, and zero-fork.
- **No Non-Standard GNU Extensions**: Do not use non-POSIX options such as `sed --posix`, `awk --posix`, or `expr length`.
- **Never Use `echo`**: `echo` behavior with flags (like `-n`) or backslashes is non-portable across shells. Always use `printf '%s\n' "$var"` or `printf '%s' "$var"`.

---

## 5. Naming and Variables

- **Function Names**:
  - Lowercase with underscores (`snake_case`).
  - Short, intuitive, and descriptive: `is_integer`, `is_file`, `trim`, `lower`.
  - Avoid overly verbose or hierarchical names (e.g. use `is_dir`, not `poshli_fs_is_directory`).
- **Temporary Variables**:
  - The `local` keyword is **not** defined in POSIX IEEE 1003.1. Do not use `local`.
  - Temporary variables must use a distinct private prefix (e.g., `_trim_str`, `_in_val`).
  - Every temporary variable **must** be explicitly unset before the function returns using standard `unset variable` (do not use `unset -v`).
  - Prefer zero-variable pattern matching when possible.
- **Strict Quoting**:
  - Always quote variable expansions: `"$1"`, `"$@"` to prevent unintended word splitting and pathname expansion.

---

## 6. Code Formatting

- **Indentation**: Tab characters (configured to 4 spaces equivalence).
- **Line Endings**: LF (Unix-style).
- **Line Length**: Wrap code and comments at approximately 100 characters.
- **Function Declaration Syntax**:
  ```sh
  function_name() {
	[ $# -ge 1 ] || return 2
	# ...
  }
  ```

---

## 7. Testing Requirements

Every function added or modified must include unit tests in `tests/`:
1. Normal valid cases.
2. Edge cases (empty strings `""`, spaces, special characters, leading hyphens `-n`).
3. Argument validation checks (verifying status `2` on missing arguments).
4. Both `make test` (modular sources) and `make test-bundle` (bundled `poshli.sh`) must pass with 100% success.
