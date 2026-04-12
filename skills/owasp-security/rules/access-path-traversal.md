## Prevent path traversal when serving user-controlled paths

`../` sequences in user input escape intended directories, reading arbitrary
files. Resolve the absolute path and verify it stays within the allowed
root. CWE-22.

**Incorrect (unsanitized filename joined to base directory):**

```typescript
app.get('/files/:name', (req, res) => {
  res.sendFile(path.join('/uploads', req.params.name));
  // GET /files/../../etc/passwd → reads /etc/passwd
});
```

**Correct (resolve + startsWith check against root):**

```typescript
import path from 'node:path';

const UPLOADS_ROOT = path.resolve('/uploads');

app.get('/files/:name', (req, res) => {
  const requested = path.resolve(UPLOADS_ROOT, req.params.name);
  if (!requested.startsWith(UPLOADS_ROOT + path.sep)) {
    return res.status(400).json({ error: 'Invalid path' });
  }
  res.sendFile(requested);
});
```

**Azure/Cloud:**

Azure Blob Storage with SAS tokens eliminates local file serving entirely.
If serving files, use App Service virtual path mappings with restricted
root directories.

**References:**
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/
- CWE-22: https://cwe.mitre.org/data/definitions/22.html
