## Roll back entire transactions on error — never partially commit

Database transactions must be atomic. Without proper error handling, a failure
between operations leaves the database inconsistent. CWE-460.

**Incorrect (partial commit on error):**

```typescript
async function transfer(from: string, to: string, amount: number) {
  await db.query('UPDATE accounts SET balance = balance - $1 WHERE id = $2', [amount, from]);
  await db.query('UPDATE accounts SET balance = balance + $1 WHERE id = $2', [amount, to]);
}
```

**Correct (atomic transaction with rollback):**

```typescript
async function transfer(from: string, to: string, amount: number) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('UPDATE accounts SET balance = balance - $1 WHERE id = $2', [amount, from]);
    await client.query('UPDATE accounts SET balance = balance + $1 WHERE id = $2', [amount, to]);
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw new AppError('Transfer failed', 500);
  } finally {
    client.release();
  }
}
```

**Azure/Cloud:**

Azure SQL and Cosmos DB support ACID transactions. For distributed transactions,
use the Saga pattern with Azure Durable Functions.

**References:**
- https://owasp.org/Top10/2025/A10_2025-Mishandling_of_Exceptional_Conditions/
- CWE-460: https://cwe.mitre.org/data/definitions/460.html
