## Pin dependency versions — avoid wildcards and latest

Using `*`, `latest`, or wide semver ranges means your next install may pull a
compromised version. CWE-1357 (Reliance on Insufficiently Trustworthy Component).

**Incorrect (wildcard and wide-range versions):**

```json
{
  "dependencies": {
    "express": "*",
    "lodash": "^3.0.0",
    "axios": "latest"
  }
}
```

**Correct (exact pinned versions with lockfile):**

```json
{
  "dependencies": {
    "express": "4.21.2",
    "lodash": "4.17.21",
    "axios": "1.7.9"
  }
}
```

**Azure/Cloud:**

Use Azure Artifacts as an upstream source. Enable Dependabot or Azure DevOps
Advanced Security for automated dependency updates with review.

**References:**
- https://owasp.org/Top10/2025/A03_2025-Software_Supply_Chain_Failures/
- CWE-1357: https://cwe.mitre.org/data/definitions/1357.html
