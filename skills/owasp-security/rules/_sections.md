# Rule Sections — OWASP Top 10:2025

This file defines the ordering and metadata for each OWASP category.
The `scripts/build.sh` script reads this to compile rules into AGENTS.md.

## Categories

| Order | Section Header                          | Prefix       | OWASP ID | Severity | Rule Count |
|-------|-----------------------------------------|--------------|----------|----------|------------|
| 1     | A01:2025 — Broken Access Control        | `access-`    | A01:2025 | CRITICAL | 13         |
| 2     | A02:2025 — Security Misconfiguration    | `config-`    | A02:2025 | CRITICAL | 8          |
| 3     | A03:2025 — Software Supply Chain Failures | `supply-`  | A03:2025 | CRITICAL | 5          |
| 4     | A04:2025 — Cryptographic Failures       | `crypto-`    | A04:2025 | HIGH     | 4          |
| 5     | A05:2025 — Injection                    | `inject-`    | A05:2025 | HIGH     | 7          |
| 6     | A06:2025 — Insecure Design              | `design-`    | A06:2025 | HIGH     | 3          |
| 7     | A07:2025 — Authentication Failures      | `auth-`      | A07:2025 | HIGH     | 5          |
| 8     | A08:2025 — Software or Data Integrity Failures | `integrity-` | A08:2025 | MEDIUM | 4      |
| 9     | A09:2025 — Security Logging and Alerting Failures | `logging-` | A09:2025 | MEDIUM | 4    |
| 10    | A10:2025 — Mishandling of Exceptional Conditions | `error-` | A10:2025 | MEDIUM | 6       |

## File naming convention

```
<prefix>-<short-name>.md
```

Examples:
- `access-cors-strict.md`
- `inject-parameterized-sql.md`
- `error-fail-closed.md`

## Rule file format

Each rule file must follow the template in `_template.md`.
