# AGENTS.md

Instructions for AI coding agents working on **Poshli**: a POSIX shell function library, currently version `0.5.0` (pre-stable), distributed as a single bundle (`poshli.sh`) generated from `src/`.

Human-facing docs: `README.md` (public contract), `.github/DEVELOPER.md` (working rulebook, including the Dependency Policy), `ROADMAP.md`. Read the relevant parts before changing code. If this file and those documents disagree, report it instead of guessing.

## Layout

- `src/core.sh`, `src/num.sh`, `src/str.sh`, `src/fs.sh`, `src/encoding.sh`: the sources of truth.
- `poshli.sh`: **generated bundle. Never edit it by hand.** Regenerate it with the project's own mechanism (`make bundle`) and confirm with `make check-bundle`.
- `tests/test_*.sh`: test suites (sources and bundle).
- `tools/gen_case.py`: development-only generator of Unicode case data. Python is never a runtime dependency.

Check the `Makefile` for the current targets (`bundle`, `check-bundle`, `test`, `test-bundle`). If a target mentioned here no longer exists, tell the maintainer.

## Non-negotiable rules

1. **POSIX only at runtime.** Target shells: `dash`, BusyBox `sh`, `bash --posix`. No bashisms, no GNU-only options, no external `base64`, no Python/Perl/Node. Allowed utilities are those specified by POSIX (`awk`, `od`, `wc`, `tr`, `sed`, `grep`, `printf`, ...). Verify an option is POSIX before using it; do not assume.
2. **Do not change the public API** (function names, arguments, output format, return codes) unless the task explicitly says so. Changing an internal implementation must preserve the documented contract and the current behavior.
3. **Priorities, in order:** correctness, portability, determinism, maintainability, simplicity. A non-POSIX exception needs explicit justification and documentation (see DEVELOPER.md, Dependency Policy).
4. **Never fail silently. Fail closed.** On error, return non-zero and emit **no partial output**, unless the documented contract explicitly specifies otherwise. Capture results first and print only on success.
5. **POSIX pipelines report only the last command's status.** Do not rely on `pipefail` or change global shell options. Validate the result instead (for example, compare byte counts against an independent `wc -c`).
6. **Temporaries:** do not introduce temporary variables where plain expansions suffice. When one is necessary, name it `_poshli_<function>_<name>` and `unset` it on **every** path (success, error, write failure).
7. **Return codes:** predicates return `0` (true) or `1` (false); operational functions return `0` on success, `1` for invalid input or failure, and `2` for invalid usage (such as a missing mandatory argument). Preserve the documented and current behavior of each function; a missing argument follows its documented contract (for example `str_empty` treats it as true, and `fs_is_plain_text` keeps `2`). Do not rename or renumber functions for cosmetic uniformity, and do not change return codes without a demonstrated defect and explicit approval.
8. **Shell string limits are real limits:** arguments and variables cannot hold NUL, and `$(...)` strips trailing newlines. Document these limits; never promise what the API cannot deliver.
9. **Locale independence:** results must not depend on the locale (`LC_ALL=C` for `od`, `awk`, `wc` where relevant).

## Code style

- Indent with tabs. Follow the neighboring code and the comment header of existing functions (description, `Returns:`, notes, `Example of use`).
- Public names use module prefixes: `num_`, `str_`, `fs_`, `encoding_`. Each module has a load guard (`_POSHLI_<MODULE>_LOADED`) and must be safe to load repeatedly and in any order.
- Comments explain *why*, especially portability traps (why `od -v`, why `\0nnn` escapes, why the byte-count check exists).

## Tests

- Use the existing helpers (`assert_eq`, `assert_status`, `assert_true`) and follow the style of the current test files. Keep all existing tests passing; do not weaken or delete them to make a change pass.
- Every behavior change needs tests. Use fixed expected values (for example the RFC 4648 vectors); an external tool may serve as a manual oracle but must never be a dependency of the suite.
- Simulate tool failures with shell functions inside a subshell `( ... )`, calling the real tool through `command <tool> "$@"`. For each failure assert both the exact status and an empty stdout.
- Compare binary data through hex (`od`), not through `$(...)`.
- New failure tests must fail against the old code (negative control). A test that cannot fail proves nothing.
- Run the suite on every installed shell (`dash`, `busybox sh`, `bash --posix`), for both sources and bundle. Treat the `awk` implementation as a second, independent matrix: when more than one is installed (GNU awk, `mawk`, `busybox awk`), repeat at least the tests of the awk-based modules with each one. Report the shell matrix and the `awk` matrix separately. Do not drop one artifact because the other passes: sources and bundle are distinct deliverables.
- When a test must pin an exact status, use `assert_status N`; `assert_false` only proves a result different from zero, so do not use it where the contract requires exactly `1`.
- Run `shellcheck -s sh` on the source modules and the bundle when it is available. Keep `# shellcheck shell=sh` in shell files without a shebang. Use only localized, justified suppressions (for example `SC2086` where word splitting is intentional); never use global exclusions or ranges, and do not enable optional checks by default. `SC2034` on `POSHLI_VERSION` is a known, justified warning; do not silence it with a global exclusion. Never edit the generated bundle to preserve a directive: comment lines are stripped during generation.
- Static analysis complements, but does not replace, the real portability matrix. A clean ShellCheck run is not proof of portability.

