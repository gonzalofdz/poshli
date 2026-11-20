# Poshli Roadmap

Practical, living record of Poshli development: what is done, what is active, and what comes next. Keep it short and current.

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
- [x] SPDX license headers and Unicode Character Database attribution (Unicode 15.0.0, Unicode License V3) across sources, tests, tools and documentation; added the license section to README and DEVELOPER.md (local commit `ae2f0a7`, pending push).
- [x] Initial `debian/` packaging files added to the repository (local commit `ae2f0a7`, pending push); the package is not built, validated or published.
- [x] Fail-closed behaviour in `str_len`, `str_lower` and `str_upper` when `od` cannot read the input bytes, with tests simulating `od`/`wc` failures (local commit `b0345be`, pending push).

## Current

- [ ] Publish the two local commits `ae2f0a7` and `b0345be` and confirm GitHub Actions CI.

## Next

- [ ] Review and normalize return-code semantics (0 true/success, 1 false/invalid input, 2 not evaluable) and align README, DEVELOPER.md, CONTRIBUTING.md and tests.
- [ ] Update documentation and tests for the changes above (Dependencies section, per-function contracts).
- [ ] Audit `src/num.sh` for generic utilities needed by future modules.
- [ ] Audit `src/str.sh` for generic utilities needed by future modules.
- [ ] Implement only the approved new utilities for `num.sh` and `str.sh`.
- [ ] Design the minimal API for `term.sh`.
- [ ] Implement `term.sh`.
- [ ] Add simple CLI feedback components: spinners, animated indicators, progress, line updates, basic success/error/warning states.

## Later

- [ ] Evaluate more advanced terminal functionality.
- [ ] Evaluate whether a TUI layer makes sense.
- [ ] Validate and build the Debian package, review distribution requirements and dependencies (Essential vs declared dependencies, `debian/copyright` attribution, LGPL-3.0-only vs -or-later) and upload it. The initial `debian/` files are already in the repository, but the package is not built, validated or published.

## Roadmap maintenance

1. Before starting a new phase, review `ROADMAP.md`.
2. When completing a task:
	- run the corresponding tests;
	- review the changes;
	- commit when appropriate;
	- update the roadmap status.
3. Keep `Current` focused only on active work.
4. Do not add unnecessary speculative tasks.
