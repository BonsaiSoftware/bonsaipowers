## Scope private packages to prevent dependency confusion

Dependency confusion exploits registries resolving a public package with
the same name as your private one. Attackers publish a higher-version
public package that gets installed instead. CWE-427.

**Incorrect (unscoped private package with no registry pinning):**

```json
{
  "dependencies": {
    "my-company-utils": "^1.0.0"
  }
}
```

**Correct (scoped package + registry pinning in .npmrc):**

```json
{
  "dependencies": {
    "@my-company/utils": "1.2.0"
  }
}
```

```ini
# .npmrc — pin scope to private registry
@my-company:registry=https://pkgs.dev.azure.com/my-org/_packaging/my-feed/npm/registry/
always-auth=true
```

Reserve your scope name on npmjs.com even if you never publish publicly.

**Azure/Cloud:**

Azure Artifacts supports upstream sources with package name reservation.
Enable "Allow external versions" only for trusted feeds.

**References:**
- https://owasp.org/Top10/2025/A03_2025-Software_Supply_Chain_Failures/
- CWE-427: https://cwe.mitre.org/data/definitions/427.html
