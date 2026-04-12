## Set security headers in Next.js via middleware or next.config.js

Next.js does not use Express, so `helmet` is not available. Security headers
must be set via `next.config.js` `headers` for static responses, or via
middleware for dynamic nonce-based CSP. Without these, responses have no
CSP, HSTS, X-Frame-Options, or other protective headers. CWE-693.

**Incorrect (no security headers in Next.js app):**

```typescript
// next.config.js — no headers configured
const nextConfig = {};
export default nextConfig;

// No middleware.ts — no CSP nonce injection
```

**Correct (security headers via next.config.js + nonce CSP in middleware):**

```typescript
// next.config.js — static security headers
const securityHeaders = [
  { key: 'X-DNS-Prefetch-Control', value: 'on' },
  { key: 'Strict-Transport-Security', value: 'max-age=31536000; includeSubDomains; preload' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
];

const nextConfig = {
  headers: async () => [{ source: '/(.*)', headers: securityHeaders }],
  poweredByHeader: false, // Remove X-Powered-By: Next.js
};
export default nextConfig;
```

```typescript
// middleware.ts — nonce-based CSP for dynamic pages
import { NextRequest, NextResponse } from 'next/server';

export function middleware(request: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString('base64');

  const csp = [
    `default-src 'self'`,
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    `style-src 'self' 'nonce-${nonce}'`,
    `img-src 'self' data: https:`,
    `connect-src 'self' https://api.example.com`,
    `font-src 'self'`,
    `object-src 'none'`,
    `frame-ancestors 'none'`,
    `base-uri 'self'`,
    `form-action 'self'`,
    `upgrade-insecure-requests`,
  ].join('; ');

  const response = NextResponse.next({
    request: { headers: new Headers(request.headers) },
  });

  response.headers.set('Content-Security-Policy', csp);
  response.headers.set('x-nonce', nonce);
  return response;
}

export const config = {
  matcher: [
    // Skip static files and images
    { source: '/((?!_next/static|_next/image|favicon.ico).*)', missing: [{ type: 'header', key: 'next-router-prefetch' }] },
  ],
};
```

```typescript
// app/layout.tsx — pass nonce to scripts
import { headers } from 'next/headers';

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const headersList = await headers();
  const nonce = headersList.get('x-nonce') ?? '';

  return (
    <html lang="en">
      <body>
        {children}
        <script nonce={nonce} src="/analytics.js" />
      </body>
    </html>
  );
}
```

**Azure/Cloud:**

Azure Front Door and Application Gateway can add security headers at the edge
via Rules Engine, complementing application-level headers. On Vercel, set
headers in `vercel.json` or `next.config.js`. Always test CSP with
`Content-Security-Policy-Report-Only` first to avoid breaking functionality.

**References:**
- https://owasp.org/Top10/2025/A02_2025-Security_Misconfiguration/
- CWE-693: https://cwe.mitre.org/data/definitions/693.html
- https://nextjs.org/docs/app/guides/content-security-policy
