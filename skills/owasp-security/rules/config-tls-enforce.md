## Enforce HTTPS-only with minimum TLS 1.2

All application traffic must use TLS 1.2 or 1.3. HTTP traffic exposes
credentials, session cookies, and data to eavesdropping. CWE-319 (Cleartext
Transmission of Sensitive Information).

**Incorrect (HTTP allowed, no redirect):**

```typescript
app.listen(80);
app.use(session({ cookie: { secure: false } }));
```

**Correct (force HTTPS redirect and secure cookies):**

```typescript
app.use((req, res, next) => {
  if (req.header('x-forwarded-proto') !== 'https') {
    return res.redirect(301, `https://${req.hostname}${req.url}`);
  }
  next();
});

app.set('trust proxy', 1);

app.use(session({
  cookie: { secure: true, httpOnly: true, sameSite: 'strict' },
}));
```

**Azure/Cloud:**

Enable "HTTPS Only" in Azure App Service Settings. Set minimum TLS version to
1.2 in App Service TLS/SSL settings.

**References:**
- https://owasp.org/Top10/2025/A02_2025-Security_Misconfiguration/
- CWE-319: https://cwe.mitre.org/data/definitions/319.html
