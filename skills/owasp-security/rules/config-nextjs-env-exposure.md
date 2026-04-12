## Never prefix secrets with NEXT_PUBLIC_ — client bundle exposure

In Next.js, any environment variable prefixed with `NEXT_PUBLIC_` is inlined
into the client-side JavaScript bundle at build time. This is visible to anyone
who opens browser DevTools. Developers frequently leak API keys, internal
service URLs, and database credentials this way. CWE-200.

**Incorrect (secret exposed in client bundle):**

```typescript
// .env
NEXT_PUBLIC_STRIPE_SECRET_KEY=sk_live_abc123
NEXT_PUBLIC_DATABASE_URL=postgres://admin:password@internal-db:5432/prod
NEXT_PUBLIC_API_SECRET=my-internal-api-key

// app/page.tsx — these values are embedded in the JavaScript sent to browsers
const stripe = new Stripe(process.env.NEXT_PUBLIC_STRIPE_SECRET_KEY!);
```

**Correct (separate public and server-only env vars):**

```typescript
// .env
# Public (safe for client) — only non-sensitive values
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_xyz789
NEXT_PUBLIC_APP_URL=https://myapp.com

# Server-only (never reaches the browser) — no NEXT_PUBLIC_ prefix
STRIPE_SECRET_KEY=sk_live_abc123
DATABASE_URL=postgres://admin:password@internal-db:5432/prod
API_SECRET=my-internal-api-key

// app/api/checkout/route.ts — server-only code
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

// lib/env.ts — validate at startup, fail fast on missing vars
import { z } from 'zod';

const serverEnvSchema = z.object({
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  DATABASE_URL: z.string().url(),
  API_SECRET: z.string().min(16),
});

const clientEnvSchema = z.object({
  NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: z.string().startsWith('pk_'),
  NEXT_PUBLIC_APP_URL: z.string().url(),
});

// Validate server env (only runs on server)
export const serverEnv = serverEnvSchema.parse(process.env);

// Validate client env (safe to expose)
export const clientEnv = clientEnvSchema.parse({
  NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY,
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
});
```

**Rule of thumb:** Only `NEXT_PUBLIC_` values you would print on a billboard.
Publishable keys, app URLs, and feature flags are fine. Anything else stays
server-only.

**Azure/Cloud:**

Use Azure Key Vault references in App Service for server-only secrets. Set
`NEXT_PUBLIC_` vars in your build pipeline environment — they're baked in at
`next build` time, not at runtime. Audit your `.env*` files and Vercel/Azure
environment settings for accidental `NEXT_PUBLIC_` prefixes on secrets.

**References:**
- https://owasp.org/Top10/2025/A02_2025-Security_Misconfiguration/
- CWE-200: https://cwe.mitre.org/data/definitions/200.html
- https://nextjs.org/docs/app/building-your-application/configuring/environment-variables
