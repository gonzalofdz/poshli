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
- [x] SPDX license headers and Unicode Character Database attribution (Unicode 15.0.0, Unicode-DFS-2016) across sources, tests, tools and documentation; added the license section to README and DEVELOPER.md.
- [x] Initial `debian/` packaging files added, built and validated (`dpkg-checkbuilddeps`, `dpkg-buildpackage -us -uc -F` with `DEB_BUILD_OPTIONS=nocheck`, `lintian --profile debian`), tagged `v0.5.0` at `da77bf7`, and published on GitHub with 7 verified assets (2026-11-23).
- [x] Fail-closed behaviour in `str_len`, `str_lower` and `str_upper` when `od` cannot read the input bytes, with tests simulating `od`/`wc` failures.
- [x] Return-code audit (PLAN.md Fase 0) executed against the bundle in `dash`, `bash --posix` and `busybox sh`; baseline saved in `docs/return-codes-baseline.md`.
- [x] Return-code normalization (PLAN.md Fases 1–4): the six `fs_is_*` predicates return `1` when the path argument is missing (D2); README, DEVELOPER.md, CONTRIBUTING.md and tests are aligned; `fs_is_plain_text` remains operational and keeps `2`. Verification re-ran the 136-case Fase 0 audit in the five original configurations, with 11 justified differences (6 from D2, 5 from `b0345be`). Caveat: 17 cells of the reduced baseline have no direct case in the recovered audit script, so its 118-cell coverage is not complete.
- [x] Publish the pending local commits and confirm GitHub Actions CI: `ae2f0a7` and `b0345be` are ancestors of `a957564`, `origin/master` is at `a957564`, and run #28 on that commit succeeded.
- [x] Full technical audit (2026-11-20, GLM 5.3, PLAN mode) against `0.5.0` at `a957564`: no critical defects, sound architecture, 583/583 tests passing in each of 10 documented configurations (the suite size at that commit), 55/55 spike tests per configuration, and a synchronized bundle. Historical evidence for that commit, not a permanent certification. Pending findings are recorded in `PLAN.md` (A1, M1–M5, H1–H7).
- [x] Quality and distribution validation review (2026-11-21): adopted `shellcheck -s sh` as the routine static check, `# shellcheck shell=sh` in shell files without a shebang, and localized justified suppressions only (for example the intentional `SC2086` word splitting in the test runners); no global exclusions and no blanket optional checks. `SC2034` on `POSHLI_VERSION` is a known, justified warning, and static checks complement but do not replace the real portability matrix. `checkbashisms` and `posh` are optional pre-publication tools, never build dependencies. The return-code contract and the documented `fs_is_plain_text` `2` are kept as they are. Decisions recorded in `AGENTS.md` and `.opencode/commands/verify.md`; the CI integration of both checks is recorded in the CI entry below.
- [x] Reproducibility check of the compatibility matrix (2026-11-21, Ubuntu 24.04): the full suite was re-run manually against sources and bundle with `dash` 0.5.12, `bash` 5.2.21 `--posix`, GNU awk 5.2.1, `mawk` 1.3.4.20240123 and BusyBox 1.36.1; **611/611 tests per configuration, no failures or skips**. This verifies GNU awk, `mawk` and BusyBox `awk` under both `dash` and `bash --posix` (sources and bundle), closes D-1, and aligns `README.md` and `AGENTS.md`. The suite grew from 583 to 611 tests with the regression tests added in `dce826d`. Manual evidence from 2026-11-21; the `awk` dimension is now also covered by CI (see the CI integration entry below).
- [x] CI integration (2026-11-21): added a blocking `shellcheck -s sh` job with a checked-in baseline (`tools/ci/shellcheck.sh`, `tools/ci/shellcheck-baseline.txt`, ShellCheck 0.9.0 pinned in the workflow) and an independent `awk` matrix job (GNU awk, `mawk`, BusyBox `awk` under `dash`, sources and bundle) that verifies the selected implementation before running the suite. Verified in GitHub Actions run #30 (all jobs green).
- [x] M3: separate invalid UTF-8 from tool failures in `str_len` diagnostics, preserving its return contract. Implemented with the reserved `INVALID` sentinel and a distinct `awk` failure diagnostic (`could not count code points`), with regression tests across the shell and `awk` matrix; the bundle was regenerated and synchronized.
- [x] A1: handle stdout write failures in `str_trim`, `_poshli_case_map` (`str_lower`/`str_upper`), `str_len`, `str_len_bytes` and `str_replace`. Functions fail closed when stdout write fails (status 1, no partial output, temporary variables cleaned up); verified with regression tests in `tests/test_str.sh` across the matrix.
- [x] Added `make check-bashisms` (optional pre-publication check): `checkbashisms -f -p` over `src/*.sh`, `poshli.sh` and `tests/*.sh`, skipping with exit 0 when the tool is absent. First run (checkbashisms 2.23.7ubuntu0.2): 0 real bashisms, 2 distinct false positives documented in `AGENTS.md` (the `source` word inside a diagnostic string, and the `.` case pattern, each reported in the source and again in the bundle), plus expected no-shebang advisories for the `src/` modules.
- [x] Evaluated `posh` 0.14.1 as an additional validation shell and **discarded it**: it runs the `num`/`fs` suites correctly but hangs (infinite loop) on `str_replace` with glob metacharacters (`.`, `[a]`, `?`, `*`) because `posh` mishandles quoted wildcards in `case`/`%%`/`#` patterns — a `posh` non-conformance, not a Poshli defect. No actionable value over the existing shells plus ShellCheck/checkbashisms.
- [x] Debian packaging: `Standards-Version` reviewed and updated to 4.7.4.1, according to `debian/control`.
- [x] Verified publication of POSHLI 0.5.0 (2026-11-23): annotated tag `v0.5.0` → `da77bf7`; CI run #32 green; GitHub Release published with the 6 Debian artifacts and `SHA256SUMS` (7 assets, `sha256sum -c` 6/6 OK, byte-for-byte match); Lintian reported only the two expected warnings (`initial-upload-closes-no-bugs`, `newer-standards-version`); draft release `v1.0.0` was left untouched at that time (removed later in G5).
- [x] M1: normalize `awk` failures in `num_randomize` to status `1`, with clear stderr diagnostics and no partial stdout; reproduced in `dash`, `bash --posix` and BusyBox `sh` before the fix and covered by shim tests.
- [x] M2: establish and document the portable limit range `1..2147483647`; zero is rejected without a shell numeric comparison, and out-of-range values return `1` without leaking shell diagnostics. The maximum reflects the `printf "%d"` overflow observed in BusyBox `awk` at `2147483648`.
- [x] M4a: add failure-injection and boundary tests for `num_randomize` (immediate failure, status `127`, partial output, maximum, maximum + 1 and a huge limit); the negative control failed 6 tests against the old code. M4 remains open for `fs_is_plain_text` (M4b).
- [x] M4b: make `fs_is_plain_text` fail closed on `od`/`awk` failures, distinguish tool failures from negative results via stderr, and validate the exact `VALID`/`INVALID` sentinel; added 13 shim tests (11 failed against the old code) and closed M4.
- [x] H1: normalize library temporaries to `_poshli_<function>_<name>` in `str.sh` and `encoding.sh`; align `DEVELOPER.md` and keep test fixtures out of the convention.
- [x] H2: make `_poshli_case_map` diagnostics use the public `str_lower`/`str_upper` names; added two tests with a negative control (2 failures against the old code).
- [x] H3: verify that `opencode.jsonc.bak` no longer exists; no ignore rule or deletion was needed.
- [x] H4: add the missing final newline to `.editorconfig` (verified `0a`).
- [x] H5: extend the `check-bundle` trap to `0 1 2 3 6 15` and make `make clean` remove `poshli.sh.check.*`; document the untrappable `SIGKILL`/`SIGSTOP` limitation.
- [x] H6/SC2317: use inline ShellCheck suppressions in all four test files, remove the file-level suppression, and regenerate the baseline with 0 `SC2317` entries.
- [x] H7: verify there are no current stale "pending push" claims; historical references in `PLAN.md` remain accurate.
- [x] G4 local portability validation (2026-11-24): the 634-test suite passed under mksh 59c (GNU awk and mawk, 634/634), under BusyBox 1.35.0 static x86_64-linux-musl with its own `sh`/`awk`/`od`/`wc` (634/634), and under ksh93u+m 1.0.8 (GNU awk and mawk, 634/634) after moving shell-function pipeline shims to executable test shims. The consolidated harness (external `awk`/`od` shims, fd-3 closed-stdout checks and corrected cleanup assertions) was re-verified with **26 executions, 634/634, no failures**. Linux CI now defines four jobs for `ksh93`/`mksh` × GNU awk/`mawk`; `portability.yml` prepares macOS 15/26 and FreeBSD 15.1 runs with the system shells and awk. No CI run result is recorded yet for these jobs. macOS/BSD remain unverified.
- [x] G5 distribution and dependency closure (2026-11-24): Debian revision `0.5.0-2` declares `Build-Depends: awk` and `Depends: mawk | gawk | original-awk`; binary build with tests passed 634/634, `dpkg-checkbuilddeps` and Lintian are clean. README documents the dependency, local Debian installation and `/usr/share/poshli/poshli.sh`. The local and remote `v1.0.0` tag and its draft release were removed; `v0.5.0` and its published release remain intact, and `uscan` no longer reports `v1.0.0`. The `0.5.0-2` binary was not published; `0.5.0-1` remains the release asset.

