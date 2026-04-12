## Use execFile() with argument arrays — never exec() with strings

`child_process.exec()` passes the entire string to a shell where special
characters enable command injection. `execFile()` passes arguments as an array
directly to the process with no shell interpretation. CWE-78 (OS Command Injection).

**Incorrect (user input in shell command string):**

```typescript
import { exec } from 'node:child_process';
app.get('/lookup', (req, res) => {
  exec(`nslookup ${req.query.domain}`, (err, stdout) => {
    res.send(stdout);
  });
});
```

**Correct (execFile with argument array):**

```typescript
import { execFile } from 'node:child_process';
import { z } from 'zod';

const domainSchema = z.string().regex(/^[a-zA-Z0-9.-]+$/);

app.get('/lookup', (req, res) => {
  const domain = domainSchema.parse(req.query.domain);
  execFile('nslookup', [domain], { timeout: 5000 }, (err, stdout) => {
    if (err) return res.status(500).json({ error: 'Lookup failed' });
    res.send(stdout);
  });
});
```

**Azure/Cloud:**

Avoid shelling out in Azure Functions — use native Node.js APIs or Azure SDKs.

**References:**
- https://owasp.org/Top10/2025/A05_2025-Injection/
- CWE-78: https://cwe.mitre.org/data/definitions/78.html