## Validation tools and packaging

- ShellCheck, `checkbashisms` and `posh` are development and validation tools, never runtime or build dependencies of the library. `checkbashisms` and `posh` are optional pre-publication checks.
- CI runs the test suite with `dash`, BusyBox `sh` and `bash --posix`; sources and bundle are distinct artifacts and both are tested. ShellCheck (blocking) and the `awk` matrix (independent job) are approved additions still pending implementation in CI; see `ROADMAP.md`. Do not describe them as already running. The 2026-11-21 `awk` matrix was executed manually and is not CI coverage.
- Do not run the full shell and `awk` matrix inside `debian/rules`, and do not add ShellCheck or `checkbashisms` to `Build-Depends`. Package validation (`dpkg-checkbuilddeps`, `dpkg-buildpackage`, `lintian`, `uscan`) is a pre-publication step.
- Keep the three installation paths distinct: user installation, local system installation and the Debian package.

## Documentation

- Update `README.md` and function comments whenever a contract or dependency changes.
- Performance and memory figures are **indicative measurements from a given environment**, never guarantees or limits. State which environment and `awk` produced them.
- `ROADMAP.md`: mark an item done only when the maintainer has approved the work, and mark only that item.
- Do not change `POSHLI_VERSION` unless asked. The project follows Semantic Versioning; `0.x` is pre-stable.

## How to work

- Work sequentially. Do not use subagents or parallel tools unless asked.
- **Do not commit or push** unless asked. Leave the working tree for review.
- Decisions already approved in a plan are closed. If you believe one is wrong, report it; do not redesign on your own.
- Keep changes isolated and reviewable. Do not refactor, touch unrelated modules or fix unrelated issues. Report out-of-scope findings in the final summary instead.
- Before replacing an implementation, record the current behavior (inputs, outputs, return codes, timings) as a baseline, and compare against it afterwards.
- Be honest about verification: state exactly which shells and `awk` implementations you ran, and what you could **not** test. Never claim BusyBox, BSD or macOS compatibility that was not actually executed.

## Workflow

- **Plan, then build.** Planning is read-only: it produces or updates `PLAN.md`, lists every open decision with a recommendation and its reasoning, and implements nothing. Building executes only phases of an approved `PLAN.md`, ticks its checkboxes as phases complete, and stops where the plan says to stop.
- **If `PLAN.md` exists, follow it.** If reality contradicts the plan, stop and report; do not improvise or silently change scope.
- **Verify before reporting.** Before declaring a task done, run the verification matrix (shells and `awk` implementations) and include the real results in the final report.
- **Independent review.** Every change gets a review by a different model than the one that wrote it, with the explicit goal of finding problems, before any commit.
- **Commits.** Only when asked. Conventional Commits in English (`feat:`, `fix:`, `docs:`, `chore:`), one logical change per commit. A change to `poshli.sh` goes in the same commit as the `src/` change that produced it. Push only when asked. Never force-push.

## Final report

End every task with: what changed and why; tests run and their real results; shells and tool implementations used; scenarios simulated; known limitations; any discrepancy between code, tests and documentation; and the output of `git status` and `git diff --stat`.

## Known limits

- `encoding_base64_encode` cannot receive NUL (shell arguments cannot hold it); `encoding_base64_decode` can write all 256 byte values (redirect to a file for binary data).

## Current coverage (snapshot as of 0.5.0; update when it changes)

- The full suite (sources and bundle) was re-run **manually on 2026-11-21** in Ubuntu 24.04 with `dash` 0.5.12, `bash` 5.2.21 `--posix`, GNU awk 5.2.1, `mawk` 1.3.4.20240123 and BusyBox 1.36.1: **583/583 tests per configuration, no failures or skips**. GNU awk was verified under `dash` (sources and bundle) and `bash --posix` (bundle); `mawk` and BusyBox `awk` under `dash` and `bash --posix` (sources and bundle); BusyBox `sh` with BusyBox `awk`, `od` and `wc` (sources and bundle); and the full-BusyBox configuration. The verified BusyBox `sh` configuration is BusyBox `sh` + BusyBox `awk` + BusyBox `od`/`wc`; BusyBox `sh` + GNU `awk` was not reproducible because `busybox sh` uses its own `awk` applet. macOS/BSD `awk` and `ksh`/`mksh` remain unverified. This is manual verification, not CI coverage.
- The authoritative statement is the *Testing* section of `README.md`; keep both in sync.
