# Poshli Roadmap

Practical, living record of Poshli development: what is done, what is active, and what comes next. Keep it short and current.

> **Technical audit (2026-11-20):** a full audit of `0.5.0` at commit `a957564` found **no critical defects** and judged the architecture sound; no architectural refactor is justified. The verified strengths and the pending local findings are recorded in `PLAN.md`. The audit was a review and verification exercise, **not a certification** of compatibility with every POSIX shell or platform.

## Architectural assets to preserve

These are deliberate design choices to keep unless new evidence and tests justify a change:

- Modular sources in `src/`, distributed as a single generated `poshli.sh` bundle.
- POSIX-first runtime: POSIX shell plus `od`, `awk` and `wc`; no external `base64`, Python, Perl or Node.js at runtime.
- Deterministic byte-oriented UTF-8 transport (`od` numbers → POSIX `awk` → `printf` bytes), independent of the locale.
- Unicode case data generated at development time and pinned in the project.
- Fail-closed behavior and a documented return-code contract for predicates and operational functions.
- A formal dependency policy with every public function classified by level.
- Security review scope: no `eval` in the sources examined, no runtime temporary files, and leading-hyphen handling in `fs_is_plain_text` via `./`.
- Three deliberately distinct installation paths: user installation (`~/.local/lib/poshli`), local system installation (`/usr/local/lib/poshli`) and the Debian package (`/usr/share/poshli`).

## Completed

- [x] Public API standardized with module prefixes (`num_`, `str_`, `fs_`, `encoding_`); unprefixed legacy names removed.
- [x] API naming policy documented (README *Naming Policy*, DEVELOPER.md conventions).
- [x] Semantic Versioning policy documented (README *Versioning Policy*; `0.5.0` consolidation baseline).
- [x] Unicode case conversion (`str_lower`/`str_upper`) with development-time generated, embedded case data (Unicode 15.0.0, pinned; `tools/gen_case.py` is development-only).
- [x] Automated test suite for sources and bundle (`make test`, `make test-bundle`, `make check-bundle`) across `dash`, `busybox sh` and `bash --posix` in CI.
- [x] Initial audit of dependencies and external tools (runtime vs development, documentation claims vs real usage).
- [x] POSIX-first architectural audit (levels: shell/POSIX core, POSIX utilities, explicit exceptions).
- [x] Dependency, determinism and POSIX compatibility analysis (`fs_is_plain_text`, `encoding.sh`, case mapping, return codes).
- [x] Adopt the POSIX-first dependency policy formally (levels: shell/POSIX core, POSIX utilities, optional improvements, explicit exceptions; README *Dependency Policy*, DEVELOPER.md).
- [x] Make `fs_is_plain_text` POSIX and deterministic (documented byte heuristic with POSIX utilities instead of `file(1)`; defined semantics and behavior).
- [x] Replace the Base64 backend with a POSIX-only implementation (`od` + `wc` + `awk` + `printf`), using a single code path with no external fallback.
- [x] Document the dependency separation clearly (per-function dependency classification in README *Dependency Policy*, mapping every public function to the policy levels: the pure POSIX shell functions are identified as level 1, `num_randomize` is classified as POSIX `awk`, and `str_len_bytes` is corrected to `wc` plus `awk` output normalization; there are no level 3 optional improvements and no level 4 exceptions at runtime).
- [x] SPDX license headers and Unicode Character Database attribution (Unicode 15.0.0, Unicode License V3) across sources, tests, tools and documentation; added the license section to README and DEVELOPER.md.
- [x] Initial `debian/` packaging files added to the repository; the package is not built, validated or published.
- [x] Fail-closed behaviour in `str_len`, `str_lower` and `str_upper` when `od` cannot read the input bytes, with tests simulating `od`/`wc` failures.
- [x] Return-code audit (PLAN.md Fase 0) executed against the bundle in `dash`, `bash --posix` and `busybox sh`; baseline saved in `docs/return-codes-baseline.md`.
- [x] Return-code normalization (PLAN.md Fases 1–4): the six `fs_is_*` predicates return `1` when the path argument is missing (D2); README, DEVELOPER.md, CONTRIBUTING.md and tests are aligned; `fs_is_plain_text` remains operational and keeps `2`. Verification re-ran the 136-case Fase 0 audit in the five original configurations, with 11 justified differences (6 from D2, 5 from `b0345be`). Caveat: 17 cells of the reduced baseline have no direct case in the recovered audit script, so its 118-cell coverage is not complete.
- [x] Publish the pending local commits and confirm GitHub Actions CI: `ae2f0a7` and `b0345be` are ancestors of `a957564`, `origin/master` is at `a957564`, and run #28 on that commit succeeded.
- [x] Full technical audit (2026-11-20, GLM 5.3, PLAN mode) against `0.5.0` at `a957564`: no critical defects, sound architecture, 583/583 tests passing in each of 10 documented configurations, 55/55 spike tests per configuration, and a synchronized bundle. Historical evidence for that commit, not a permanent certification. Pending findings are recorded in `PLAN.md` (A1, M1–M5, H1–H7).
- [x] Quality and distribution validation review (2026-11-21): adopted `shellcheck -s sh` as the routine static check, `# shellcheck shell=sh` in shell files without a shebang, and localized justified suppressions only (for example the intentional `SC2086` word splitting in the test runners); no global exclusions and no blanket optional checks. `SC2034` on `POSHLI_VERSION` is a known, justified warning, and static checks complement but do not replace the real portability matrix. `checkbashisms` and `posh` are optional pre-publication tools, never build dependencies. The return-code contract and the documented `fs_is_plain_text` `2` are kept as they are. Decisions recorded in `AGENTS.md` and `.opencode/commands/verify.md`; the CI implementation of ShellCheck and of the `awk` matrix is still pending (see *Next*).
- [x] Reproducibility check of the compatibility matrix (2026-11-21, Ubuntu 24.04): the full suite was re-run manually against sources and bundle with `dash` 0.5.12, `bash` 5.2.21 `--posix`, GNU awk 5.2.1, `mawk` 1.3.4.20240123 and BusyBox 1.36.1; **583/583 tests per configuration, no failures or skips**. This verifies `bash --posix` + `mawk` and `bash --posix` + BusyBox `awk`, closes D-1, and aligns `README.md` and `AGENTS.md`. Manual evidence, not CI coverage; CI still runs only the shell matrix.

