# POSHLI

**POSHLI** (*POSIX Shell Library*) is a lightweight, standard, and ergonomic library of reusable shell functions for `/bin/sh` (POSIX). Its primary purpose is to make writing shell scripts in Linux and other POSIX-compliant environments easier, faster, and more intuitive without constantly reinventing common utilities.

---

## Features

- **Standard POSIX sh**: Designed, verified, and tested against standard `/bin/sh` interpreters, including `dash` (Debian/Ubuntu default `/bin/sh`), `busybox sh`, and `bash --posix`.
- **Linux as primary platform**: Optimized for Linux development workflows while maintaining strict POSIX portability.
- **Short and ergonomic API**: Clean, direct function names without unnecessary prefixes (`is_integer`, `is_file`, `trim`, `lower`, etc.).
- **Self-contained bundle**: Distributed as a single file (`poshli.sh`) ready for direct inclusion or project vendoring.
- **Predictable return codes**: Predicates return `0` (true) or `1` (false); missing mandatory arguments return `2`.
- **Zero heavy dependencies**: Relies strictly on native shell syntax and standard POSIX utilities.

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
| `lower <str>` | Prints `<str>` converted to lowercase using standard `tr`. |
| `upper <str>` | Prints `<str>` converted to uppercase using standard `tr`. |
| `starts_with <str> <prefix>` | Returns 0 if `<str>` begins with `<prefix>`. Returns 2 if fewer than 2 arguments are passed. |
| `ends_with <str> <suffix>` | Returns 0 if `<str>` ends with `<suffix>`. Returns 2 if fewer than 2 arguments are passed. |
| `contains <str> <substr>` | Returns 0 if `<str>` contains `<substr>`. Returns 2 if fewer than 2 arguments are passed. |
| `str_len <str>` | Prints the length in characters of `<str>` using native `${#str}`. |
| `str_replace <search> <replace> <str>` | Prints `<str>` with all literal occurrences of `<search>` replaced with `<replace>`. Handles special characters safely. Returns 2 if fewer than 3 arguments are passed. |

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

POSHLI includes a zero-dependency automated test suite (211 tests) compatible with standard POSIX shells:

```sh
# Run test suite against modular sources (src/):
make test

# Run test suite directly against the single-file bundle (poshli.sh):
make test-bundle
```

---

## Contributing

Contributions are welcome! Please refer to the [Contributing Guidelines](.github/CONTRIBUTING.md) and review the [Code of Conduct](.github/CODE_OF_CONDUCT.md).

---

## License

GNU Lesser General Public License v3.0 ([LGPL-3.0](LICENSE)).
