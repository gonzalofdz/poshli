# POSHLI Developer Documentation

## 1. Welcome

Thank you for contributing to the **POSHLI** project. All contributions that align with our core principles—clarity, portability, simplicity, and ergonomics—are warmly welcomed.

---

## 2. Target Shell and Platform

- **Primary Target**: POSIX-compatible `/bin/sh` (DASH, BusyBox `sh`, `bash --posix`).
- **Standard**: Strict conformance to the POSIX Shell Command Language (IEEE Std 1003.1).
- **Test Platform**: Linux is the primary continuous-integration platform. macOS and the BSDs are supported targets where the required standard utilities behave portably, but they are not all continuously tested.
- **Portability Principle**: Prefer POSIX syntax and widely available standard utilities. Avoid shell-specific extensions and undocumented tool behavior. Dependency decisions follow the POSIX-first policy in section 4.

---

## 3. Function Design Principles

Every POSHLI function must strictly follow one of two predictable behaviors:

1. **Predicate Functions** (`num_is_*`, `fs_is_*`, `str_empty`, `str_contains`, `str_starts_with`, `str_ends_with`):
   - Silent: do not print anything to `stdout` or `stderr`.
   - Return `0` for true / condition met.
   - Return `1` for false / condition not met.
   - Return `2` if required arguments are missing.

2. **Transformer / Producer Functions** (`str_trim`, `str_lower`, `str_upper`, `str_len`, `str_len_bytes`, `str_replace`):
   - Print the processed result to `stdout` using `printf '%s\n'`.
   - Return `0` on success.
   - Return `1` if the input is invalid or the operation cannot be performed correctly.
   - Return `2` if required arguments are missing.

---

## 4. Dependency Policy (POSIX-first)

The architectural policy for dependencies, portability and external tools is **POSIX-first**:

> Poshli prioritizes implementations based on POSIX shell and utilities specified by POSIX. Non-POSIX dependencies must be avoided whenever a reasonable, maintainable POSIX alternative exists.

This does **not** mean "pure shell". POSIX utilities such as `awk`, `sed`, `grep`, `tr`, `od`, `printf` or `wc` are part of the allowed model when they provide a clear advantage. The public summary lives in the *Dependency Policy* section of `README.md`; this section is the working rulebook.

### 4.1 Dependency levels

1. **POSIX shell / core**: small, clear operations implemented directly with POSIX shell when reasonable. Do not create unnecessary external processes for trivial operations.
2. **POSIX utilities**: tools specified by POSIX (`awk`, `sed`, `grep`, `tr`, `od`, `wc`, ...) when they provide greater robustness, greater clarity, or capabilities that would be unnecessarily complex in pure shell. Do not reinvent mature tools merely to avoid running an external process.
3. **Optional improvements**: non-POSIX tools may be used only when they provide a clearly justified improvement: performance, experience, or explicitly additional capabilities. They must never silently change the basic semantics of a function according to the tools installed: the same function with the same arguments must have deterministic semantics within its documented contract.
4. **Explicit exceptions**: when no reasonable, maintainable POSIX alternative exists, a non-POSIX dependency may exist when it is:
   - explicitly documented;
   - justified;
   - limited in scope;
   - never failing silently;
   - explicit about what happens when the dependency is unavailable.

   An exception must not automatically become a global dependency of the whole library when it only affects one feature. Current exceptions and pending corrections are listed in *Current dependency status* of the *Dependency Policy* section in `README.md`.

   Every public function must be classified in the *Per-function dependency classification* table of `README.md`; update that table whenever a function's external tool usage changes.

### 4.2 Criteria for introducing a dependency

Before introducing an external tool, evaluate:

1. Can the operation be done simply and robustly with POSIX shell?
2. Does an adequate POSIX utility exist?
3. Would the POSIX alternative be reasonably maintainable?
4. Does the external tool provide a real advantage in correctness, robustness, performance, or capability?
5. Does it introduce an unnecessary runtime dependency?
6. Can it affect determinism?
7. How does the feature behave when the tool is unavailable?

### 4.3 Priorities

POSIX is not pursued at any cost. The architectural order of priorities is:

```text
correctness
→ portability
→ determinism
→ maintainability
→ simplicity
```

