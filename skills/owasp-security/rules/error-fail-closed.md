## Default to deny on errors — never fail open

When security checks throw exceptions, the application must default to denying
access. CWE-636 (Not Failing Securely).

**Incorrect (exception leaves isAdmin undefined):**

```typescript
app.get('/admin', (req, res) => {
  let isAdmin;
  try {
    isAdmin = checkAdminStatus(req.user);
  } catch (e) {
    // Error swallowed — isAdmin stays undefined
  }
  if (isAdmin !== false) {
    return res.json(getAdminData());
  }
  res.status(403).json({ error: 'Forbidden' });
});
```

**Correct (default to deny, explicit false on error):**

```typescript
app.get('/admin', (req, res) => {
  let isAdmin = false; // DEFAULT: DENY
  try {
    isAdmin = checkAdminStatus(req.user);
  } catch (e) {
    logger.warn({ event: 'ADMIN_CHECK_ERROR', userId: req.user?.id });
    isAdmin = false;
  }
  if (!isAdmin) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  res.json(getAdminData());
});
```

**Azure/Cloud:**

Configure Azure API Management `<on-error>` to return 403/500 on backend
failures. Azure AD Conditional Access fails closed by default.

**References:**
- https://owasp.org/Top10/2025/A10_2025-Mishandling_of_Exceptional_Conditions/
- CWE-636: https://cwe.mitre.org/data/definitions/636.html
