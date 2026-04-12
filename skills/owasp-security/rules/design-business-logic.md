## Validate business rules server-side with plausibility checks

Business logic attacks exploit the gap between what the UI allows and what the
API accepts. CWE-840 (Business Logic Errors).

**Incorrect (trusting client-provided business data):**

```typescript
app.post('/api/checkout', authenticate, async (req, res) => {
  const { items, totalPrice } = req.body;
  await createOrder(req.user.id, items, totalPrice);
  await chargePayment(req.user.id, totalPrice);
});
```

**Correct (server calculates and validates all business logic):**

```typescript
app.post('/api/checkout', authenticate, async (req, res) => {
  const { items } = checkoutSchema.parse(req.body);
  const pricing = await calculatePricing(items);
  if (pricing.total <= 0) {
    return res.status(400).json({ error: 'Invalid order total' });
  }
  for (const item of items) {
    if (item.quantity < 1 || item.quantity > 50) {
      return res.status(400).json({ error: 'Invalid quantity' });
    }
  }
  const order = await db.transaction(async (tx) => {
    await deductStock(tx, items);
    const order = await createOrder(tx, req.user.id, items, pricing.total);
    await chargePayment(req.user.id, pricing.total);
    return order;
  });
  res.json(order);
});
```

**Azure/Cloud:**

Use Azure Durable Functions for multi-step business workflows. Azure Cosmos DB
stored procedures execute atomic multi-document operations.

**References:**
- https://owasp.org/Top10/2025/A06_2025-Insecure_Design/
- CWE-840: https://cwe.mitre.org/data/definitions/840.html
