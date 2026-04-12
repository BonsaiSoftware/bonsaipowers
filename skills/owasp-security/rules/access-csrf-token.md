## Prevent CSRF with SameSite cookies and tokens

Cross-Site Request Forgery tricks authenticated browsers into submitting
state-changing requests. SameSite cookies are the primary defense; tokens
add defense-in-depth for older browsers. CWE-352.

**Incorrect (no CSRF protection on state-changing endpoint):**

```typescript
app.post('/api/transfer', authenticate, async (req, res) => {
  await transfer(req.user.id, req.body.to, req.body.amount);
  res.json({ success: true });
});
```

**Correct (SameSite cookie + CSRF token for forms):**

```typescript
import csrf from 'csrf';
const tokens = new csrf();

app.use(session({
  cookie: { sameSite: 'strict', secure: true, httpOnly: true },
}));

app.use((req, res, next) => {
  if (!req.session.csrfSecret) req.session.csrfSecret = tokens.secretSync();
  res.locals.csrfToken = tokens.create(req.session.csrfSecret);
  next();
});

app.post('/api/transfer', authenticate, (req, res, next) => {
  if (!tokens.verify(req.session.csrfSecret, req.body._csrf)) {
    return res.status(403).json({ error: 'Invalid CSRF token' });
  }
  next();
}, transferHandler);
```

**Azure/Cloud:**

Azure App Service sets ARR Affinity cookies without SameSite — override
with custom session cookies. API-only backends using Bearer tokens are
inherently CSRF-safe (tokens aren't sent automatically by browsers).

**References:**
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/
- CWE-352: https://cwe.mitre.org/data/definitions/352.html
