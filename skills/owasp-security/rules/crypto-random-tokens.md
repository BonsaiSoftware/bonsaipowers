## Use crypto.randomBytes() for tokens — never Math.random()

`Math.random()` uses a PRNG seeded from a predictable source. Security tokens
must use a CSPRNG. CWE-330 (Use of Insufficiently Random Values).

**Incorrect (predictable token generation):**

```typescript
const token = Math.random().toString(36).substring(2);
```

**Correct (cryptographically secure random generation):**

```typescript
import crypto from 'node:crypto';

const token = crypto.randomBytes(32).toString('hex');
const urlSafeToken = crypto.randomBytes(32).toString('base64url');
const apiKey = `sk_${crypto.randomBytes(24).toString('base64url')}`;
const id = crypto.randomUUID();
```

**Azure/Cloud:**

Azure Key Vault can generate cryptographic keys server-side. For token
generation in Azure Functions, use the Node.js `crypto` module.

**References:**
- https://owasp.org/Top10/2025/A04_2025-Cryptographic_Failures/
- CWE-330: https://cwe.mitre.org/data/definitions/330.html
