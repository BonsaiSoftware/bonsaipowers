## Check new passwords against breached credential databases

NIST SP 800-63B recommends checking passwords against known breached credentials.
The HIBP Passwords API uses k-anonymity. CWE-521 (Weak Password Requirements).

**Incorrect (only length and complexity rules):**

```typescript
function validatePassword(password: string): boolean {
  return password.length >= 8 && /[A-Z]/.test(password) && /[0-9]/.test(password);
}
```

**Correct (breach check via HIBP k-anonymity API):**

```typescript
import crypto from 'node:crypto';

async function isPasswordBreached(password: string): Promise<boolean> {
  const sha1 = crypto.createHash('sha1').update(password).digest('hex').toUpperCase();
  const prefix = sha1.slice(0, 5);
  const suffix = sha1.slice(5);
  const response = await fetch(`https://api.pwnedpasswords.com/range/${prefix}`);
  const text = await response.text();
  return text.split('\n').some((line) => line.startsWith(suffix));
}
```

**Azure/Cloud:**

Azure AD B2C supports custom password policies including banned password lists.
Azure AD has built-in banned password detection (Smart Lockout).

**References:**
- https://owasp.org/Top10/2025/A07_2025-Authentication_Failures/
- https://haveibeenpwned.com/API/v3#PwnedPasswords
