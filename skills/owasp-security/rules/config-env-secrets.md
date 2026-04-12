## Store secrets in Key Vault or environment variables — never in code

Hard-coded credentials in source files end up in Git history, CI logs, Docker
images, and sometimes client-side bundles. CWE-798 (Use of Hard-coded Credentials).

**Incorrect (secrets in source code):**

```typescript
const JWT_SECRET = 'super-secret-key-123';
const DB_PASSWORD = 'admin123';
```

**Correct (secrets from environment variables or Key Vault):**

```typescript
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) throw new Error('JWT_SECRET not configured');

import { SecretClient } from '@azure/keyvault-secrets';
import { DefaultAzureCredential } from '@azure/identity';

const client = new SecretClient(
  `https://${process.env.KEYVAULT_NAME}.vault.azure.net`,
  new DefaultAzureCredential()
);
const dbPassword = await client.getSecret('db-password');
```

**Azure/Cloud:**

Use Azure Key Vault with Managed Identity access. Reference Key Vault secrets
in App Service via `@Microsoft.KeyVault(SecretUri=...)` syntax.

**References:**
- https://owasp.org/Top10/2025/A02_2025-Security_Misconfiguration/
- CWE-798: https://cwe.mitre.org/data/definitions/798.html
