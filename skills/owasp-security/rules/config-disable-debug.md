## Disable debug mode, x-powered-by, and stack traces in production

Verbose error messages in production reveal stack traces, file paths, database
query structures, and library versions. CWE-209 (Information Exposure Through
an Error Message).

**Incorrect (debug mode and verbose errors in production):**

```typescript
app.use((err, req, res, next) => {
  res.status(500).json({
    error: err.message,
    stack: err.stack,
    query: err.sql,
  });
});
```

**Correct (generic errors externally, detailed logs internally):**

```typescript
if (process.env.NODE_ENV !== 'production') {
  console.warn('WARNING: NODE_ENV is not set to production');
}

app.disable('x-powered-by');

app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  logger.error({
    event: 'UNHANDLED_ERROR',
    message: err.message,
    stack: err.stack,
    path: req.path,
    requestId: req.id,
  });
  res.status(500).json({
    error: 'Internal server error',
    requestId: req.id,
  });
});
```

**Azure/Cloud:**

Set `NODE_ENV=production` in Azure App Service Application Settings. Disable
Remote Debugging. Enable Azure Application Insights for internal error tracking.

**References:**
- https://owasp.org/Top10/2025/A02_2025-Security_Misconfiguration/
- CWE-209: https://cwe.mitre.org/data/definitions/209.html