A huge, fragile, or hard-to-maintain POSIX implementation is not automatically better than a well-justified external exception.

### 4.4 Determinism

> Optional dependencies must not silently change the semantics of an existing function.

An optional improvement may speed up an implementation, but the same input must not produce an incompatible result depending on the machine. If an additional capability requires another tool, it must be exposed or documented explicitly as such.

### 4.5 Practical rules for standard tools

- **Pragmatic POSIX**: Leverage standard POSIX utilities (`awk`, `sed`, `od`, `wc`, `tr`, `test`) when they provide a clean, tested, and reliable solution.
- **Pure Shell When Practical**: Use standard shell built-in expansions (`case`, `${#var}`, `${var#pattern}`, `${var%pattern}`) for operations that are faster, simpler, and zero-fork.
- **No Non-Standard GNU Extensions**: Do not use non-POSIX options such as `sed --posix`, `awk --posix`, or `expr length`.
- **Normalize External Output**: Standard utilities may have implementation-specific formatting. For example, BSD and macOS `wc` pad counts with leading blanks. When parsing external output, normalize it explicitly instead of assuming a clean format.
- **Never Use `echo`**: `echo` behavior with flags (like `-n`) or backslashes is non-portable across shells. Always use `printf '%s\n' "$var"` or `printf '%s' "$var"`.

---

## 5. Naming and Variables

- **Function Names**:
  - Lowercase with underscores (`snake_case`).
  - Every public function carries its module prefix (`num_`, `str_`, `fs_`, `encoding_`); see the Naming Policy section in `README.md`.
  - Short, intuitive, and descriptive: `num_is_integer`, `fs_is_file`, `str_trim`, `str_lower`.
  - Avoid overly verbose or hierarchical names (e.g. use `fs_is_dir`, not `poshli_fs_is_directory`).
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

---

## 8. Architecture and Module Layout

- `src/` contains the modular source files (`core.sh`, `num.sh`, `fs.sh`, `case_data.sh`, `str.sh`, `encoding.sh`). Each module is self-contained and uses a load guard so it can be sourced independently and repeatedly.
- `src/case_data.sh` is generated data (Unicode case mapping) produced by `tools/gen_case.py`; regenerate it with `make case-data`, never edit it by hand. The data is pinned to Unicode 15.0.0: the generator refuses to run if the Python interpreter embeds a different Unicode version, so the data never changes silently. Following a new Unicode version is a deliberate act (update the pin in `tools/gen_case.py` and regenerate).
- `poshli.sh` is the generated Core bundle. It is produced by the Makefile from the module list in `BUNDLE_SOURCES`; never edit it by hand.
- Bundles are concatenations, not loaders. Do not introduce relative-path sourcing (`. ./src/num.sh`): it depends on the current working directory and breaks installation and vendoring. POSIX shell also lacks a portable way to resolve the directory of a sourced file.
- New general-purpose modules belong in `src/` and are added to `BUNDLE_SOURCES`.
- Specialized modules with extra dependencies (for example cryptography or networking) should be distributed as separate optional bundles, not added to the Core bundle.
- Each generated bundle must use a unique top-level load guard so that loading more than one bundle is safe.
- Keep the public API stable. Adding functions is fine; changing or removing existing functions requires a compatibility review.

---

## 9. `tools/spike/` (Development Verification Only)

- `tools/spike/` holds `run_spike.sh` and `roundtrip_spike.sh`, a self-contained technical spike that proves the portable UTF-8 byte-transport technique behind the Unicode support in `src/str.sh` (UTF-8 bytes → `od` numbers → POSIX `awk` → `printf '%b'` bytes).
- It is a development/verification tool: **not part of the runtime**, **not public API**, and not wired into `make test`, `make test-bundle`, or CI. It is run manually and independently.
- Its purpose is to verify the byte-exact UTF-8 round-trip and its portability across the supported shells (dash, BusyBox `sh`, `bash --posix`), locales, and the BusyBox `od`/`awk` applets.
- Run the full matrix:

  ```sh
  tools/spike/run_spike.sh
  ```

  or a single shell: `dash tools/spike/roundtrip_spike.sh` (also `busybox sh ...` or `bash --posix ...`).
