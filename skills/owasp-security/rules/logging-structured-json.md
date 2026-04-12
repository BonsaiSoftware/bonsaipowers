## Use structured JSON logging for all security events

Text-based `console.log()` is unparseable by log aggregation systems. Structured
JSON logging enables querying and alerting. CWE-778 (Insufficient Logging).

**Incorrect (unstructured console.log):**

```typescript
console.log('User login failed');
console.log(`Error: ${error.message}`);
```

**Correct (structured JSON logging):**

```typescript
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  redact: ['req.headers.authorization', 'req.body.password'],
  timestamp: pino.stdTimeFunctions.isoTime,
});

logger.warn({
  event: 'AUTH_FAILURE',
  username: req.body.username,
  ip: req.ip,
  userAgent: req.headers['user-agent'],
  path: req.path,
  reason: 'invalid_password',
});
```

**Azure/Cloud:**

Stream logs to Azure Application Insights. Use Azure Log Analytics Workspace
with KQL queries. Application Insights auto-correlates requests across services.

**References:**
- https://owasp.org/Top10/2025/A09_2025-Security_Logging_and_Alerting_Failures/
- CWE-778: https://cwe.mitre.org/data/definitions/778.html
