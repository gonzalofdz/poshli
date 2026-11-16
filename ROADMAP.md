# Poshli Roadmap

Practical, living record of Poshli development: what is done, what is active, and what comes next. Keep it short and current.

## Completed

- [x] Public API standardized with module prefixes (`num_`, `str_`, `fs_`, `encoding_`); unprefixed legacy names removed.
- [x] API naming policy documented (README *Naming Policy*, DEVELOPER.md conventions).
- [x] Semantic Versioning policy documented (README *Versioning Policy*; `1.0.0` consolidation baseline).
- [x] Unicode case conversion (`str_lower`/`str_upper`) with development-time generated, embedded case data (Unicode 15.0.0, pinned; `tools/gen_case.py` is development-only).
- [x] Automated test suite for sources and bundle (`make test`, `make test-bundle`, `make check-bundle`) across `dash`, `busybox sh` and `bash --posix` in CI.
- [x] Initial audit of dependencies and external tools (runtime vs development, documentation claims vs real usage).
- [x] POSIX-first architectural audit (levels: shell/POSIX core, POSIX utilities, explicit exceptions).
- [x] Dependency, determinism and POSIX compatibility analysis (`fs_is_plain_text`, `encoding.sh`, case mapping, return codes).
- [x] Adopt the POSIX-first dependency policy formally (levels: shell/POSIX core, POSIX utilities, optional improvements, explicit exceptions; README *Dependency Policy*, DEVELOPER.md).
- [x] Make `fs_is_plain_text` POSIX and deterministic (documented byte heuristic with POSIX utilities instead of `file(1)`; defined semantics and behavior).

## Current

- [ ] Document the dependency separation clearly (the policy levels are documented; the per-function classification completes once Base64 is corrected):
	- shell / pure POSIX;
	- POSIX utilities;
	- optional extensions or improvements;
	- explicit exceptions.

## Next

- [ ] Replace the Base64 backend with a POSIX-only implementation (`od` + `awk` + `printf`), single code path with no external fallback, if it remains the approved architectural solution after implementation and review.
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
- [ ] Investigate and prepare Debian packaging.
- [ ] Review distribution requirements, dependencies and metadata for Debian (Essential vs declared dependencies, `debian/copyright` attribution, LGPL-3.0-only vs -or-later).

## Roadmap maintenance

1. Before starting a new phase, review `ROADMAP.md`.
2. When completing a task:
	- run the corresponding tests;
	- review the changes;
	- commit when appropriate;
	- update the roadmap status.
3. Keep `Current` focused only on active work.
4. Do not add unnecessary speculative tasks.
