## Use parameterized queries — never concatenate user input into SQL

SQL injection allows attackers to execute arbitrary database commands. Parameterized
queries treat user input as data, never as executable SQL. CWE-89.

**Incorrect (string concatenation):**

```typescript
const query = `SELECT * FROM users WHERE email = '${req.query.email}'`;
const result = await db.query(query);
```

**Correct (parameterized queries):**

```typescript
const { rows } = await pool.query(
  'SELECT id, email FROM users WHERE email = $1',
  [req.body.email]
);

const user = await prisma.user.findUnique({
  where: { email: validatedEmail },
});
```

**Azure/Cloud:**

Enable Azure SQL Threat Detection for SQL injection alerting. Azure WAF on
Application Gateway detects and blocks common SQL injection patterns.

**References:**
- https://owasp.org/Top10/2025/A05_2025-Injection/
- CWE-89: https://cwe.mitre.org/data/definitions/89.html
