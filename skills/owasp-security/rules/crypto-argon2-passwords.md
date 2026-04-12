## Hash passwords with Argon2id — never MD5 or SHA

MD5 and SHA-family hashes are fast — an attacker with a GPU can test billions
per second. Argon2id is the recommended password hashing algorithm. CWE-916
(Use of Password Hash With Insufficient Computational Effort).

**Incorrect (fast hash):**

```typescript
import crypto from 'node:crypto';
const hash = crypto.createHash('md5').update(password).digest('hex');
```

**Correct (Argon2id with automatic salt):**

```typescript
import argon2 from 'argon2';

const hash = await argon2.hash(password, {
  type: argon2.argon2id,
  memoryCost: 65536,
  timeCost: 3,
  parallelism: 4,
});

const valid = await argon2.verify(storedHash, inputPassword);
```

**Azure/Cloud:**

For Azure AD / Entra ID authentication, password hashing is handled by the
identity provider. When managing passwords directly, use the `argon2` npm package.

**References:**
- https://owasp.org/Top10/2025/A04_2025-Cryptographic_Failures/
- CWE-916: https://cwe.mitre.org/data/definitions/916.html
