# POSHLI

**POSHLI** (*POSIX Shell Library*) is a lightweight, standard, and ergonomic library of reusable shell functions for `/bin/sh` (POSIX). Its primary purpose is to make writing shell scripts in Linux and other POSIX-compliant environments easier, faster, and more intuitive without constantly reinventing common utilities.

---

## Features

- **Standard POSIX sh**: Designed, verified, and tested against standard `/bin/sh` interpreters, including `dash` (Debian/Ubuntu default `/bin/sh`), `busybox sh`, and `bash --posix`.
- **Linux as primary platform**: Optimized for Linux development workflows while maintaining strict POSIX portability.
- **Short and ergonomic API**: Clean, direct function names without unnecessary prefixes (`is_integer`, `is_file`, `trim`, `lower`, etc.).
- **Self-contained bundle**: Distributed as a single file (`poshli.sh`) ready for direct inclusion or project vendoring.
- **Predictable return codes**: Predicates return `0` (true) or `1` (false); missing mandatory arguments return `2`.
- **Unicode-aware helpers**: `str_len` counts UTF-8 code points independently of the locale; `lower`/`upper` always map ASCII and use `gawk` for Unicode case mapping when it is available and the active locale is UTF-8, falling back to the system `awk` otherwise (typically ASCII-only).
- **Zero heavy dependencies**: Relies strictly on native shell syntax and standard POSIX utilities. `gawk` is optional and only enables Unicode case mapping; when it is absent, `lower`/`upper` use the system `awk` (typically ASCII-only). No extra tool is required.

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

---

## API Reference

### Library Metadata (`core.sh`)

| Variable | Description |
| :--- | :--- |
| `POSHLI_VERSION` | Constant string exposed by the loaded library containing the current POSHLI release version (e.g. `'1.0.0'`). |

---

### Return Code Conventions
- **`0`**: Success / Condition met (`true`).
- **`1`**: Condition not met (`false`).
- **`2`**: Invalid usage / Missing mandatory arguments.

---

### 1. Numbers and Types (`num.sh`)

| Function | Description |
| :--- | :--- |
| `is_integer <val>` | Returns 0 if `<val>` is an integer with optional sign (`42`, `-42`, `+42`, `0012`, `0`). Rejects `+`, `-`, `12-3`, `12+`, `++1`. |
| `is_number <val>` | Returns 0 if `<val>` is an integer or decimal number with optional sign (`42`, `3.14`, `-0.05`, `.5`). Rejects trailing dots `3.`, multiple dots `1.2.3`, isolated dots `.`. |
| `is_natural <val>` | Returns 0 if `<val>` is a non-negative integer without sign (`0`, `1`, `42`). Rejects negative or explicit signs (`-1`, `+1`). |
| `is_hex <val>` | Returns 0 if `<val>` is hexadecimal (`0xFF`, `1a`, `DEADBEEF`), with optional `0x`/`0X` prefix. |
| `is_bin <val>` | Returns 0 if `<val>` is binary (`10110`, `0b1010`), with optional `0b`/`0B` prefix. |
| `is_bool <val>` | Returns 0 if `<val>` is strictly `0`, `1`, `true`, `false`, `TRUE`, or `FALSE`. |

*All numeric functions return 2 if no argument is passed.*

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

*All file system functions return 2 if no argument is passed.*

---

### 3. String Manipulation & Checks (`str.sh`)

