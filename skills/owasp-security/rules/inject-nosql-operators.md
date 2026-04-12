## Use explicit $eq operators in MongoDB to prevent operator injection

MongoDB accepts objects as query values. An attacker can send `{"$gt": ""}`
instead of a string, changing query semantics. CWE-943.

**Incorrect (user object used directly in query):**

```typescript
app.post('/login', async (req, res) => {
  const user = await db.collection('users').findOne({
    username: req.body.username,
    password: req.body.password,
  });
  if (user) return res.json({ token: generateToken(user) });
});
```

**Correct (explicit $eq and type validation):**

```typescript
import { z } from 'zod';

const loginSchema = z.object({
  username: z.string().min(1).max(100),
  password: z.string().min(1).max(128),
});

app.post('/login', async (req, res) => {
  const { username, password } = loginSchema.parse(req.body);
  const user = await db.collection('users').findOne({
    username: { $eq: username },
  });
  if (!user || !(await argon2.verify(user.passwordHash, password))) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  res.json({ token: generateToken(user) });
});
```

**Azure/Cloud:**

Azure Cosmos DB with MongoDB API supports parameterized queries. Use Mongoose
with `sanitizeFilter` option to strip MongoDB operators from user input.

**References:**
- https://owasp.org/Top10/2025/A05_2025-Injection/
- CWE-943: https://cwe.mitre.org/data/definitions/943.html
