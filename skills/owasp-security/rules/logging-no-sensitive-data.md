## Never log passwords, tokens, PII, or credit card numbers

Sensitive data in logs creates compliance violations and security risks.
CWE-532 (Insertion of Sensitive Information into Log File).

**Incorrect (sensitive data in logs):**

```typescript
logger.info(`User login: ${email}, password: ${password}`);
logger.info(`Payment processed: card ${cardNumber}`);
```

**Correct (redaction and field exclusion):**

```typescript
import pino from 'pino';

const logger = pino({
  redact: {
    paths: [
      'req.headers.authorization',
      'req.body.password',
      'req.body.creditCard',
      '*.token',
      '*.accessToken',
    ],
    censor: '[REDACTED]',
  },
});

logger.info({
  event: 'PAYMENT_PROCESSED',
  userId: user.id,
  cardLast4: cardNumber.slice(-4),
  orderId: order.id,
});
```

**Azure/Cloud:**

Azure Application Insights supports telemetry initializers for automatic PII
scrubbing. Use Azure Purview for data classification.

**References:**
- https://owasp.org/Top10/2025/A09_2025-Security_Logging_and_Alerting_Failures/
- CWE-532: https://cwe.mitre.org/data/definitions/532.html
