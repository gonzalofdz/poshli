# POSHLI

**POSHLI** (*POSIX Shell Library*) is a lightweight, general-purpose shell library built around portable POSIX shell syntax and widely available standard utilities. It provides reusable, ergonomic functions for automation, text processing, validation, and everyday scripting on Linux, macOS, BSD, WSL, Cygwin, and other POSIX-compatible Unix-like environments.

---

## Features

- **Portable POSIX shell**: Designed and tested against standard `/bin/sh` interpreters, including `dash` (Debian/Ubuntu default `/bin/sh`), `busybox sh`, and `bash --posix`, without relying on shell-specific extensions.
- **General purpose and portable**: Linux is the primary continuous-integration platform. macOS, BSD, WSL, and Cygwin are supported targets where the required standard utilities behave portably; they are not all continuously tested, so platform-specific behavior may vary.
- **Short and ergonomic API**: Clean, direct function names without unnecessary prefixes (`is_integer`, `is_file`, `trim`, `lower`, etc.).
- **Self-contained bundle**: Distributed as a single file (`poshli.sh`) ready for direct inclusion or project vendoring.
- **Predictable return codes**: Boolean predicates return `0` (true) or `1` (false); an absent, empty, or invalid input is treated as false when the predicate can answer the question. Operational functions return `1` when the input is invalid or the operation cannot be performed correctly, and may return `2` for invalid usage, such as a missing mandatory argument.
- **Unicode-aware helpers**: `str_len` counts Unicode code points in valid UTF-8 independently of the locale and rejects invalid UTF-8. `lower`/`upper` apply Unicode case mapping (Latin, Greek and Cyrillic guaranteed) with data generated into the library itself, so the result is identical in every locale, shell and `awk`; valid code points without a mapping (emoji, CJK, symbols) are preserved unchanged and invalid UTF-8 is rejected with status `1`.
- **Minimal dependencies**: Built around the POSIX shell and standard POSIX utilities (`od`, `awk`, `wc`, `tr`). Case mapping works over numeric code points with data generated at development time (Python is a development-only tool): the runtime needs no Unicode database, no extra tool, and no Unicode-aware `awk`.

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

