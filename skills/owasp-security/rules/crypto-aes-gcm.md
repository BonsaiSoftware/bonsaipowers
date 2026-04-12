## Use AES-256-GCM authenticated encryption — never ECB

ECB mode encrypts each block independently, leaking patterns. AES-256-GCM
provides authenticated encryption — confidentiality AND integrity. CWE-327
(Use of a Broken or Risky Cryptographic Algorithm).

**Incorrect (ECB mode leaks patterns):**

```typescript
import crypto from 'node:crypto';
const cipher = crypto.createCipheriv('aes-256-ecb', key, null);
```

**Correct (AES-256-GCM with unique IV per encryption):**

```typescript
import crypto from 'node:crypto';

function encrypt(plaintext: string, key: Buffer): string {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return Buffer.concat([iv, authTag, encrypted]).toString('base64');
}
```

**Azure/Cloud:**

Use Azure Key Vault for key storage — keys never leave the HSM boundary.
Azure Storage Service Encryption and Azure SQL TDE use AES-256 automatically.

**References:**
- https://owasp.org/Top10/2025/A04_2025-Cryptographic_Failures/
- CWE-327: https://cwe.mitre.org/data/definitions/327.html
