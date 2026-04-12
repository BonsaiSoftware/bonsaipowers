## Store keys in Azure Key Vault with Managed Identity access

Encryption keys and signing keys should never exist in application code.
Azure Key Vault provides HSM-backed storage with access policies, audit
logging, and automatic rotation. CWE-321 (Use of Hard-coded Cryptographic Key).

**Incorrect (keys in code):**

```typescript
const ENCRYPTION_KEY = Buffer.from('0123456789abcdef0123456789abcdef', 'hex');
```

**Correct (Azure Key Vault with Managed Identity):**

```typescript
import { SecretClient } from '@azure/keyvault-secrets';
import { DefaultAzureCredential } from '@azure/identity';

const credential = new DefaultAzureCredential();
const vaultUrl = `https://${process.env.KEYVAULT_NAME}.vault.azure.net`;
const client = new SecretClient(vaultUrl, credential);

const secret = await client.getSecret('encryption-key');
```

**Azure/Cloud:**

Enable Key Vault soft-delete and purge protection. Use RBAC to scope access
per service. Set up key rotation policies with automatic rotation.

**References:**
- https://owasp.org/Top10/2025/A04_2025-Cryptographic_Failures/
- CWE-321: https://cwe.mitre.org/data/definitions/321.html
