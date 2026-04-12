## Validate JWT aud, iss, exp claims — use RS256 algorithm

JWTs must be fully validated: algorithm, audience, issuer, expiry, and signature.
CWE-347 (Improper Verification of Cryptographic Signature).

**Incorrect (minimal validation):**

```typescript
import jwt from 'jsonwebtoken';
const payload = jwt.verify(token, publicKey);
```

**Correct (full claim validation with algorithm pinning):**

```typescript
import jwt from 'jsonwebtoken';

function validateToken(token: string): JwtPayload {
  const payload = jwt.verify(token, publicKey, {
    algorithms: ['RS256'],
    audience: process.env.CLIENT_ID,
    issuer: `https://login.microsoftonline.com/${TENANT_ID}/v2.0`,
    clockTolerance: 30,
  });
  if (typeof payload === 'object' && !payload.sub) {
    throw new Error('Missing subject claim');
  }
  return payload as JwtPayload;
}
```

**Azure/Cloud:**

Use `@azure/msal-node` for token validation. Azure API Management `validate-jwt`
policy enforces token validation at the gateway level.

**References:**
- https://owasp.org/Top10/2025/A07_2025-Authentication_Failures/
- CWE-347: https://cwe.mitre.org/data/definitions/347.html
