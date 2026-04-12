## Set Content-Security-Policy to restrict script sources

CSP restricts which scripts can execute. Even if an XSS vulnerability exists,
a strict CSP prevents the injected script from executing.

**Incorrect (no CSP):**

```typescript
// No Content-Security-Policy header set
// Any XSS payload executes without restriction
```

**Correct (strict CSP with nonce-based script loading):**

```typescript
import crypto from 'node:crypto';
import helmet from 'helmet';

app.use((req, res, next) => {
  res.locals.cspNonce = crypto.randomBytes(16).toString('base64');
  next();
});

app.use((req, res, next) => {
  helmet.contentSecurityPolicy({
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", `'nonce-${res.locals.cspNonce}'`],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https:'],
      objectSrc: ["'none'"],
      frameAncestors: ["'none'"],
      baseUri: ["'self'"],
      formAction: ["'self'"],
      upgradeInsecureRequests: [],
    },
  })(req, res, next);
});
```

**Azure/Cloud:**

Azure Static Web Apps support CSP in `staticwebapp.config.json`. Azure CDN
and Front Door can inject CSP headers via Rules Engine.

**References:**
- https://owasp.org/Top10/2025/A05_2025-Injection/
- https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