# Or relative loading when vendored:
# . "./lib/poshli.sh"
```

> **Note on Namespaces**: POSHLI exports short, ergonomic functions directly into the shell's global function table for maximum ease of use. Ensure your scripts do not define conflicting function names.

> **Modular sources**: The `src/` directory contains the individual modules (`core.sh`, `num.sh`, `fs.sh`, `case_data.sh`, `str.sh`, `encoding.sh`). Each module is self-contained and can be sourced on its own during development (`str.sh` needs `src/case_data.sh` for `lower`/`upper`), but the supported distribution format is the generated `poshli.sh` bundle.

---

## API Reference

### Library Metadata (`core.sh`)

| Variable | Description |
| :--- | :--- |
| `POSHLI_VERSION` | Constant string exposed by the loaded library containing the current POSHLI release version (e.g. `'1.0.0'`). |

---

### Return Code Conventions

POSHLI distinguishes boolean predicates from operational functions:

- **Predicates** answer a yes/no question and return `0` for true and `1` for false. An absent, empty, or invalid input is treated as false when the predicate can answer the question; a separate error state is not used merely because an argument is missing.
- **Operational functions** perform an action or produce output. They return `0` on success, `1` when the input is invalid or the operation cannot be performed correctly (for example, `lower`/`upper` receiving invalid UTF-8), and `2` when a missing mandatory argument is a genuinely distinct usage error.

| Code | Meaning |
| :--- | :--- |
| `0` | Success / condition met (`true`). |
| `1` | Condition not met (`false`), invalid input, or input the operation cannot handle correctly. |
| `2` | Invalid usage in an operational function (for example, a missing mandatory argument). |

---

### 1. Numbers and Types (`num.sh`)

| Function | Description |
| :--- | :--- |
| `is_integer <val>` | Returns 0 if `<val>` is an integer with optional sign (`42`, `-42`, `+42`, `0012`, `0`). Rejects `+`, `-`, `12-3`, `12+`, `++1`. |
| `is_number <val>` | Returns 0 if `<val>` is a decimal number with an optional sign and at most one decimal point (`42`, `3.14`, `-0.05`, `.5`, `3.`). Rejects scientific notation (`1e10`), multiple dots (`1.2.3`) and isolated dots (`.`). |
| `is_natural <val>` | Returns 0 if `<val>` is a non-negative integer without sign (`0`, `1`, `42`). Rejects negative or explicit signs (`-1`, `+1`). |
| `is_hex <val>` | Returns 0 if `<val>` is hexadecimal (`0xFF`, `1a`, `DEADBEEF`), with optional `0x`/`0X` prefix. |
| `is_bin <val>` | Returns 0 if `<val>` is binary (`10110`, `0b1010`), with optional `0b`/`0B` prefix. |
| `is_bool <val>` | Returns 0 if `<val>` is strictly `0`, `1`, `true`, `false`, `TRUE`, or `FALSE`. |
| `randomize <limit>` | Prints a random integer from `0` to one less than `<limit>` (`randomize 5` prints `0`–`4`). Returns 1 if `<limit>` is not a natural number greater than `0`, or 2 if no argument is passed. |

*The numeric predicates return `1` when the argument is missing or invalid. `randomize` returns `2` when no argument is passed.*

---

### 2. File System Checks (`fs.sh`)

| Function | Description |
| :--- | :--- |
| `is_file <path>` | Returns 0 if `<path>` exists and is a regular file (`[ -f ]`). |
| `is_dir <path>` | Returns 0 if `<path>` exists and is a directory (`[ -d ]`). |
| `is_readable <path>` | Returns 0 if `<path>` exists and has read permissions (`[ -r ]`). |
| `is_writable <path>` | Returns 0 if `<path>` exists and has write permissions (`[ -w ]`). |
| `is_exec <path>` | Returns 0 if `<path>` exists and has execute permissions (`[ -x ]`). |
| `is_empty_file <path>` | Returns 0 if `<path>` exists, is a regular file, and its size is 0 bytes (`[ -f ] && [ ! -s ]`). |
| `is_plain_text <path>` | Returns 0 if `<path>` is readable and `file` reports it as text. Returns 1 if it is a binary or non-text file, or if it does not exist or is unreadable; 2 if no argument is passed. |

*Unlike the boolean predicates in `num.sh` and `str.sh`, the file-system predicates still return `2` when the path argument is missing.*

---

### 3. String Manipulation & Checks (`str.sh`)

| Function | Description |
| :--- | :--- |
| `is_empty [str]` | Returns 0 if `[str]` is empty (`""`) or if no argument is given. Returns 1 if `[str]` contains at least one character. |
| `trim [str]` | Prints `[str]` with leading and trailing spaces and tabs removed. If no argument is given, treats it as empty string. Preserves internal spacing. Returns 0 on success. |
| `lower [str]` | Prints `[str]` converted to lowercase with Unicode case mapping (guaranteed for ASCII, Latin, Greek and Cyrillic; every other code point with a generated mapping is converted too). Code points without a mapping (emoji, CJK, symbols, punctuation, combining marks) are preserved unchanged. Invalid UTF-8 prints nothing, writes a diagnostic to standard error, and returns `1`. If no argument is given, treats it as empty string and prints ``. See [Unicode Support](#unicode-support). |
| `upper [str]` | Prints `[str]` converted to uppercase. Same behavior as `lower`, including the unconditional one-to-many mappings (`upper "grüße"` prints `GRÜSSE`). |
| `starts_with <str> <prefix>` | Returns 0 if `<str>` begins with `<prefix>`, and 1 otherwise. Returns 1 if arguments are missing or insufficient. |
| `ends_with <str> <suffix>` | Returns 0 if `<str>` ends with `<suffix>`, and 1 otherwise. Returns 1 if arguments are missing or insufficient. |
| `contains <str> <substr>` | Returns 0 if `<str>` contains `<substr>`, and 1 otherwise. Returns 1 if arguments are missing or insufficient. |
| `str_len [str]` | Prints the number of Unicode code points in `[str]` (valid UTF-8). If no argument is given, treats it as empty string and prints `0`. Independent of `${#str}`, the shell, and the active locale. Combining marks and emoji components count separately; grapheme clusters are not counted. For invalid UTF-8, prints nothing, writes a diagnostic to standard error, and returns `1`. |
| `str_len_bytes [str]` | Prints the exact number of bytes in `[str]` using `wc -c`. If no argument is given, treats it as empty string and prints `0`. Always locale-independent. Returns 0 on success. |
| `str_replace <search> <replace> <str>` | Prints `<str>` with all literal occurrences of `<search>` replaced with `<replace>`. Handles special characters safely. Returns `2` when arguments are insufficient. |

*The operational functions that require multiple mandatory arguments (`str_replace`) return `2` when arguments are missing.*

---

### 4. Encoding (`encoding.sh`)

`base64` is **not** part of POSIX, so it is treated as a documented external dependency. POSHLI detects a usable decode flag functionally at load time (`-d` or `-D`) and does not add fallbacks such as `openssl`, Python, or `uudecode`.

| Function | Description |
| :--- | :--- |
| `base64_enc <str>` | Prints `$1` encoded in standard Base64 as a single line. Extra arguments are ignored. Returns 1 if encoding fails or if no usable `base64` backend is available, or 2 if no argument is passed. |
| `base64_dec <str>` | Decodes strict standard Base64 (RFC 4648) from `$1` and writes decoded bytes directly to stdout. The empty string is valid and produces no output. Extra arguments are ignored. Returns 1 if the input is invalid, decoding fails, or no usable `base64` backend is available; 2 if no argument is passed. |

`base64_dec` accepts only the standard alphabet (`A-Z a-z 0-9 + /`), correct `=` padding, and a length multiple of 4. It rejects whitespace, line breaks, base64url (`-`/`_`), missing padding, and malformed padding. When POSHLI's validation rejects the input, no output is produced.

> Base64 is an encoding, not an encryption: it provides no confidentiality.
>
> Capturing output with `$(...)` is not suitable for binary/NUL data and removes trailing newlines. Redirect decoded binary output to a file instead.

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
- `str_len_bytes` counts **bytes** exactly and is always locale-independent. The `wc -c` output is normalized, because some BSD and macOS `wc` implementations pad the count with leading blanks.
- Neither function counts **grapheme clusters** (visual characters). A combining mark or the components of a ZWJ emoji are counted separately. POSHLI does not normalize text, so `é` (U+00E9) and `e` + U+0301 are different code-point sequences even when they render identically.
- For invalid UTF-8, `str_len` prints nothing, writes a diagnostic to standard error, and returns `1`. Use `str_len_bytes` when the data is not known to be valid UTF-8.

### Case mapping (`lower` / `upper`)

`lower`/`upper` apply Unicode case mapping with POSHLI's own generated data. The result is identical in every shell, locale and `awk` implementation: the conversion never uses the locale, never uses `tolower()`/`toupper()` from `awk`, and never depends on any Unicode capability of the platform.

The input is validated and decoded from UTF-8 exactly like `str_len`, converted per code point, and re-encoded to UTF-8. All intermediate processing happens over ASCII text and numbers (`od`, POSIX `awk`, `printf`); no tool ever interprets non-ASCII text. The mapping data (`src/case_data.sh`) is generated at development time by `tools/gen_case.py` from the Unicode Character Database (Unicode 15.0.0) and compiled into the `poshli.sh` bundle, so the runtime needs no external Unicode database and no Python.

What is mapped:

- The Unicode **simple case mappings**, plus the **unconditional one-to-many mappings**: `upper "ß"` prints `SS`, `lower "İ"` prints `i` + U+0307, `upper "ﬁ"` prints `FI`, and similar. These expansions can make the result longer than the input.
- ASCII, **Latin**, **Greek** and **Cyrillic** letters are guaranteed and covered by the test suite. Every other code point with a generated mapping (Armenian, Georgian, and so on) is converted with the same rule.
- Code points **without a mapping are preserved unchanged**: emoji (`😀`, `🎉`), CJK (`你好`), symbols (`€`), punctuation, combining marks and ASCII emoticonos (`;-)`) pass through, and the ASCII letters inside the text are mapped like any other ASCII letter.
- Case mapping preserves accents exactly as they are: `lower "ΕΛΛΑΔΑ"` prints `ελλαδα` (U+0391 maps to U+03B1). Mapping never adds or removes diacritics and POSHLI never normalizes text.

What is not applied (documented limitations):

- **Contextual rules**. `lower` always maps U+03A3 to U+03C3: the contextual final sigma is never selected (unlike, for example, Python's `str.lower()`, which applies it at string level). POSHLI does not guess word boundaries.
- **Language-specific tailoring**. No Turkish/Azerbaijani dotted and dotless `i`, no Lithuanian rules, no locale tailoring at all: `upper "i"` returns `I` in every locale.
- **Case folding**. This is case mapping, not full case folding, and there is no normalization or grapheme-aware processing.

Invalid UTF-8 is rejected exactly like `str_len`: `lower`/`upper` print nothing, write a diagnostic to standard error, and return `1`. For arbitrary binary data, use `str_len_bytes`; case conversion is not defined for binary data.

### Dependencies

- **Required**: a POSIX shell and the standard POSIX utilities `od`, `awk`, `wc` and `tr`. These are mandatory in POSIX environments and require no extra installation.
- **Unicode case mapping**: the data is generated into `src/case_data.sh` at development time by `tools/gen_case.py` (Python 3, development only) and ships inside `poshli.sh`. The runtime does not need Python, an external Unicode database, or a Unicode-aware `awk`.
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
if ! is_integer "$PORT"; then
	printf 'Error: PORT must be an integer.\n' >&2
	exit 1
fi

if ! is_file "$CONFIG_FILE" || is_empty_file "$CONFIG_FILE"; then
	printf 'Error: Configuration file does not exist or is empty.\n' >&2
	exit 1
fi

# String processing
RAW_LINE="   host = localhost:8080   "
CLEAN_LINE=$(trim "$RAW_LINE")

if starts_with "$CLEAN_LINE" "host"; then
	HOST=$(lower "$CLEAN_LINE")
	printf 'Configuration detected: %s\n' "$HOST"
fi
```

---

## Testing

POSHLI includes a self-contained automated test suite that runs under standard POSIX shells and uses only standard utilities. The number of tests adapts to the environment: locale-dependent tests run only when a UTF-8 locale is available. The case-mapping tests are environment-independent, because `lower`/`upper` are guaranteed to behave identically with any `awk` and in any locale:

```sh
# Run test suite against modular sources (src/):
make test

# Run test suite directly against the single-file bundle (poshli.sh):
make test-bundle

# Verify the committed bundle is synchronized with src/:
make check-bundle
```

---

## Contributing

Contributions are welcome! Please refer to the [Contributing Guidelines](.github/CONTRIBUTING.md) and review the [Code of Conduct](.github/CODE_OF_CONDUCT.md).

---

## License

GNU Lesser General Public License v3.0 ([LGPL-3.0](LICENSE)).
