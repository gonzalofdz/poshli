# POSHLI

**POSHLI** (*POSIX Shell Library*) is a lightweight, general-purpose shell library built around portable POSIX shell syntax and widely available standard utilities. It provides reusable, ergonomic functions for automation, text processing, validation, and everyday scripting on Linux, macOS, BSD, WSL, Cygwin, and other POSIX-compatible Unix-like environments.

---

## Features

- **Portable POSIX shell**: Designed and tested against standard `/bin/sh` interpreters, including `dash` (Debian/Ubuntu default `/bin/sh`), `busybox sh`, and `bash --posix`, without relying on shell-specific extensions.
- **General purpose and portable**: Linux is the primary continuous-integration platform. macOS, BSD, WSL, and Cygwin are supported targets where the required standard utilities behave portably; they are not all continuously tested, so platform-specific behavior may vary.
- **Module-namespaced API**: Every public function carries its module prefix (`num_is_integer`, `str_trim`, `fs_is_file`, `encoding_base64_encode`), so names are predictable and collisions with user code are unlikely. See [Naming Policy](#naming-policy).
- **Self-contained bundle**: Distributed as a single file (`poshli.sh`) ready for direct inclusion or project vendoring.
- **Predictable return codes**: Boolean predicates return `0` (true) or `1` (false), and never return `2`; an absent, empty, or invalid input is treated as false when the predicate can answer the question. Operational functions return `1` when the input is invalid or the operation cannot be performed correctly, and may return `2` for invalid usage, such as a missing mandatory argument.
- **Unicode-aware helpers**: `str_len` counts Unicode code points in valid UTF-8 independently of the locale and rejects invalid UTF-8. `str_lower`/`str_upper` apply Unicode case mapping (Latin, Greek and Cyrillic guaranteed) with data generated into the library itself, so the result is identical in every locale and shell and cannot vary between conforming `awk` implementations (see [Testing](#testing) for the `awk` implementations actually verified); valid code points without a mapping (emoji, CJK, symbols) are preserved unchanged and invalid UTF-8 is rejected with status `1`.
- **Minimal dependencies (POSIX-first)**: Built around the POSIX shell and standard POSIX utilities (`od`, `awk`, `wc`) following the [Dependency Policy](#dependency-policy). No non-POSIX tool is needed at runtime: Base64 encoding and decoding are implemented with `od`, `wc`, `awk` and the shell `printf`, without the external `base64` command. Case mapping works over numeric code points with data generated at development time (Python is a development-only tool): the runtime needs no Unicode database, no extra tool, and no Unicode-aware `awk`.

---

## Installation

### User Installation (Default, no `sudo` required)

By default, POSHLI installs to `~/.local/lib/poshli/`:

```sh
git clone https://github.com/gonzalofdz/poshli.git
cd poshli
make install
```

### Global System Installation (Optional)

To install system-wide under `/usr/local/lib/poshli/`:

```sh
sudo make install PREFIX=/usr/local
```

### Debian Package (Optional)

The repository also provides a Debian binary package. It is not part of the Debian archive; install the local file explicitly:

```sh
sudo apt install ./poshli_0.5.0-2_all.deb
# or:
sudo dpkg -i poshli_0.5.0-2_all.deb
```

The package installs the bundle at `/usr/share/poshli/poshli.sh`.

### Uninstallation

To remove POSHLI from your system:

```sh
# For user installation:
make uninstall

# For global installation:
sudo make uninstall PREFIX=/usr/local
```

### Vendoring Mode (No installation)

You can also copy the generated `poshli.sh` file directly into your own repository:

```sh
cp poshli.sh /path/to/your/project/lib/poshli.sh
```

---

## How to Load POSHLI

In any standard POSIX shell script, source the library using the dot (`.`) command:

```sh
#!/bin/sh

# Loading from user installation:
. "$HOME/.local/lib/poshli/poshli.sh"

# Or loading from global installation:
# . "/usr/local/lib/poshli/poshli.sh"

# Or loading from the Debian package:
# . "/usr/share/poshli/poshli.sh"

# Or relative loading when vendored:
# . "./lib/poshli.sh"
```

> **Note on Namespaces**: POSHLI exports namespaced functions (`str_trim`, `fs_is_file`, `encoding_base64_encode`, ...) into the shell's global function table for maximum ease of use. The module prefixes keep collisions unlikely, but ensure your scripts do not define conflicting function names.

> **Modular sources**: The `src/` directory contains the individual modules (`core.sh`, `num.sh`, `fs.sh`, `case_data.sh`, `str.sh`, `encoding.sh`). Each module is self-contained and can be sourced on its own during development (`str.sh` needs `src/case_data.sh` for `str_lower`/`str_upper`), but the supported distribution format is the generated `poshli.sh` bundle.

---

## Naming Policy

POSHLI's public API follows a consistent naming policy.

### General principle

Every public function is named `<module>_<name>`: the prefix of its module followed by a short, descriptive name.

```text
num_is_integer    num_randomize
str_trim          str_len
fs_is_file        fs_is_empty_file
encoding_base64_encode    encoding_base64_decode
```

No public function is exported without its module prefix. Generic unprefixed names (`trim`, `lower`, `is_file`) are not part of the API.

### Responsibility rule

> A function belongs to the module that represents its natural abstraction, not necessarily the module that uses it most.

For example, `str_len` is a string operation and lives in `str.sh` even when another module would consume it. Duplicated variants of the same abstraction under different prefixes (a second "repeat" or "trim" in another module) must be avoided.

### Queries and properties

Properties use direct, short names, without `get_`-style prefixes:

```text
str_len
str_len_bytes
```

### Actions

Actions read as `<module>_<verb>[_<detail>]`:

```text
str_trim
str_replace
num_randomize
encoding_base64_encode
encoding_base64_decode
```

### Predicates

Predicates express their condition and read naturally in conditionals. Classification predicates (type or format checks) keep `is_`; state and relationship predicates use the bare condition:

```text
if num_is_integer "$PORT"; then
if fs_is_file "$CONFIG_FILE"; then
if str_empty "$LINE"; then
if str_contains "$LINE" "host"; then
if str_starts_with "$LINE" "host"; then
```

### Symmetric families

Related functions follow a predictable pattern and differ only in a small, regular suffix. New variants of an existing operation extend the family; they never introduce a one-off name.

```text
str_starts_with / str_ends_with
str_len         / str_len_bytes
encoding_base64_encode / encoding_base64_decode
num_is_integer, num_is_natural, num_is_number, num_is_hex, num_is_bin, num_is_octal, num_is_bool
fs_is_file, fs_is_dir, fs_is_readable, fs_is_writable, fs_is_exec, fs_is_empty_file, fs_is_plain_text
```

### History

The module-prefix convention replaced the earlier unprefixed names (`trim`, `lower`, `upper`, `is_file`, `randomize`, `base64_enc`, ...). This rename was technically a breaking change and no compatibility aliases are provided: update call sites to the prefixed names. It took place during the initial consolidation of the public API, before `1.0.0`, and required no major version bump under the pre-1.0.0 policy (`POSHLI_VERSION` is `0.5.0`); see [Versioning Policy](#versioning-policy).

---

## Versioning Policy

POSHLI follows Semantic Versioning using the format:

```text
MAJOR.MINOR.PATCH
```

The current version is exposed as `POSHLI_VERSION` (see [Library Metadata](#library-metadata-coresh)) and is currently `0.5.0`.

### Pre-1.0.0 development

While `POSHLI_VERSION` is `0.y.z`, Poshli is in initial development. Under Semantic Versioning, anything MAY change at any time, and the public API is not considered stable. Incompatible changes are therefore permitted without a MAJOR version increment.

Once Poshli reaches `1.0.0`, the compatibility rules described below apply.

### PATCH — compatible fixes

```text
1.0.0 → 1.0.1
```

Used for bug fixes, corrections of incorrect behavior, internal improvements that do not break the public API incompatibly, portability fixes, and documentation fixes belonging to a maintenance release.

> A PATCH release must not break compatibility with the existing public API.

### MINOR — compatible features

```text
1.0.0 → 1.1.0
```

Used for new functionality, new public functions, new compatible modules, and extended capabilities that keep the existing API intact. For example, adding `num_clamp`, `str_repeat`, `str_width` or `term.sh` while preserving existing names and behavior.

> A MINOR release adds new capabilities without breaking existing public APIs.

### MAJOR — incompatible changes

```text
1.0.0 → 2.0.0
```

Used for incompatible changes: removing public functions, renaming public functions without compatibility aliases, changing arguments or public behavior incompatibly, or architectural changes that break the users' code.

> If a user must modify existing code to upgrade, it is normally a MAJOR bump.

Expected progression:

```text
1.0.0 → 1.0.1  compatible fixes
      → 1.1.0  compatible features
      → 1.2.0  compatible features
      → 2.0.0  incompatible change
```

### Historical note: naming cleanup

The module-prefix renaming (see [Naming Policy](#naming-policy)) was technically a breaking change relative to the earlier names: the unprefixed names were removed and no compatibility aliases are provided, so call sites must use the prefixed names. It took place during the initial development of the public API, before `1.0.0` was reached, while `POSHLI_VERSION` was still `0.y.z`. Under the pre-1.0.0 policy described above, the change required no MAJOR increment: the API was still in development and no compatibility guarantee was in force. This is recorded as project history, **not** as an exception to Semantic Versioning. Compatibility guarantees begin at `1.0.0`: from that release onward, the increments described above define what each change must follow.

### Debian packaging

The repository includes a `debian/` directory with packaging files for the `poshli` package. Revision `0.5.0-2` was built and validated locally on 2026-11-24 against the current tree with `dpkg-buildpackage`, `dpkg-checkbuilddeps` and `lintian`. The published GitHub Release `v0.5.0` carries the earlier `0.5.0-1` binary. The package version separates the upstream version from the Debian revision:

```text
0.5.0-2
```

- `0.5.0` — upstream Poshli version (`POSHLI_VERSION`).
- `-2` — second Debian packaging revision; it declares `awk` in `Build-Depends` and a real `awk` provider in `Depends`.

The packaging files specify `/usr/share/poshli/poshli.sh` as the install location. The package has **not** been uploaded to the Debian archive; it is distributed as a local/GitHub artifact.

---

## Dependency Policy

POSHLI follows a **POSIX-first** dependency policy:

> Poshli prioritizes implementations based on POSIX shell and utilities specified by POSIX. Non-POSIX dependencies must be avoided whenever a reasonable, maintainable POSIX alternative exists.

POSIX-first does **not** mean "pure shell". POSIX utilities such as `awk`, `sed`, `grep`, `tr`, `od`, `printf` or `wc` are part of the allowed model when they provide a clear advantage.

### Dependency levels

1. **POSIX shell / core**: small, clear operations implemented directly with POSIX shell when reasonable. Trivial operations must not spawn unnecessary external processes.
2. **POSIX utilities**: tools specified by POSIX when they add robustness, clarity, or capabilities that would be unnecessarily complex in pure shell. Mature tools are not reinvented merely to avoid running an external process.
3. **Optional improvements**: non-POSIX tools may be used only for a clearly justified improvement (performance, experience, or explicitly additional capabilities). They must never silently change the basic semantics of a function: the same call with the same arguments keeps the same semantics within its documented contract, whatever is installed.
4. **Explicit exceptions**: when no reasonable, maintainable POSIX alternative exists, a non-POSIX dependency is allowed when it is documented, justified, limited in scope, never fails silently, and defines what happens if it is unavailable. An exception for one feature never becomes a global dependency of the library.

### Determinism

> Optional dependencies must not silently change the semantics of an existing function.

An optional improvement may speed up an implementation, but the same input must not produce an incompatible result depending on the machine. If an additional capability requires another tool, it must be exposed or documented explicitly as such.

### Priorities

POSIX is not pursued at any cost. The architectural order of priorities is:

```text
correctness
→ portability
→ determinism
→ maintainability
→ simplicity
```

A huge, fragile, or hard-to-maintain POSIX implementation is not automatically better than a well-justified external exception.

### Current dependency status

- **Required at runtime**: a POSIX shell and the POSIX utilities `od`, `awk` and `wc` (the test suite additionally uses `tr` and other standard tools). `od` and `wc` come from `coreutils` (Essential); `awk` is a virtual package provided by `mawk`, `gawk` or `original-awk`. The Debian package declares `Build-Depends: awk` and `Depends: mawk | gawk | original-awk`, so a provider is declared explicitly rather than assumed. No Python, Perl or Node.js dependency is introduced at runtime.
- **Non-POSIX exceptions (level 4)**: none at runtime. `encoding_base64_encode`/`encoding_base64_decode` are implemented with `od`, `wc`, `awk` and the shell `printf`; the external `base64` command (not specified by POSIX) is not used; see [Encoding](#4-encoding-encodingsh).
- **Development only**: Python 3 generates the case-mapping data (`tools/gen_case.py`); it is never a runtime dependency. The generated data is derived from the Unicode Character Database, Unicode 15.0.0, under the Unicode License Agreement - Data Files and Software (2016) (`Unicode-DFS-2016`).

### Per-function dependency classification

Every public function is classified with the [dependency levels](#dependency-levels) above. Shell builtins and shell constructs (`test`/`[`, `printf`, `case`, parameter expansion, `unset`) count as **level 1** (POSIX shell / core); every POSIX utility executed as an external process counts as **level 2**. All runtime dependencies are level 1 or 2: there are **no level 3 optional improvements and no level 4 exceptions at runtime**. Which `awk` implementations the code has actually been verified against is stated in [Testing](#testing); unlisted implementations are covered by design only.

| Function | Level | External dependencies | Notes |
| :--- | :--- | :--- | :--- |
| `POSHLI_VERSION` | 1 | none | Constant variable. |
| `num_is_integer`, `num_is_natural`, `num_is_number`, `num_is_hex`, `num_is_bin`, `num_is_octal`, `num_is_bool` | 1 | none | Pure POSIX shell (`case`, `test`). |
| `num_randomize <limit>` | 2 | `awk` (`srand`, `rand`, `int`) | Randomness comes from the `awk` implementation's PRNG (see the note below). Indirect: `num_is_natural` (level 1). |
| `fs_is_file`, `fs_is_dir`, `fs_is_readable`, `fs_is_writable`, `fs_is_exec`, `fs_is_empty_file` | 1 | none | Pure POSIX shell (`test`). |
| `fs_is_plain_text` | 2 | `od`, `awk` | Also `test` (level 1). Documented byte heuristic; see [Filesystem](#2-filesystem-fssh). |
| `str_empty`, `str_trim`, `str_starts_with`, `str_ends_with`, `str_contains`, `str_replace` | 1 | none | Pure POSIX shell (`test`, `case`, parameter expansion). |
| `str_lower`, `str_upper` | 2 | `od`, `awk`, shell `printf` | Via the internal `_poshli_case_map`; the mapping data (`src/case_data.sh`) is embedded in the library, not an external dependency. |
| `str_len` | 2 | `od`, `awk` | UTF-8 validation and code-point counting over byte numbers. |
| `str_len_bytes` | 2 | `wc`, `awk` | `awk` only normalizes the `wc` output (some BSD and macOS `wc` pad counts with leading blanks); the count itself comes from `wc -c`. |
| `encoding_base64_encode` | 2 | `wc`, `od`, `awk`, shell `printf` | Also `test`, `case`, parameter expansion (level 1). |
| `encoding_base64_decode` | 2 | `awk`, shell `printf '%b'` | Input validation is pure POSIX shell (`case`, parameter expansion). |

> **`num_randomize` randomness**: POSIX leaves the `awk` random-number generator and its default seed implementation-defined. The values are **not cryptographic**, their quality depends on the installed `awk` implementation, and consecutive calls within the same second can return the same value with implementations whose default seed has one-second resolution (observed with GNU awk and BusyBox awk). The contract is only "a random integer in `[0, limit)`" for `limit` between `1` and `2147483647`.

Developers: [DEVELOPER.md](.github/DEVELOPER.md) documents the full criteria for introducing a dependency.

---

## API Reference

### Library Metadata (`core.sh`)

| Variable | Description |
| :--- | :--- |
| `POSHLI_VERSION` | Constant string exposed by the loaded library containing the current POSHLI release version (e.g. `'0.5.0'`). |

---

### Return Code Conventions

POSHLI distinguishes boolean predicates from operational functions:

- **Predicates** answer a yes/no question and return `0` for true and `1` for false. They never return `2`. An absent, empty, or invalid input is treated as false (`1`) when the predicate can answer the question; a separate error state is not used merely because an argument is missing.
- **Operational functions** perform an action or produce output. They return `0` on success, `1` when the input is invalid or the operation cannot be performed correctly (for example, `str_lower`/`str_upper` receiving invalid UTF-8), and `2` when a missing mandatory argument is a genuinely distinct usage error.

| Code | Meaning |
| :--- | :--- |
| `0` | Success / condition met (`true`). |
| `1` | Condition not met (`false`), invalid input, or input the operation cannot handle correctly. |
| `2` | Invalid usage in an operational function (for example, a missing mandatory argument). |

---

### 1. Numbers and Types (`num.sh`)

| Function | Description |
| :--- | :--- |
| `num_is_integer <val>` | Returns 0 if `<val>` is an integer with optional sign (`42`, `-42`, `+42`, `0012`, `0`). Rejects `+`, `-`, `12-3`, `12+`, `++1`. |
| `num_is_number <val>` | Returns 0 if `<val>` is a decimal number with an optional sign and at most one decimal point (`42`, `3.14`, `-0.05`, `.5`, `3.`). Rejects scientific notation (`1e10`), multiple dots (`1.2.3`) and isolated dots (`.`). |
| `num_is_natural <val>` | Returns 0 if `<val>` is a non-negative integer without sign (`0`, `1`, `42`). Rejects negative or explicit signs (`-1`, `+1`). |
| `num_is_hex <val>` | Returns 0 if `<val>` is hexadecimal (`0xFF`, `1a`, `DEADBEEF`), with optional `0x`/`0X` prefix. |
| `num_is_bin <val>` | Returns 0 if `<val>` is binary (`10110`, `0b1010`), with optional `0b`/`0B` prefix. |
| `num_is_bool <val>` | Returns 0 if `<val>` is a case-insensitive boolean literal: `0`, `1`, `true` or `false`. Rejects any other value. |
| `num_randomize <limit>` | Prints a random integer from `0` to one less than `<limit>` (`num_randomize 5` prints `0`–`4`). Returns 1 if `<limit>` is not a natural number in `1..2147483647`, or if `awk` fails (diagnostic on stderr, no stdout); returns 2 if no argument is passed. |

*The numeric predicates return `1` when the argument is missing or invalid. `num_randomize` returns `2` when no argument is passed. The randomness of `num_randomize` comes from the `awk` pseudo-random generator (not cryptographic; see the note in [Dependency Policy](#dependency-policy)).*

---

### 2. File System Checks (`fs.sh`)

| Function | Description |
| :--- | :--- |
| `fs_is_file <path>` | Returns 0 if `<path>` exists and is a regular file (`[ -f ]`). |
| `fs_is_dir <path>` | Returns 0 if `<path>` exists and is a directory (`[ -d ]`). |
| `fs_is_readable <path>` | Returns 0 if `<path>` exists and has read permissions (`[ -r ]`). |
| `fs_is_writable <path>` | Returns 0 if `<path>` exists and has write permissions (`[ -w ]`). |
| `fs_is_exec <path>` | Returns 0 if `<path>` exists and has execute permissions (`[ -x ]`). |
| `fs_is_empty_file <path>` | Returns 0 if `<path>` exists, is a regular file, and its size is 0 bytes (`[ -f ] && [ ! -s ]`). |
| `fs_is_plain_text <path>` | Returns 0 if `<path>` is a regular, readable file (symlinks are followed) and its first 4096 bytes are plain text: valid UTF-8, no NUL bytes, and no control characters other than TAB (`0x09`), LF (`0x0A`) and CR (`0x0D`) (an empty file is plain text). Returns 1 if the inspected content is not plain text (silently), or if the file does not exist, is unreadable, is not a regular file or its content cannot be read or validated (diagnostic on stderr, stdout empty); 2 if no argument is passed. |

*The six file-system predicates (`fs_is_file`, `fs_is_dir`, `fs_is_readable`, `fs_is_writable`, `fs_is_exec` and `fs_is_empty_file`) return `1` when the path argument is missing. `fs_is_plain_text` is an operational function, not a predicate: it returns `2` when its mandatory path argument is missing, and `1` when the content is not plain text or the file cannot be evaluated.*

> **`fs_is_plain_text` contract**: the file must be regular and readable. At most the first **4096 bytes** are inspected, and they must form a valid UTF-8 sequence (validated explicitly over bytes; overlong forms, surrogates and code points above `U+10FFFF` are rejected) with no NUL bytes and no control characters other than TAB (`0x09`), LF (`0x0A`) and CR (`0x0D`). The only control characters accepted are those three: DEL (`0x7F`) and the C1 controls (`U+0080`–`U+009F`) are rejected as well. An empty file is plain text. The result is deterministic and independent of the locale and of the installed tools: it is a documented byte heuristic implemented with the POSIX utilities `od` and `awk`; `file(1)` is **not** used. Content that is not plain text returns `1` silently; failures to read or validate the content also return `1`, but print a diagnostic on stderr and never write to stdout. Tool failures are therefore distinguishable from a negative result without changing the return-code contract.
>
> **Known limitation (intentional)**: only the first 4096 bytes are inspected. Binary content appearing after that limit can go unnoticed and the file is still classified as plain text. A UTF-8 character cut by the limit is assumed to continue beyond it. Reading whole files just to close this gap is deliberately avoided.

---

### 3. String Manipulation & Checks (`str.sh`)

| Function | Description |
| :--- | :--- |
| `str_empty [str]` | Returns 0 if `[str]` is empty (`""`) or if no argument is given. Returns 1 if `[str]` contains at least one character. |
| `str_trim [str]` | Prints `[str]` with leading and trailing spaces and tabs removed. If no argument is given, treats it as empty string. Preserves internal spacing. Returns 0 on success. |
| `str_lower [str]` | Prints `[str]` converted to lowercase with Unicode case mapping (guaranteed for ASCII, Latin, Greek and Cyrillic; every other code point with a generated mapping is converted too). Code points without a mapping (emoji, CJK, symbols, punctuation, combining marks) are preserved unchanged. Invalid UTF-8 prints nothing, writes a diagnostic to standard error, and returns `1`; the same happens if `od` cannot read the input bytes. If no argument is given, treats it as empty string and prints ``. See [Unicode Support](#unicode-support). |
| `str_upper [str]` | Prints `[str]` converted to uppercase. Same behavior as `str_lower`, including the unconditional one-to-many mappings (`str_upper "grüße"` prints `GRÜSSE`). |
| `str_starts_with <str> <prefix>` | Returns 0 if `<str>` begins with `<prefix>`, and 1 otherwise. Returns 1 if arguments are missing or insufficient. |
| `str_ends_with <str> <suffix>` | Returns 0 if `<str>` ends with `<suffix>`, and 1 otherwise. Returns 1 if arguments are missing or insufficient. |
| `str_contains <str> <substr>` | Returns 0 if `<str>` contains `<substr>`, and 1 otherwise. Returns 1 if arguments are missing or insufficient. |
| `str_len [str]` | Prints the number of Unicode code points in `[str]` (valid UTF-8). If no argument is given, treats it as empty string and prints `0`. Independent of `${#str}`, the shell, and the active locale. Combining marks and emoji components count separately; grapheme clusters are not counted. For invalid UTF-8, prints nothing, writes a diagnostic to standard error, and returns `1`. If `od` cannot read the input bytes, prints nothing, writes a diagnostic to standard error, and returns `1`. |
| `str_len_bytes [str]` | Prints the exact number of bytes in `[str]` using `wc -c`, with the count normalized through `awk` (some BSD and macOS `wc` implementations pad counts with leading blanks). If no argument is given, treats it as empty string and prints `0`. Always locale-independent. Returns 0 on success. If `wc` cannot count the bytes or `awk` cannot normalize the count, prints nothing, writes a diagnostic to standard error, and returns `1`. |
| `str_replace <search> <replace> <str>` | Prints `<str>` with all literal occurrences of `<search>` replaced with `<replace>`. Handles special characters safely. Returns `2` when arguments are insufficient. |

*The operational functions that require multiple mandatory arguments (`str_replace`) return `2` when arguments are missing.*

---

### 4. Encoding (`encoding.sh`)

The external `base64` command is **not** used: it is not specified by POSIX and its decode flag varies between implementations (`-d` or `-D`). Both functions are implemented with the POSIX utilities `od`, `wc` and `awk` and the shell `printf`, with a single code path and no fallbacks such as `openssl`, Python, or `uudecode`. Because a POSIX pipeline reports the status of its last command only, `encoding_base64_encode` validates what `od` actually produced (the expected byte count from `wc -c` and the field values seen by `awk`); the Base64 result is captured first and only printed on success, so no partial Base64 output is emitted on error.

| Function | Description |
| :--- | :--- |
| `encoding_base64_encode <str>` | Prints `$1` encoded in standard Base64 as a single line. Extra arguments are ignored. Returns 0 on success; 1 if encoding fails, including `od` or `wc` unavailable or producing inconsistent output (no partial Base64 output is emitted on error), or a write error while printing the result; 2 if no argument is passed. |
| `encoding_base64_decode <str>` | Decodes strict standard Base64 (RFC 4648) from `$1` and writes decoded bytes directly to stdout. The empty string is valid and produces no output. Extra arguments are ignored. Returns 1 if the input is invalid, decoding fails, or a write error occurs while writing the decoded bytes; 2 if no argument is passed. |

`encoding_base64_decode` accepts only the standard alphabet (`A-Z a-z 0-9 + /`), correct `=` padding, and a length multiple of 4. It rejects whitespace, line breaks, base64url (`-`/`_`), missing padding, and malformed padding. When POSHLI's validation rejects the input, no output is produced.

> Base64 is an encoding, not an encryption: it provides no confidentiality.
>
> Capturing output with `$(...)` is not suitable for binary/NUL data and removes trailing newlines. Redirect decoded binary output to a file instead.
>
> **Performance and size scope (indicative figures only)**: the measurements behind this contract cover inputs up to **5 MB**; larger inputs are neither excluded nor guaranteed. Times and peak memory were taken in the environment used for development (dash 0.5.12 with GNU awk 5.2.1): `encoding_base64_encode` took about 0.5 s for 1 MB and about 2.8 s for 5 MB, with an observed peak memory of about 10 MB and about 44 MB; with mawk 1.3.4 the 5 MB run took about 1.9 s and about 44 MB. `encoding_base64_decode` took about 2.4 s for 5 MB with an observed peak of about 109 MB. These are measurements of specific runs in one environment, **not** performance guarantees and **not** maximum input limits.
>
> **Memory**: the encoder's `awk` stage streams the input and uses constant memory; the peak is a small multiple of the input size because the result is captured before printing to keep the "no partial Base64 output is emitted on error" guarantee (the decoder's captured escape text is the same kind of buffer). As a reference for the improvement, the previous implementation buffered the whole input inside `awk` and reached about 127 MB for 1 MB and about 626 MB for 5 MB with GNU awk (about 332 MB for 5 MB with mawk 1.3.4).

---

## Unicode Support

POSHLI distinguishes three concepts that are often all called "length":

| String | Code points (`str_len`) | Bytes (`str_len_bytes`) | Grapheme clusters (not provided) |
| :--- | ---: | ---: | ---: |
| `hello` | 5 | 5 | 5 |
| `España` | 6 | 7 | 6 |
| `áéíóú` | 5 | 10 | 5 |
| `你好` | 2 | 6 | 2 |
| `😀` | 1 | 4 | 1 |
| `e` + U+0301 | 2 | 3 | 1 |
| `👨‍👩‍👧‍👦` | 7 | 25 | 1 |

### Length semantics

- `str_len` counts **Unicode code points** in valid UTF-8. It uses `od` and `awk` to count UTF-8 leading bytes and validate the sequence, so the result is consistent across `dash`, BusyBox `sh`, and `bash --posix`, and independent of the active locale.
- `str_len_bytes` counts **bytes** exactly and is always locale-independent. The `wc -c` output is normalized with `awk`, because some BSD and macOS `wc` implementations pad the count with leading blanks.
- Neither function counts **grapheme clusters** (visual characters). A combining mark or the components of a ZWJ emoji are counted separately. POSHLI does not normalize text, so `é` (U+00E9) and `e` + U+0301 are different code-point sequences even when they render identically.
- For invalid UTF-8, `str_len` prints nothing, writes a diagnostic to standard error, and returns `1`. Use `str_len_bytes` when the data is not known to be valid UTF-8.

### Case mapping (`str_lower` / `str_upper`)

`str_lower`/`str_upper` apply Unicode case mapping with POSHLI's own generated data. The result cannot vary with the shell, the locale or the `awk` implementation: the conversion never uses the locale, never uses `tolower()`/`toupper()` from `awk`, and never depends on any Unicode capability of the platform; the `awk` code uses only POSIX `awk` features. Which `awk` implementations the test suite has actually been verified against is stated in [Testing](#testing).

The input is validated and decoded from UTF-8 exactly like `str_len`, converted per code point, and re-encoded to UTF-8. All intermediate processing happens over ASCII text and numbers (`od`, POSIX `awk`, `printf`); no tool ever interprets non-ASCII text. The mapping data (`src/case_data.sh`) is generated at development time by `tools/gen_case.py` from the Unicode Character Database (Unicode 15.0.0) and compiled into the `poshli.sh` bundle, so the runtime needs no external Unicode database and no Python. The Unicode data is used under the Unicode License Agreement - Data Files and Software (2016) (`Unicode-DFS-2016`).

What is mapped:

- The Unicode **simple case mappings**, plus the **unconditional one-to-many mappings**: `str_upper "ß"` prints `SS`, `str_lower "İ"` prints `i` + U+0307, `str_upper "ﬁ"` prints `FI`, and similar. These expansions can make the result longer than the input.
- ASCII, **Latin**, **Greek** and **Cyrillic** letters are guaranteed and covered by the test suite. Every other code point with a generated mapping (Armenian, Georgian, and so on) is converted with the same rule.
- Code points **without a mapping are preserved unchanged**: emoji (`😀`, `🎉`), CJK (`你好`), symbols (`€`), punctuation, combining marks and ASCII emoticonos (`;-)`) pass through, and the ASCII letters inside the text are mapped like any other ASCII letter.
- Case mapping preserves accents exactly as they are: `str_lower "ΕΛΛΑΔΑ"` prints `ελλαδα` (U+0391 maps to U+03B1). Mapping never adds or removes diacritics and POSHLI never normalizes text.

What is not applied (documented limitations):

- **Contextual rules**. `str_lower` always maps U+03A3 to U+03C3: the contextual final sigma is never selected (unlike, for example, Python's `str.lower()`, which applies it at string level). POSHLI does not guess word boundaries.
- **Language-specific tailoring**. No Turkish/Azerbaijani dotted and dotless `i`, no Lithuanian rules, no locale tailoring at all: `str_upper "i"` returns `I` in every locale.
- **Case folding**. This is case mapping, not full case folding, and there is no normalization or grapheme-aware processing.

Invalid UTF-8 is rejected exactly like `str_len`: `str_lower`/`str_upper` print nothing, write a diagnostic to standard error, and return `1`. If `od` cannot read the input bytes, they fail in the same closed way. For arbitrary binary data, use `str_len_bytes`; case conversion is not defined for binary data.

### Dependencies

These are the requirements of the Unicode helpers; see the [Dependency Policy](#dependency-policy) for the complete dependency picture of the library.

- **Required**: a POSIX shell and the standard POSIX utilities `od`, `awk` and `wc`. `od` and `wc` are part of the POSIX-specified utilities; `awk` is a virtual package provided by `mawk`, `gawk` or `original-awk`, and every standard Debian and Ubuntu installation provides one, so the Debian package does not declare a dependency on it.
- **Unicode case mapping**: the data is generated into `src/case_data.sh` at development time by `tools/gen_case.py` (Python 3, development only) and ships inside `poshli.sh`. The runtime does not need Python, an external Unicode database, or a Unicode-aware `awk`.
- The case-mapping data embedded in `src/case_data.sh` and in the bundle is derived from the Unicode Character Database, Unicode 15.0.0, and is used under the Unicode License Agreement - Data Files and Software (2016) (`Unicode-DFS-2016`).
- No Python, Perl or Node.js dependency is introduced **at runtime**.

---

## Practical Example

```sh
#!/bin/sh
set -e

. "$HOME/.local/lib/poshli/poshli.sh"

PORT="$1"
CONFIG_FILE="$2"

# Parameter validation
if ! num_is_integer "$PORT"; then
	printf 'Error: PORT must be an integer.\n' >&2
	exit 1
fi

if ! fs_is_file "$CONFIG_FILE" || fs_is_empty_file "$CONFIG_FILE"; then
	printf 'Error: Configuration file does not exist or is empty.\n' >&2
	exit 1
fi

# String processing
RAW_LINE="   host = localhost:8080   "
CLEAN_LINE=$(str_trim "$RAW_LINE")

if str_starts_with "$CLEAN_LINE" "host"; then
	HOST=$(str_lower "$CLEAN_LINE")
	printf 'Configuration detected: %s\n' "$HOST"
fi
```

---

## Testing

POSHLI includes a self-contained automated test suite that runs under standard POSIX shells and uses only standard utilities. The number of tests adapts to the environment: locale-dependent tests run only when a UTF-8 locale is available, and permission-sensitive tests are skipped when the suite runs as root. The reported total is therefore environment-dependent; the full local matrix reports 634 tests. The case-mapping tests are environment-independent, because `str_lower`/`str_upper` never consult the locale or any Unicode behavior of the `awk` implementation and the expectations are fixed vectors:

```sh
# Run test suite against modular sources (src/):
make test

# Run test suite directly against the single-file bundle (poshli.sh):
make test-bundle

# Verify the committed bundle is synchronized with src/:
make check-bundle
```

> **`awk` implementation coverage (designed vs. verified)**: the library's `awk` code uses only POSIX `awk` features and never the locale, so its results are designed not to vary between conforming `awk` implementations. The matrix was re-executed **manually on 2026-11-21** in Ubuntu 24.04 with `dash` 0.5.12-6ubuntu5, `bash` 5.2.21-2ubuntu4 (`--posix`), GNU awk 5.2.1-2ubuntu0.1, `mawk` 1.3.4.20240123-1build1 and BusyBox 1.36.1-6ubuntu3.1. Every run executed the full suite (611 tests) with **611/611 passing and no skips**:
>
> - GNU awk 5.2.1: `dash` and `bash --posix` (sources and bundle).
> - `mawk` 1.3.4.20240123: `dash` and `bash --posix` (sources and bundle).
> - BusyBox `awk` 1.36.1: `dash` and `bash --posix` (sources and bundle).
> - BusyBox `sh` with BusyBox `awk`, `od` and `wc` (sources and bundle), plus the full-BusyBox configuration with `tr`, `cmp`, `head` and `id`.
> - `dash` with BusyBox `od` and `wc` (sources and bundle).
>
> This is **manual evidence from 2026-11-21**, and CI now also covers the `awk` dimension: an independent job runs the full suite under `dash` with GNU awk, `mawk` and BusyBox `awk` (sources and bundle), verifying the selected implementation before testing; a blocking ShellCheck job checks sources, tests and bundle against a checked-in baseline. The shell and `awk` dimensions are not always independently selectable: this BusyBox build uses its own `awk` applet from `busybox sh` regardless of `PATH`, so **BusyBox `sh` + GNU `awk` was not reproducible** and is not claimed; the verified BusyBox `sh` configuration is BusyBox `sh` + BusyBox `awk` + BusyBox `od`/`wc`. `mawk` was also used for some of the performance figures in [Encoding](#4-encoding-encodingsh).
>
> **Portability extension (2026-11-24):** after G1–G3 the suite contains **634 tests**. Local validation on Ubuntu 24.04.5 ran sources and bundle with:
>
> - **mksh 59c** (2024/02/01 +Debian) with GNU awk 5.2.1 and mawk 1.3.4: **634/634** each.
> - **BusyBox 1.35.0 static x86_64-linux-musl** (SHA-256 `6e123e7f3202a8c1e9b1f94d8941580a25135382b99e8d3e34fb858bba311348`), using its own `sh`, `awk`, `od` and `wc`: **634/634** each.
> - **ksh93u+m 1.0.8** (package `ksh` 20240113) with GNU awk and mawk: **634/634** each. ksh93 reports status `256` for a shell function used as the last command of a pipeline; the tests now use an executable `awk` shim under `tests/shims/` where `PATH` is honoured, with an equivalent function shim for BusyBox applet resolution. No library change was needed.
>
> **macOS `awk`, BSD `awk` and macOS/BSD `/bin/sh` remain unverified.** Linux CI defines a `ksh93`/`mksh` job that selects GNU awk and `mawk` explicitly and runs both sources and bundle; no run result is recorded here yet. `.github/workflows/portability.yml` prepares scheduled/manual runs on macOS 15 and macOS 26 (system `/bin/sh`, bash 3.2 `--posix` and BWK awk) and on FreeBSD 15.1 (system `/bin/sh`, `bash --posix` and BSD awk); those external runs are pending and have no recorded result yet.

---

## Contributing

Contributions are welcome! Please refer to the [Contributing Guidelines](.github/CONTRIBUTING.md) and review the [Code of Conduct](.github/CODE_OF_CONDUCT.md).

---

## License

SPDX-License-Identifier: `LGPL-3.0-only`

POSHLI is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, version **3 of the License only**. See [LICENSE](LICENSE) for the full license text.

### Unicode Character Database

The case-mapping data embedded in `src/case_data.sh` and in the generated `poshli.sh` bundle is derived from the Unicode Character Database, Unicode 15.0.0. It is distributed under `Unicode-DFS-2016` (Unicode License Agreement - Data Files and Software, 2016). Unicode 15.0.0 was published on 2022-09-13, when that was the license in force; the later Unicode License v3 (2023) is not retroactive and does not replace it for these data.

The full copyright and permission notice is reproduced below:

```text
UNICODE, INC. LICENSE AGREEMENT - DATA FILES AND SOFTWARE

See Terms of Use <https://www.unicode.org/copyright.html>
for definitions of Unicode Inc.’s Data Files and Software.

NOTICE TO USER: Carefully read the following legal agreement.
BY DOWNLOADING, INSTALLING, COPYING OR OTHERWISE USING UNICODE INC.'S
DATA FILES ("DATA FILES"), AND/OR SOFTWARE ("SOFTWARE"),
YOU UNEQUIVOCALLY ACCEPT, AND AGREE TO BE BOUND BY, ALL OF THE
TERMS AND CONDITIONS OF THIS AGREEMENT.
IF YOU DO NOT AGREE, DO NOT DOWNLOAD, INSTALL, COPY, DISTRIBUTE OR USE
THE DATA FILES OR SOFTWARE.

COPYRIGHT AND PERMISSION NOTICE

Copyright © 1991-2022 Unicode, Inc. All rights reserved.
Distributed under the Terms of Use in https://www.unicode.org/copyright.html.

Permission is hereby granted, free of charge, to any person obtaining
a copy of the Unicode data files and any associated documentation
(the "Data Files") or Unicode software and any associated documentation
(the "Software") to deal in the Data Files or Software
without restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, and/or sell copies of
the Data Files or Software, and to permit persons to whom the Data Files
or Software are furnished to do so, provided that either
(a) this copyright and permission notice appear with all copies
of the Data Files or Software, or
(b) this copyright and permission notice appear in associated
Documentation.

THE DATA FILES AND SOFTWARE ARE PROVIDED "AS IS", WITHOUT WARRANTY OF
ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT OF THIRD PARTY RIGHTS.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED IN THIS
NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL
DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THE DATA FILES OR SOFTWARE.

Except as contained in this notice, the name of a copyright holder
shall not be used in advertising or otherwise to promote the sale,
use or other dealings in these Data Files or Software without prior
written authorization of the copyright holder.
```

### Using POSHLI in other programs

POSHLI is a shell function library that a script loads with the POSIX dot (`.`) command, effectively combining the caller's script with the library at runtime. The GNU LGPL permits this kind of use in proprietary as well as free programs, provided you comply with the LGPL notice and source-provision requirements for the library itself.

The LGPL's terminology ("Application", "Combined Work", "linking") was written primarily for compiled and dynamically-linked libraries. Loading a shell library with `.` / `source` is not exactly dynamic linking in the technical sense, but it is the idiomatic way to combine a shell script with a reusable library. If you distribute a program that incorporates POSHLI in this way, the LGPL requires you to give recipients the means to replace POSHLI with a modified version and to provide them with POSHLI's source code and license text. How best to satisfy the "relink" requirement for a shell script is not addressed explicitly in the LGPL text; if you need certainty for a specific distribution model, consult a lawyer or `debian-legal@lists.debian.org`.

No additional restrictions are imposed on your own code beyond what the LGPL itself requires.
