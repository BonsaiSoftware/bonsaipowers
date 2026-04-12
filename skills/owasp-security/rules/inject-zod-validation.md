## Validate all input with Zod or Joi schemas on the server

Every external input must be validated for type, length, format, and range on
the server. Client-side validation is a UX convenience, not security. CWE-20.

**Incorrect (no validation):**

```typescript
app.post('/api/users', async (req, res) => {
  const user = await User.create({
    name: req.body.name,
    email: req.body.email,
    role: req.body.role,
  });
  res.json(user);
});
```

**Correct (Zod schema validates and transforms input):**

```typescript
import { z } from 'zod';

const createUserSchema = z.object({
  name: z.string().min(1).max(100).trim(),
  email: z.string().email().max(255).toLowerCase(),
  age: z.number().int().min(13).max(150).optional(),
});

app.post('/api/users', async (req, res) => {
  const data = createUserSchema.parse(req.body);
  const user = await User.create({ ...data, role: 'user' });
  res.json(user);
});
```

**Azure/Cloud:**

Azure API Management supports request validation policies including JSON schema
validation, parameter validation, and body size limits.

**References:**
- https://owasp.org/Top10/2025/A05_2025-Injection/
- CWE-20: https://cwe.mitre.org/data/definitions/20.html
