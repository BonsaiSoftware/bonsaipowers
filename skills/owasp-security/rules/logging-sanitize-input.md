## Encode log inputs to prevent log injection and forging

Attackers can inject newlines to create fake log entries. CWE-117 (Improper
Output Neutralization for Logs).

**Incorrect (raw user input in log message):**

```typescript
console.log(`[WARN] Login failed for user: ${req.body.username}`);
```

**Correct (sanitize input before logging):**

```typescript
function sanitizeForLog(input: string): string {
  return input
    .replace(/[\n\r]/g, '_')
    .replace(/[\t]/g, ' ')
    .replace(/[\x00-\x1F]/g, '')
    .substring(0, 200);
}

logger.warn({
  event: 'AUTH_FAILURE',
  username: sanitizeForLog(req.body.username),
  ip: req.ip,
});
```

**Azure/Cloud:**

Azure Application Insights and Log Analytics automatically handle JSON
structured data. Use KQL `parse_json()` for querying structured log fields.

**References:**
- https://owasp.org/Top10/2025/A09_2025-Security_Logging_and_Alerting_Failures/
- CWE-117: https://cwe.mitre.org/data/definitions/117.html