## Current

- [ ] Maintainer review of the audit documentation in `PLAN.md` and of the provisional priority order (A1 → M1/M2 → M3 → M4 → M5 → hygiene → portability). D-1 is closed (2026-11-21); the remaining coverage question is CI, not manual verification.

## Next

Ordered by provisional priority. Unless listed under *Approved, pending implementation*, each item is an investigation and validation task, not an approved implementation.

- [ ] A1: reproduce and confirm the stdout write-error behavior of `str_trim`, `_poshli_case_map` (`str_lower`/`str_upper`), `str_len`, `str_len_bytes` and `str_replace`; confirm severity before choosing a fix.
- [ ] M1: reproduce `num_randomize` failures with a simulated missing or failing `awk`; define a documented return status and closed failure behavior.
- [ ] M2: determine the portable numeric range of `num_randomize` and decide whether out-of-range values are rejected explicitly or documented as environment-dependent.
- [ ] M3: separate invalid UTF-8 from tool failures in `str_len` diagnostics, preserving its return contract.
- [ ] M4: add failure-injection tests for `fs_is_plain_text` and `num_randomize`, matching the existing `od`/`wc` shim style.
- [ ] Review ShellCheck suppression coherence (`SC2317` and the informational test warnings) without adding or removing suppressions by default.
- [ ] Resolve hygiene items H1–H5 and H7: temporary-variable naming consistency, `_poshli_case_map` diagnostic prefixes, `opencode.jsonc.bak`, `.editorconfig` final newline, `check-bundle` temporary cleanup and stale document statuses.
- [ ] Validate portability areas not covered by the 2026-11-21 matrix: macOS/BSD `awk`, `ksh`/`mksh`, and non-static or other BusyBox variants.
- [ ] Audit `src/num.sh` for generic utilities needed by future modules.
- [ ] Audit `src/str.sh` for generic utilities needed by future modules.
- [ ] Implement only the approved new utilities for `num.sh` and `str.sh`.
- [ ] Design the minimal API for `term.sh`.
- [ ] Implement `term.sh`.
- [ ] Add simple CLI feedback components: spinners, animated indicators, progress, line updates, basic success/error/warning states.

### Approved, pending implementation

These decisions are closed. They are not yet implemented; do not mark them complete until the change is executed and verified.

- [ ] Add ShellCheck to CI as a blocking check over the source modules (`shellcheck -s sh`), handling the known warnings explicitly (`SC2034` on `POSHLI_VERSION`; the intentional informational warnings in the tests) without global exclusions. `.github/workflows/tests.yml` still runs only the shell matrix.
- [ ] Add the `awk` implementation matrix (GNU awk, `mawk`, BusyBox `awk`) to CI as an independent job, reusing the `tools/spike/run_spike.sh` selection style and weighing runtime cost. The manual matrix of 2026-11-21 does not satisfy this item; CI integration is still pending.
- [ ] Optional pre-publication portability checks: `checkbashisms` and `posh`, never as build dependencies.

## Later

- [ ] Debian packaging, before publishing: replace the Unicode License stanza in `debian/copyright` with the full applicable license text and the correct attribution and year; first verify which license version corresponds to the Unicode data used.
- [ ] Debian packaging, before publishing: review `Standards-Version` and update it only after checking the requirements of the target version.
- [ ] Debian packaging, before publishing: run `dpkg-checkbuilddeps`, build with `dpkg-buildpackage`, validate with `lintian`, and run `uscan` when applicable. The initial `debian/` files are in the repository, but the package is not built, validated or published.
- [ ] Keep the review of distribution requirements and dependencies (Essential vs declared dependencies, LGPL-3.0-only vs -or-later) part of the packaging review.
- [ ] Keep `debian/rules` limited to bundle synchronization plus `make test`/`test-bundle`: do not run the full shell and `awk` matrix there, and do not add ShellCheck or `checkbashisms` to `Build-Depends`. Package validation stays a pre-publication step.
- [ ] Refresh performance and memory figures with new measurements, stating the environment and `awk` implementation; current figures are indicative only.
- [ ] Evaluate more advanced terminal functionality.
- [ ] Evaluate whether a TUI layer makes sense.

## Roadmap maintenance

1. Before starting a new phase, review `ROADMAP.md` and the relevant sections of `PLAN.md`.
2. When completing a task:
	- run the corresponding tests;
	- review the changes;
	- commit when appropriate;
	- update the roadmap status.
3. Keep `Current` focused only on active work.
4. Do not add unnecessary speculative tasks.
5. Do not mark an audit finding resolved without the reproduction and verification evidence required by `PLAN.md`.
6. Keep the distinction between “designed for” and “verified on” explicit.