## Current

- [ ] Recorded execution of the four prepared Linux `ksh93`/`mksh` × GNU awk/`mawk` CI jobs and external macOS/BSD portability validation. D-1, A1, M1, M2, M3, M4, M5, D-4 and H1–H7 are closed (2026-11-21/24); G4 is fully validated locally but has no CI or macOS/BSD evidence yet.

## Next

Ordered by provisional priority; each item is an investigation and validation task, not an approved implementation.

- [ ] Validate macOS/BSD: macOS 15/26 `/bin/sh` (bash 3.2) with BWK awk, and FreeBSD 15.1 `/bin/sh` with BSD awk, using the scheduled/manual portability workflow. OpenBSD and NetBSD still need a separate job or VM.
- [ ] Audit `src/num.sh` for generic utilities needed by future modules.
- [ ] Audit `src/str.sh` for generic utilities needed by future modules.
- [ ] Implement only the approved new utilities for `num.sh` and `str.sh`.
- [ ] Design the minimal API for `term.sh`.
- [ ] Implement `term.sh`.
- [ ] Add simple CLI feedback components: spinners, animated indicators, progress, line updates, basic success/error/warning states.

## Later

- [x] Debian packaging: `debian/copyright` includes the `Unicode-DFS-2016` copyright and permission notice with the correct attribution (© 1991-2022 Unicode, Inc.); it points to the Unicode Terms of Use for the definitions of Data Files and Software. Verified that Unicode 15.0.0 was published on 2022-09-13 under DFS-2016; the later Unicode License v3 (2023) is not retroactive and does not replace it for these data.
- [x] Debian packaging: validation on the definitive release tag (`v0.5.0` = `da77bf7`) and publication (GitHub Release, 2026-11-23, 7 assets with verified checksums).

> **Note (0.5.0 packaging):** `initial-upload-closes-no-bugs` is expected because Poshli 0.5.0 is not intended for the official Debian archive. Do not open an ITP or add an override for this tag.

- [x] Distribution requirements and dependencies reviewed (2026-11-24): `coreutils`/`dash` are Essential; `awk` is declared via `Build-Depends: awk` and `Depends: mawk | gawk | original-awk`; LGPL-3.0-only and Unicode-DFS-2016 verified.
- [x] `debian/rules` remains limited to bundle synchronization plus `make test`/`test-bundle`; it does not run the full shell/`awk` matrix, ShellCheck or checkbashisms, and none of those tools was added to `Build-Depends`.
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
