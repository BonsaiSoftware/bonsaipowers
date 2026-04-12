## Secure Next.js Route Handlers with explicit CORS, auth, and rate limiting

Next.js Route Handlers (`app/api/*/route.ts`) are bare endpoints with no
middleware chain — unlike Express, there is no `app.use(cors())` or
`app.use(helmet())`. Each Route Handler must explicitly implement
authentication, CORS, rate limiting, and input validation. Forgetting any of
these creates an unprotected public API endpoint. CWE-284.

**Incorrect (unprotected Route Handler):**

```typescript
// app/api/users/route.ts — no auth, no CORS, no rate limiting, no validation
export async function GET() {
  const users = await db.user.findMany();
  return Response.json(users); // Exposes all user data to anyone
}

export async function POST(request: Request) {
  const body = await request.json(); // No validation
  const user = await db.user.create({ data: body }); // Mass assignment
  return Response.json(user);
}
```

**Correct (Route Handler with layered security):**

```typescript
// lib/api-utils.ts — reusable security helpers for Route Handlers
import { NextRequest, NextResponse } from 'next/server';
import { verifySession } from '@/lib/auth';
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ALLOWED_ORIGINS = ['https://myapp.com', 'https://admin.myapp.com'];

export function corsHeaders(request: NextRequest) {
  const origin = request.headers.get('origin') ?? '';
  const headers: Record<string, string> = {
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };
  if (ALLOWED_ORIGINS.includes(origin)) {
    headers['Access-Control-Allow-Origin'] = origin;
    headers['Access-Control-Allow-Credentials'] = 'true';
  }
  return headers;
}

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(20, '60 s'),
});

export async function checkRateLimit(request: NextRequest) {
  const ip = request.headers.get('x-forwarded-for') ?? 'unknown';
  const { success } = await ratelimit.limit(ip);
  return success;
}
```

```typescript
// app/api/users/route.ts — secured Route Handler
import { NextRequest, NextResponse } from 'next/server';
import { verifySession } from '@/lib/auth';
import { corsHeaders, checkRateLimit } from '@/lib/api-utils';
import { z } from 'zod';

// Handle CORS preflight
export async function OPTIONS(request: NextRequest) {
  return new NextResponse(null, { status: 204, headers: corsHeaders(request) });
}

export async function GET(request: NextRequest) {
  // Rate limiting
  if (!(await checkRateLimit(request))) {
    return NextResponse.json(
      { error: 'Too many requests' },
      { status: 429, headers: corsHeaders(request) }
    );
  }

  // Authentication
  const session = await verifySession();
  if (!session) {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401, headers: corsHeaders(request) }
    );
  }

  // Authorization
  if (session.role !== 'admin') {
    return NextResponse.json(
      { error: 'Forbidden' },
      { status: 403, headers: corsHeaders(request) }
    );
  }

  const users = await db.user.findMany({
    select: { id: true, name: true, email: true }, // Explicit select
  });
  return NextResponse.json(users, { headers: corsHeaders(request) });
}

const createUserSchema = z.object({
  name: z.string().min(1).max(100).trim(),
  email: z.string().email().max(255),
});

export async function POST(request: NextRequest) {
  if (!(await checkRateLimit(request))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
  }

  const session = await verifySession();
  if (!session || session.role !== 'admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  // Validate input
  const body = createUserSchema.safeParse(await request.json());
  if (!body.success) {
    return NextResponse.json({ errors: body.error.errors }, { status: 400 });
  }

  const user = await db.user.create({
    data: { ...body.data, role: 'user' }, // Role set server-side
  });
  return NextResponse.json(user, { status: 201, headers: corsHeaders(request) });
}
```

**Azure/Cloud:**

Azure API Management can front Next.js Route Handlers with rate limiting,
JWT validation, and CORS policies at the gateway. For self-hosted Next.js
on App Service or AKS, implement these checks in the Route Handler code
as shown above. Vercel does not provide gateway-level rate limiting — it
must be application-level.

**References:**
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/
- CWE-284: https://cwe.mitre.org/data/definitions/284.html
- https://nextjs.org/docs/app/building-your-application/routing/route-handlers
