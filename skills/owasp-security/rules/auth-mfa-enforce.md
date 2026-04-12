## Implement MFA — delegate to Azure AD/Entra ID where possible

Password-only authentication is insufficient. MFA adds a second factor that
attackers cannot replay. CWE-308 (Use of Single-factor Authentication).

**Incorrect (password-only authentication):**

```typescript
app.post('/login', async (req, res) => {
  const user = await db.findUser(req.body.email);
  if (user && await argon2.verify(user.hash, req.body.password)) {
    req.session.userId = user.id;
  }
});
```

**Correct (delegated to Azure AD with built-in MFA):**

```typescript
import { MsalProvider } from '@azure/msal-react';
import { PublicClientApplication } from '@azure/msal-browser';

const msalConfig = {
  auth: {
    clientId: process.env.REACT_APP_CLIENT_ID!,
    authority: `https://login.microsoftonline.com/${process.env.REACT_APP_TENANT_ID}`,
    redirectUri: window.location.origin,
  },
  cache: { cacheLocation: 'memoryStorage' },
};
```

**Azure/Cloud:**

Enable Azure AD Conditional Access policies requiring MFA for all users.
Use Azure AD Identity Protection for risk-based MFA.

**References:**
- https://owasp.org/Top10/2025/A07_2025-Authentication_Failures/
- CWE-308: https://cwe.mitre.org/data/definitions/308.html
