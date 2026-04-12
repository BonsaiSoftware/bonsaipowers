---
name: owasp-security
description: OWASP Top 10 2025 security patterns for React, Node.js, Azure, and cloud-native applications. Use when writing, reviewing, or refactoring code to prevent security vulnerabilities. Triggers on tasks involving authentication, authorization, input handling, API endpoints, error handling, dependency management, secrets management, cryptography, logging, monitoring, or security configuration. Also triggers when reviewing pull requests, setting up CI/CD pipelines, configuring cloud infrastructure, or implementing middleware. Apply proactively — don't wait for explicit security requests.
---

# OWASP Security Patterns — Top 10 2025

Comprehensive application security guide based on the **OWASP Top 10:2025**, tailored
for React frontends, Node.js backends, Azure cloud services, and cloud-native
architectures. Contains **59 rules** across **10 categories**, each with vulnerable
and secure code examples, prioritized by risk severity.

Based on analysis of **175,000+ CVEs** across **589 CWEs** in **248 categories**.

## When to apply

Reference these guidelines when:

- Writing or reviewing authentication, authorization, or session management logic
- Handling user input, form data, query parameters, or API request/response bodies
- Implementing API endpoints, middleware, or server-side business logic
- Managing secrets, credentials, environment variables, or cryptographic operations
- Configuring Express/Fastify middleware, security headers, or CORS policies
- Setting up CI/CD pipelines, dependencies, Docker images, or deployment infrastructure
- Implementing error handling, logging, monitoring, or alerting
- Deploying to Azure App Service, AKS, Azure Functions, or any cloud environment

## Rule categories by OWASP risk ranking

| Priority | Category                  | Severity | Rules | Prefix       | OWASP    |
|----------|---------------------------|----------|-------|--------------|----------|
| 1        | Broken Access Control     | CRITICAL | 13    | `access-`    | A01:2025 |
| 2        | Security Misconfiguration | CRITICAL | 8     | `config-`    | A02:2025 |
| 3        | Software Supply Chain     | CRITICAL | 5     | `supply-`    | A03:2025 |
| 4        | Cryptographic Failures    | HIGH     | 4     | `crypto-`    | A04:2025 |
| 5        | Injection                 | HIGH     | 7     | `inject-`    | A05:2025 |
| 6        | Insecure Design           | HIGH     | 3     | `design-`    | A06:2025 |
| 7        | Authentication Failures   | HIGH     | 5     | `auth-`      | A07:2025 |
| 8        | Integrity Failures        | MEDIUM   | 4     | `integrity-` | A08:2025 |
| 9        | Logging & Alerting        | MEDIUM   | 4     | `logging-`   | A09:2025 |
| 10       | Exceptional Conditions    | MEDIUM   | 6     | `error-`     | A10:2025 |

## Quick reference

### 1. Broken Access Control (CRITICAL) — A01:2025

- `access-deny-default` — Deny access by default; require explicit grants
- `access-server-side-authz` — Enforce all authorization server-side, never trust the client
- `access-ownership-check` — Verify record ownership before CRUD operations
- `access-cors-strict` — Configure CORS with specific allowed origins, never wildcard
- `access-ssrf-allowlist` — Validate and allowlist URLs for server-side requests
- `access-csrf-token` — Prevent CSRF with SameSite cookies and tokens
- `access-path-traversal` — Prevent path traversal when serving user-controlled paths
- `access-open-redirect` — Validate redirect targets against an allowlist
- `access-rsc-data-leakage` — Prevent sensitive data leakage across RSC/client boundary
- `access-nextjs-image-ssrf` — Restrict next/image remotePatterns to prevent SSRF
- `access-nextjs-auth-layers` — Verify auth in every server layer, not just middleware
- `access-nextjs-route-handlers` — Secure Route Handlers with explicit CORS, auth, rate limiting
- `access-nextjs-revalidation-auth` — Authenticate revalidation calls to prevent cache poisoning

### 2. Security Misconfiguration (CRITICAL) — A02:2025

- `config-helmet-headers` — Use helmet for CSP, HSTS, X-Frame-Options headers
- `config-env-secrets` — Store secrets in Key Vault or env vars, never in code
- `config-disable-debug` — Disable debug mode, x-powered-by, and stack traces in production
- `config-tls-enforce` — Enforce HTTPS-only with minimum TLS 1.2
- `config-xxe-disable` — Disable XML external entity processing
- `config-nextjs-env-exposure` — Never prefix secrets with NEXT_PUBLIC_
- `config-nextjs-headers` — Set security headers in Next.js via middleware
- `config-nextjs-static-exposure` — Exclude sensitive data from statically generated pages

### 3. Software Supply Chain (CRITICAL) — A03:2025

