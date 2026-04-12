## Apply rate limiting to auth and business-critical endpoints

Rate limiting is a design-level control. Authentication endpoints need strict
limits, business endpoints need logic-appropriate limits. CWE-770.

**Incorrect (no rate limiting):**

```typescript
app.post('/login', loginHandler);
app.post('/api/purchase', purchaseHandler);
```

**Correct (tiered rate limiting):**

```typescript
import rateLimit from 'express-rate-limit';

app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
}));

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  skipSuccessfulRequests: true,
});
app.post('/login', authLimiter, loginHandler);
```

**Azure/Cloud:**

Azure API Management provides rate limiting via `rate-limit` and `quota` policies.
Azure Front Door has built-in rate limiting rules.

**References:**
- https://owasp.org/Top10/2025/A06_2025-Insecure_Design/
- CWE-770: https://cwe.mitre.org/data/definitions/770.html
