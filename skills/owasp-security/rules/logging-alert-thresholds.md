## Configure alerts for failed logins, error spikes, and access violations

Logging without alerting provides minimal value. You need automated alerts on
security-relevant event thresholds. CWE-223.

**Incorrect (logging without alerting):**

```typescript
logger.warn({ event: 'AUTH_FAILURE', username, ip });
```

**Correct (structured logging + alerting thresholds):**

```typescript
const failedLoginCounts = new Map<string, { count: number; first: number }>();

function trackAuthFailure(ip: string, username: string) {
  logger.warn({ event: 'AUTH_FAILURE', username, ip });
  const key = `${ip}:${username}`;
  const entry = failedLoginCounts.get(key) || { count: 0, first: Date.now() };
  entry.count++;
  failedLoginCounts.set(key, entry);
  if (entry.count >= 10) {
    logger.error({
      event: 'BRUTE_FORCE_DETECTED',
      ip, username,
      attempts: entry.count,
    });
  }
}
```

**Azure/Cloud:**

Use Microsoft Sentinel as SIEM. Configure Azure Monitor Alert Rules with
Action Groups. Enable Azure AD Identity Protection.

**References:**
- https://owasp.org/Top10/2025/A09_2025-Security_Logging_and_Alerting_Failures/
- CWE-778: https://cwe.mitre.org/data/definitions/778.html
