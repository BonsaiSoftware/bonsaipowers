## Run npm audit and SCA scanning in every build

Software Composition Analysis (SCA) detects known vulnerabilities in
dependencies before they reach production. CWE-1395 (Dependency on Vulnerable
Third-Party Component).

**Incorrect (no vulnerability scanning in CI):**

```yaml
steps:
  - run: npm install
  - run: npm run build
  - run: npm run deploy
```

**Correct (audit integrated into CI with fail thresholds):**

```yaml
steps:
  - run: npm ci
  - run: npm audit --audit-level=high --omit=dev
  - run: npm run build
  - run: npx snyk test --severity-threshold=high
```

**Azure/Cloud:**

Enable Microsoft Defender for DevOps. Use GitHub Advanced Security dependency
alerts. Azure DevOps Advanced Security includes SCA as a pipeline task.

**References:**
- https://owasp.org/Top10/2025/A03_2025-Software_Supply_Chain_Failures/
- CWE-1395: https://cwe.mitre.org/data/definitions/1395.html
