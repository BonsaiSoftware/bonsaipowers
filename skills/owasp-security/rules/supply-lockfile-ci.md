## Use npm ci with committed lockfile in CI pipelines

`npm install` can silently update `package-lock.json`. `npm ci` uses the exact
lockfile and fails if missing or inconsistent.

**Incorrect (npm install in CI):**

```yaml
steps:
  - run: npm install
  - run: npm run build
```

**Correct (npm ci with lockfile validation):**

```yaml
steps:
  - run: npm ci
  - run: npm audit --audit-level=high
  - run: npm run build
```

**Azure/Cloud:**

In Azure DevOps Pipelines, use the `npm ci` task. Cache `node_modules` with
the lockfile hash as the cache key.

**References:**
- https://owasp.org/Top10/2025/A03_2025-Software_Supply_Chain_Failures/
