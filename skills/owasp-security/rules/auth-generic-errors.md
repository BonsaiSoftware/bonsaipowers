## Return identical error messages for all auth failures

If login returns "User not found" vs "Incorrect password", attackers can
enumerate valid usernames. All auth failure responses must be indistinguishable.
CWE-203 (Observable Discrepancy).

**Incorrect (different errors reveal account existence):**

```typescript
app.post('/login', async (req, res) => {
  const user = await db.findUser(req.body.email);
  if (!user) return res.status(401).json({ error: 'User not found' });
  if (!await argon2.verify(user.hash, req.body.password))
    return res.status(401).json({ error: 'Incorrect password' });
});
```

**Correct (identical responses):**

```typescript
const GENERIC_AUTH_ERROR = 'Invalid email or password';

app.post('/login', async (req, res) => {
  const { email, password } = loginSchema.parse(req.body);
  const user = await db.findUser(email);
  const dummyHash = '$argon2id$v=19$m=65536,t=3,p=4$dummysalt$dummyhash';
  const valid = await argon2.verify(user?.hash || dummyHash, password);
  if (!user || !valid) {
    return res.status(401).json({ error: GENERIC_AUTH_ERROR });
  }
});
```

**Azure/Cloud:**

Azure AD / Entra ID returns generic error messages by default. Enable Azure AD
Identity Protection to detect enumeration attack patterns.

**References:**
- https://owasp.org/Top10/2025/A07_2025-Authentication_Failures/
- CWE-203: https://cwe.mitre.org/data/definitions/203.html