| Function | Description |
| :--- | :--- |
| `is_empty [str]` | Returns 0 if `[str]` is empty (`""`) or if no argument is given. Returns 1 if `[str]` contains at least one character. |
| `trim <str>` | Prints `<str>` with leading and trailing spaces and tabs removed. Preserves internal spacing. |
| `lower <str>` | Prints `<str>` converted to lowercase. ASCII letters are always mapped. When `gawk` is available and the active locale is UTF-8, Unicode case mapping is also applied (delegated to `gawk` and the active locale, e.g. `É` → `é`). Without `gawk`, the system `awk` is used and non-ASCII characters are typically left unchanged. See [Unicode Support](#unicode-support). |
| `upper <str>` | Prints `<str>` converted to uppercase. Same behavior as `lower`. |
| `starts_with <str> <prefix>` | Returns 0 if `<str>` begins with `<prefix>`. Returns 2 if fewer than 2 arguments are passed. |
| `ends_with <str> <suffix>` | Returns 0 if `<str>` ends with `<suffix>`. Returns 2 if fewer than 2 arguments are passed. |
| `contains <str> <substr>` | Returns 0 if `<str>` contains `<substr>`. Returns 2 if fewer than 2 arguments are passed. |
| `str_len <str>` | Prints the number of Unicode code points in `<str>` (valid UTF-8). Independent of `${#str}`, the shell, and the active locale. Combining marks and emoji components count separately; grapheme clusters are not counted. For invalid UTF-8 the result is approximate. Returns 2 if no argument is passed. |
| `str_len_bytes <str>` | Prints the exact number of bytes in `<str>` using `wc -c`. Always locale-independent. Returns 2 if no argument is passed. |
| `str_replace <search> <replace> <str>` | Prints `<str>` with all literal occurrences of `<search>` replaced with `<replace>`. Handles special characters safely. Returns 2 if fewer than 3 arguments are passed. |

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

- `str_len` counts **Unicode code points** in valid UTF-8. It uses `od` and `awk` to count UTF-8 leading bytes, so the result is consistent across `dash`, BusyBox `sh`, and `bash --posix`, and independent of the active locale.
- `str_len_bytes` counts **bytes** exactly and is always locale-independent.
- Neither function counts **grapheme clusters** (visual characters). A combining mark or the components of a ZWJ emoji are counted separately. POSHLI does not normalize text, so `é` (U+00E9) and `e` + U+0301 are different code-point sequences even when they render identically.
- For invalid UTF-8, `str_len` returns an approximate count based on UTF-8 leading-byte heuristics. Use `str_len_bytes` when the data is not known to be valid UTF-8.

### Case mapping (`lower` / `upper`)

ASCII letters are always mapped, though the mapping is locale-dependent when `gawk` is used; set `LC_ALL=C` for deterministic ASCII behavior. For case mapping, POSHLI uses `gawk` when it is available and otherwise the system `awk`, a mandatory POSIX utility:

- If `gawk` is available in `PATH`, it is preferred and applies Unicode case mapping when the active locale is UTF-8. `gawk` is free software and available in every major Linux distribution, Cygwin, WSL, macOS (Homebrew) and the BSDs.
- Otherwise the system `awk` is used. Most implementations (for example `mawk` and BusyBox `awk`) leave non-ASCII bytes unchanged in the C and UTF-8 locales, so the result is typically ASCII-only. POSHLI does not guarantee Unicode case mapping without `gawk`, and the result still depends on the `awk` implementation and the active locale.

The backend is selected once when the library is loaded; there is no runtime probing and no cache. Results depend on the selected backend (`gawk` or the system `awk`) and on the active locale: when `gawk` is used, it delegates to the casing rules of that locale. In a single-byte non-UTF-8 locale (for example ISO-8859-1), a system `awk` may map high bytes and alter UTF-8 input.

For deterministic ASCII-only behavior, set `LC_ALL=C` (or use `tr` directly). The Unicode path delegates case mapping to `gawk` (or to the system `awk`); it is not full case folding:

- It does not expand `ß` to `SS`, expand ligatures such as `ﬀ`, or apply contextual rules such as Greek final sigma.
- It does not normalize text or perform grapheme-aware operations.
- It does not implement locale-specific tailoring itself, but when `gawk` is used the casing rules of the active locale apply. For example, in a Turkish or Azeri locale `upper "i"` returns `İ` and `lower "I"` returns `ı`.

For arbitrary binary data, use `str_len_bytes` and keep case conversion in ASCII mode.

### Dependencies

- **Required**: a POSIX shell and the standard POSIX utilities `sed`, `od`, `awk` and `wc`. These are mandatory in POSIX environments and require no extra installation.
- **Optional**: `gawk` enables Unicode case mapping. If it is not installed, `lower`/`upper` remain fully functional for ASCII text. Install it with the package manager of your system:
  - Debian/Ubuntu/WSL: `sudo apt-get install gawk`
  - Fedora/RHEL: `sudo dnf install gawk`
  - Alpine: `apk add gawk`
  - Arch: `sudo pacman -S gawk`
  - macOS: `brew install gawk`
  - Cygwin: install the `gawk` package with Cygwin Setup
- No Python, Perl or Node.js dependency is introduced.

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

POSHLI includes a zero-dependency automated test suite compatible with standard POSIX shells. The number of tests adapts to the environment: locale-dependent tests run only when a UTF-8 locale is available, and the Unicode case-mapping assertions run only when a UTF-8 locale and `gawk` are available (254 tests with a UTF-8 locale and no `gawk`; 257 with `gawk` and a UTF-8 locale):

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
