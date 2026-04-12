## Verify record ownership before CRUD operations

Insecure Direct Object Reference (IDOR) occurs when an API accepts a user-supplied
ID and returns data without verifying the requesting user owns that record.
CWE-639 (Authorization Bypass Through User-Controlled Key).

**Incorrect (no ownership verification — any user reads any order):**

```typescript
app.get('/api/orders/:orderId', authenticate, async (req, res) => {
  const order = await Order.findById(req.params.orderId);
  if (!order) return res.status(404).json({ error: 'Not found' });
  res.json(order);
});
```

**Correct (ownership check scopes query to authenticated user):**

```typescript
app.get('/api/orders/:orderId', authenticate, async (req, res) => {
  const order = await Order.findOne({
    where: {
      id: req.params.orderId,
      userId: req.user.id,
    },
  });
  if (!order) return res.status(404).json({ error: 'Not found' });
  res.json(order);
});

function ownershipCheck(model: string, userField = 'userId') {
  return async (req: Request, res: Response, next: NextFunction) => {
    const record = await db[model].findById(req.params.id);
    if (!record || record[userField] !== req.user.id) {
      return res.status(404).json({ error: 'Not found' });
    }
    req.record = record;
    next();
  };
}
```

**Azure/Cloud:**

Use Azure Cosmos DB partition keys based on tenant/user ID to enforce data
isolation at the database level. In Azure SQL, use Row-Level Security (RLS)
policies to filter queries automatically by the authenticated user's identity.

**References:**
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/
- CWE-639: https://cwe.mitre.org/data/definitions/639.html
