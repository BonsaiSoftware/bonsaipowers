## Validate and allowlist URLs for server-side requests

Server-Side Request Forgery (SSRF) occurs when an application fetches a
user-supplied URL without validation. Attackers target internal services
(localhost, 169.254.169.254 for cloud metadata, private IPs). CWE-918.

**Incorrect (user-controlled URL fetched without validation):**

```typescript
app.post('/api/fetch-url', async (req, res) => {
  const response = await fetch(req.body.url);
  const data = await response.text();
  res.json({ data });
});
```

**Correct (URL validation with protocol and host allowlist):**

```typescript
import { URL } from 'node:url';

const ALLOWED_HOSTS = ['api.example.com', 'cdn.example.com'];

function validateExternalUrl(input: string): URL {
  const url = new URL(input);
  if (!['https:'].includes(url.protocol)) {
    throw new Error('Only HTTPS URLs are allowed');
  }
  if (!ALLOWED_HOSTS.includes(url.hostname)) {
    throw new Error('Host not in allowlist');
  }
  return url;
}

app.post('/api/fetch-url', async (req, res) => {
  try {
    const url = validateExternalUrl(req.body.url);
    const response = await fetch(url.toString(), { redirect: 'error' });
    const data = await response.text();
    res.json({ data });
  } catch (e) {
    res.status(400).json({ error: 'Invalid URL' });
  }
});
```

**Azure/Cloud:**

Disable the Azure Instance Metadata Service (IMDS) if not needed, or use Azure
Network Security Groups to restrict outbound traffic. Use Azure Private
Endpoints and VNet integration to isolate backend services.

**References:**
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/
- CWE-918: https://cwe.mitre.org/data/definitions/918.html
