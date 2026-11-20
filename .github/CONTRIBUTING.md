# Contributing to POSHLI

Thank you for your interest in contributing to **POSHLI**! We welcome bug reports, test improvements, documentation updates, and new functions that adhere to our design principles.

---

## Contribution Workflow

1. **Fork and Clone**: Fork the repository and create your feature branch:
   ```sh
   git checkout -b feature/my-new-function
   ```

2. **Follow Design Rules**:
   - Read and adhere to the guidelines in [DEVELOPER.md](DEVELOPER.md).
   - Use the module-prefixed naming convention (`num_is_integer`, `str_trim`, etc.); see the Naming Policy in [README.md](../README.md).
   - Classify the version impact of your change (none / PATCH / MINOR / MAJOR); see the Versioning Policy in [README.md](../README.md).
   - Ensure strict POSIX compatibility and avoid non-standard GNU/BSD options.
   - Use standard `unset variable` (no `-v`) for any temporary variables.

3. **Add Tests**:
   - Add unit tests for your function in the appropriate file under `tests/` (`test_num.sh`, `test_fs.sh`, or `test_str.sh`).
   - Cover normal cases, edge cases (empty strings, leading hyphens, whitespace), and missing argument checks: predicates return `1`; operational functions return `2` for invalid usage.

4. **Verify All Tests**:
   ```sh
   make test
   make test-bundle
   ```
   All test suites must pass 100%.

5. **Generate the Bundle**:
   If you modified files in `src/`, rebuild and verify `poshli.sh`:
   ```sh
   make bundle
   make check-bundle
   ```

6. **Submit a Pull Request**:
   - Provide a clear description of the problem solved or the function added.
   - State the expected version impact (none / PATCH / MINOR / MAJOR).
   - Reference any relevant issues.

---

## Code of Conduct

All contributors are expected to adhere to our [Code of Conduct](CODE_OF_CONDUCT.md).