- `supply-pin-versions` — Pin dependency versions; avoid wildcards and latest
- `supply-lockfile-ci` — Use npm ci with committed lockfile in CI pipelines
- `supply-audit-pipeline` — Run npm audit and SCA scanning in every build
- `supply-sbom-generate` — Generate and maintain Software Bill of Materials
- `supply-dependency-confusion` — Scope private packages to prevent dependency confusion

### 4. Cryptographic Failures (HIGH) — A04:2025

- `crypto-argon2-passwords` — Hash passwords with Argon2id, never MD5/SHA
- `crypto-random-tokens` — Use crypto.randomBytes(), never Math.random()
- `crypto-aes-gcm` — Use AES-256-GCM authenticated encryption, never ECB
- `crypto-keyvault-secrets` — Store keys in Azure Key Vault with Managed Identity

### 5. Injection (HIGH) — A05:2025

- `inject-parameterized-sql` — Use parameterized queries, never string concatenation
- `inject-xss-escape` — Use React auto-escaping; avoid dangerouslySetInnerHTML
- `inject-nosql-operators` — Use explicit $eq operators in MongoDB queries
- `inject-command-execfile` — Use execFile() with argument arrays, never exec()
- `inject-zod-validation` — Validate all input with Zod/Joi schemas on the server
- `inject-csp-headers` — Set Content-Security-Policy to restrict script sources
- `inject-prototype-pollution` — Guard against prototype pollution in object merges

### 6. Insecure Design (HIGH) — A06:2025

- `design-threat-model` — Perform threat modeling (STRIDE/PASTA) for critical flows
- `design-rate-limit` — Apply rate limiting to auth and business-critical endpoints
- `design-business-logic` — Validate business rules server-side with plausibility checks

### 7. Authentication Failures (HIGH) — A07:2025

- `auth-mfa-enforce` — Implement MFA; delegate to Azure AD/Entra ID where possible
- `auth-session-secure` — Configure sessions with secure, httpOnly, sameSite cookies
- `auth-jwt-validate` — Validate JWT aud, iss, exp claims; use RS256 algorithm
- `auth-generic-errors` — Return identical error messages for all auth failures
- `auth-password-breach-check` — Check new passwords against breached credential databases

### 8. Software/Data Integrity (MEDIUM) — A08:2025

- `integrity-json-parse` — Use JSON.parse(), never eval() for deserialization
- `integrity-sri-cdn` — Add Subresource Integrity hashes to all CDN script tags
- `integrity-signed-artifacts` — Sign and verify build artifacts in CI/CD pipelines
- `integrity-cicd-pipeline` — Harden CI/CD pipelines against injection and tampering

### 9. Security Logging & Alerting (MEDIUM) — A09:2025

- `logging-structured-json` — Use structured JSON logging (Winston/Pino) for security events
- `logging-sanitize-input` — Encode log inputs to prevent log injection/forging
- `logging-no-sensitive-data` — Never log passwords, tokens, PII, or credit card numbers
- `logging-alert-thresholds` — Configure alerts for failed logins, error spikes, access violations

### 10. Exceptional Conditions (MEDIUM) — A10:2025

- `error-fail-closed` — Default to deny on errors; never fail open
- `error-global-handler` — Implement centralized error handler returning generic messages
- `error-resource-cleanup` — Use try/finally to release resources on all code paths
- `error-transaction-rollback` — Roll back entire transactions on error
- `error-boundary-react` — Wrap React component trees in ErrorBoundary with fallback UI
- `error-unhandled-rejection` — Handle unhandledRejection and uncaughtException globally

## How to Use

**IMPORTANT: Do NOT read the compiled guide. Use the Quick Reference above to identify 2-5 relevant rules, then read only those files.**

1. Review the Quick Reference above to find rules that apply to the current task
2. Read only the relevant rule files using the Read tool:
   - Example: For CORS → `rules/access-cors-strict.md`
   - Example: For input validation → `rules/inject-zod-validation.md` and `rules/inject-xss-escape.md`
   - Example: For auth → `rules/auth-session-secure.md` and `rules/auth-jwt-validate.md`
3. Each rule file contains: security risk, vulnerable code, secure code, Azure/cloud guidance
4. Rule file path: `rules/<prefix>-<name>.md`
5. Prefix mapping: `access-` (A01), `config-` (A02), `supply-` (A03), `crypto-` (A04), `inject-` (A05), `design-` (A06), `auth-` (A07), `integrity-` (A08), `logging-` (A09), `error-` (A10)

### For comprehensive security reviews

Identify which 1-3 OWASP categories are relevant based on what the code does, then read those categories' rules. Do not read all 59 rules.