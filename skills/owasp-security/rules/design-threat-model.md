## Perform threat modeling for critical flows

Insecure design is an architectural problem. Threat modeling identifies what can
go wrong before code is written. Use STRIDE or PASTA for systematic analysis.

**Incorrect (no threat modeling):**

```text
# Feature: User password reset
# Design: Send reset link via email
# Implementation: Build it, ship it, fix security bugs later
```

**Correct (threat model drives security requirements):**

```text
# Feature: User password reset
# Threat model (STRIDE):
# - Spoofing: Rate limit to 3 requests/hour per email
# - Tampering: HMAC-signed token with 15-min expiry
# - Repudiation: Log reset requests with IP + timestamp
# - Info Disclosure: Always return "If account exists, email sent"
# - DoS: Rate limit + CAPTCHA after 5 attempts
# - Elevation: Invalidate all tokens on password change
```

```typescript
app.post('/api/reset-password', rateLimit({ max: 3, windowMs: 3600000 }),
  async (req, res) => {
    const { email } = resetRequestSchema.parse(req.body);
    res.json({ message: 'If an account exists, a reset email has been sent' });
    const user = await User.findByEmail(email);
    if (user) {
      const token = generateSignedToken(user.id, '15m');
      await sendResetEmail(user.email, token);
    }
  });
```

**Azure/Cloud:**

Use Microsoft Threat Modeling Tool for Azure architectures.

**References:**
- https://owasp.org/Top10/2025/A06_2025-Insecure_Design/
