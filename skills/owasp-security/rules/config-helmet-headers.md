## Use helmet for CSP, HSTS, X-Frame-Options headers

Express sends no security headers by default. The `helmet` middleware sets 11
HTTP response headers that mitigate common browser-based attacks. CWE-693
(Protection Mechanism Failure).

**Incorrect (no security headers):**

```typescript
import express from 'express';
const app = express();
app.get('/', (req, res) => res.send('Hello'));
```

**Correct (helmet sets all recommended security headers):**

```typescript
import express from 'express';
import helmet from 'helmet';

const app = express();
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https:'],
      connectSrc: ["'self'", 'https://api.example.com'],
      objectSrc: ["'none'"],
      upgradeInsecureRequests: [],
    },
  },
  hsts: { maxAge: 31536000, includeSubDomains: true, preload: true },
  referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
}));
```

**Azure/Cloud:**

Azure Front Door and Application Gateway can inject security headers at the
edge. Azure Static Web Apps supports custom headers in `staticwebapp.config.json`.

**References:**
- https://owasp.org/Top10/2025/A02_2025-Security_Misconfiguration/
- https://helmetjs.github.io/
