## Configure CORS with specific allowed origins — never wildcard

Cross-Origin Resource Sharing (CORS) controls which external domains can call
your API from a browser. Using `*` or reflecting the Origin header without
validation allows any malicious website to make authenticated requests to your
API using the victim's cookies. CWE-942 (Permissive Cross-domain Policy).

**Incorrect (wildcard origin allows any site to call the API):**

```typescript
import cors from 'cors';

app.use(cors()); // Defaults to Access-Control-Allow-Origin: *
// Or worse — reflecting any origin:
app.use(cors({
  origin: (origin, callback) => callback(null, true), // Reflects any origin
  credentials: true, // Combined with credential support = full bypass
}));
```

**Correct (explicit allowlist of trusted origins):**

```typescript
import cors from 'cors';

const ALLOWED_ORIGINS = [
  'https://app.example.com',
  'https://admin.example.com',
];

if (process.env.NODE_ENV === 'development') {
  ALLOWED_ORIGINS.push('http://localhost:3000');
}

app.use(cors({
  origin: (origin, callback) => {
    if (!origin || ALLOWED_ORIGINS.includes(origin)) {
      callback(null, origin);
    } else {
      callback(new Error('CORS policy violation'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400,
}));
```

**Azure/Cloud:**

Configure CORS in Azure App Service under Settings → CORS with exact origins —
never use `*` with authentication enabled. For Azure Functions, set allowed
origins in `host.json` or the Function App's CORS settings. Azure API Management
supports CORS policies with fine-grained origin control per operation.

**References:**
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/
- CWE-942: https://cwe.mitre.org/data/definitions/942.html
