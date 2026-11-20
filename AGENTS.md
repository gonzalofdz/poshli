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
7. **Return codes:** the documented convention is that predicates return 0/1 and operational functions return 1 for invalid input or failure, and 2 for invalid usage (such as a missing mandatory argument). Do not assume every function already follows it: preserve the documented and current behavior of each function. A global normalization of return codes is a pending roadmap item: do not change the policy as a side effect.
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
- Run the suite on every installed shell (`dash`, `busybox sh`, `bash --posix`), for both sources and bundle. Treat the `awk` implementation as a second, independent matrix: when more than one is installed (GNU awk, `mawk`, `busybox awk`), repeat at least the tests of the awk-based modules with each one. Report the shell matrix and the `awk` matrix separately.
- Run `shellcheck -s sh` if available.

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

- The full suite (sources and bundle) has been run with GNU awk 5.2.1 under `dash` and `bash --posix`, with `mawk` 1.3.4 under `dash`, and with BusyBox `awk` 1.36.1 under `dash` and BusyBox `sh`. The combinations `mawk` + `bash --posix` and BusyBox `awk` + `bash --posix` have not been verified. macOS and BSD `awk` are not covered by tests.
- The authoritative statement is the *Testing* section of `README.md`; keep both in sync.
