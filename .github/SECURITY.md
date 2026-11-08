# Security Policy

## Supported Versions

| Version | Supported |
| :--- | :--- |
| 1.0.x | :white_check_mark: |

---

## Security Principles in POSHLI

Because shell scripts execute commands directly within system shells, POSHLI enforces strict defensive programming practices:

1. **No `eval`**: POSHLI never evaluates user-supplied data through `eval`.
2. **Strict Quoting**: All internal variable expansions are strictly quoted (`"$1"`, `"$@"`) to prevent word splitting and unintended pathname globbing.
3. **Safe Output**: Functions use `printf '%s\n'` exclusively, preventing option-flag injection that can occur when strings begin with hyphens (e.g., `-n`, `-e`).
4. **Input Sanitization**: Pattern and replacement strings in text utilities are handled to prevent regex command injections.

---

## Reporting a Vulnerability

If you discover a security vulnerability in POSHLI:

1. **Do not open a public issue.**
2. Send an email describing the issue, impact, and a minimal reproducible example to: `humanogonzalo@gmail.com`.
3. We will acknowledge receipt within 48 hours and coordinate a fix and release.
