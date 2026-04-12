## Implement centralized error handler returning generic messages

Every Express application needs a final error-handling middleware that logs the
full error internally and returns only a generic message. CWE-209.

**Incorrect (no error handler):**

```typescript
app.get('/api/data', async (req, res) => {
  const data = await db.query('SELECT * FROM sensitive_table');
  res.json(data);
});
```

**Correct (centralized error handler with correlation IDs):**

```typescript
import { randomUUID } from 'node:crypto';

app.use((req, res, next) => {
  req.id = req.headers['x-request-id'] as string || randomUUID();
  res.setHeader('x-request-id', req.id);
  next();
});

class AppError extends Error {
  constructor(public message: string, public statusCode: number, public isOperational = true) {
    super(message);
  }
}

app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  logger.error({
    event: 'REQUEST_ERROR',
    requestId: req.id,
    error: err.message,
    stack: err.stack,
  });
  if (err instanceof AppError && err.isOperational) {
    return res.status(err.statusCode).json({ error: err.message, requestId: req.id });
  }
  res.status(500).json({ error: 'An unexpected error occurred', requestId: req.id });
});
```

**Azure/Cloud:**

Azure Application Insights `trackException()` captures full exception details.
Set `NODE_ENV=production` on App Service to disable Express verbose errors.

**References:**
- https://owasp.org/Top10/2025/A10_2025-Mishandling_of_Exceptional_Conditions/
- CWE-209: https://cwe.mitre.org/data/definitions/209.html
