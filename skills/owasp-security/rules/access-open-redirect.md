## Validate redirect targets against an allowlist

Unvalidated redirects let attackers craft links that appear to originate
from your domain but land on a phishing site. CWE-601.

**Incorrect (redirect to user-supplied URL without validation):**

```typescript
app.get('/redirect', (req, res) => {
  res.redirect(req.query.url as string);
  // /redirect?url=https://evil.com → user lands on attacker site
});
```

**Correct (allowlist of permitted redirect targets):**

```typescript
const ALLOWED_REDIRECTS = ['/', '/dashboard', '/settings'];

app.get('/redirect', (req, res) => {
  const target = req.query.url as string;
  if (!target || !ALLOWED_REDIRECTS.includes(target)) {
    return res.redirect('/');
  }
  res.redirect(target);
});

// For dynamic URLs: validate same-origin
function isSafeRedirect(url: string, host: string): boolean {
  try {
    const parsed = new URL(url, `https://${host}`);
    return parsed.host === host;
  } catch {
    return false;
  }
}
```

**Azure/Cloud:**

Azure Front Door can rewrite redirect responses at the edge. Azure AD
redirect_uri validation uses exact-match allowlists by default.

**References:**
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/
- CWE-601: https://cwe.mitre.org/data/definitions/601.html
