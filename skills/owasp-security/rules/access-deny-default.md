## Deny access by default — require explicit grants

Access control must default to denying all requests, then explicitly grant
permissions to specific roles or users. The opposite pattern — allow by default,
then block specific paths — inevitably misses routes as the application grows.
This maps to CWE-276 (Incorrect Default Permissions) and CWE-285 (Improper
Authorization).

**Incorrect (allow-by-default with a blocklist of protected routes):**

```typescript
const protectedRoutes = ['/admin', '/api/users'];

app.use((req, res, next) => {
  if (protectedRoutes.includes(req.path)) {
    return requireAuth(req, res, next);
  }
  next();
});

app.get('/api/internal/reports', async (req, res) => {
  res.json(await getInternalReports());
});
```

**Correct (deny-by-default with an allowlist of public routes):**

```typescript
const publicRoutes = ['/health', '/login', '/api/public'];

app.use((req, res, next) => {
  if (publicRoutes.some((route) => req.path.startsWith(route))) {
    return next();
  }
  return requireAuth(req, res, next);
});

app.get('/api/internal/reports', async (req, res) => {
  res.json(await getInternalReports());
});
```

**Azure/Cloud:**

Use Azure App Service Authentication (EasyAuth) with "Require authentication"
enabled. For Azure API Management, set a base `<validate-jwt>` policy at the
API level and only override for explicitly public operations.

**References:**
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/
- CWE-276: https://cwe.mitre.org/data/definitions/276.html
