## Restrict next/image remotePatterns to prevent SSRF

Next.js image optimization (`next/image`) acts as a server-side proxy —
fetching, resizing, and caching remote images. Without restricting
`remotePatterns` in `next.config.js`, attackers can use `/_next/image?url=`
to proxy requests to internal services, cloud metadata endpoints
(169.254.169.254), or arbitrary hosts, turning your server into an SSRF
relay. CWE-918.

**Incorrect (unrestricted image optimization):**

```typescript
// next.config.js — allows ANY remote image
const nextConfig = {
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: '**' }, // Wildcard — any host
    ],
  },
};
export default nextConfig;

// Or worse: using the deprecated domains with a broad list
const nextConfig = {
  images: {
    domains: ['*'], // Open proxy
  },
};
```

```
# Attacker exploits the image proxy:
GET /_next/image?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/&w=1&q=1
GET /_next/image?url=http://internal-api.local:3001/admin/users&w=1&q=1
```

**Correct (strict remotePatterns allowlist):**

```typescript
// next.config.js — only allow specific trusted hosts
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images.example.com',
      },
      {
        protocol: 'https',
        hostname: '*.githubusercontent.com',
      },
      {
        protocol: 'https',
        hostname: 'cdn.example.com',
        pathname: '/uploads/**', // Restrict to specific paths too
      },
    ],
  },
};
export default nextConfig;
```

**If user-uploaded image URLs are dynamic**, validate them server-side before
storing:

```typescript
const ALLOWED_IMAGE_HOSTS = ['images.example.com', 'cdn.example.com'];

function validateImageUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return (
      parsed.protocol === 'https:' &&
      ALLOWED_IMAGE_HOSTS.includes(parsed.hostname)
    );
  } catch {
    return false;
  }
}
```

**Azure/Cloud:**

Azure App Service and Container Apps run the Next.js server — SSRF via image
proxy can reach Azure IMDS (metadata service), private VNet resources, and
internal APIs. Use Network Security Groups to restrict outbound traffic. If
hosting on Vercel, the image optimization runs on their infrastructure but
still proxies to whatever URL is requested.

**References:**
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/
- CWE-918: https://cwe.mitre.org/data/definitions/918.html
- https://nextjs.org/docs/app/api-reference/components/image#remotepatterns
