## Verify auth in every server layer — not just middleware or layouts

In Next.js, middleware runs on the edge before the request reaches the page,
but layouts do NOT re-render on client-side navigation. An auth check in a
layout runs once on initial load but is skipped on subsequent `router.push()`
navigations. Relying solely on middleware or layouts creates gaps — Server
Components, Server Actions, and Route Handlers must each independently verify
authentication. CWE-863.

**Incorrect (auth only in middleware — Server Action is unprotected):**

```typescript
// middleware.ts — catches page requests but NOT direct Server Action calls
export function middleware(request: NextRequest) {
  const token = request.cookies.get('session');
  if (!token && !request.nextUrl.pathname.startsWith('/login')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}

// app/layout.tsx — auth check here does NOT re-run on client navigation
export default async function RootLayout({ children }) {
  const session = await getSession();
  if (!session) redirect('/login'); // Only runs on initial page load
  return <html><body>{children}</body></html>;
}

// app/actions.ts — directly callable, bypasses middleware check
'use server'
export async function deleteAccount(userId: string) {
  // No auth check — anyone who knows the action endpoint can call this
  await db.user.delete({ where: { id: userId } });
}
```

**Correct (auth verified at every layer):**

```typescript
// lib/auth.ts — shared auth verification
import { cookies } from 'next/headers';
import { cache } from 'react';

// cache() deduplicates within a single request — call freely in every layer
export const verifySession = cache(async () => {
  const cookieStore = await cookies();
  const token = cookieStore.get('session')?.value;
  if (!token) return null;

  const session = await validateSessionToken(token);
  return session; // { userId, role, expiresAt }
});

// middleware.ts — first line of defense (optimistic, edge-only)
export function middleware(request: NextRequest) {
  const token = request.cookies.get('session');
  if (!token && isProtectedRoute(request.nextUrl.pathname)) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  // Middleware does basic check; authoritative check is in the server layer
}

// app/dashboard/page.tsx — Server Component verifies auth independently
export default async function Dashboard() {
  const session = await verifySession();
  if (!session) redirect('/login');

  const data = await getDashboardData(session.userId);
  return <DashboardView data={data} />;
}

// app/actions.ts — Server Action verifies auth independently
'use server'
export async function deleteAccount(userId: string) {
  const session = await verifySession();
  if (!session) throw new Error('Unauthorized');
  if (session.userId !== userId && session.role !== 'admin') {
    throw new Error('Forbidden');
  }
  await db.user.delete({ where: { id: userId } });
}

// app/api/data/route.ts — Route Handler verifies auth independently
export async function GET() {
  const session = await verifySession();
  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const data = await getData(session.userId);
  return NextResponse.json(data);
}
```

**Why `cache()` matters:** `verifySession` may be called in the layout, page,
and multiple Server Components in the same request. `React.cache()` ensures
the session lookup runs only once per request, so the overhead of checking
auth everywhere is negligible.

**Azure/Cloud:**

Azure AD middleware checks at the App Service level (EasyAuth) only protect
page requests — Server Actions and Route Handlers need application-level
auth. Use Managed Identity for service-to-service auth, but always verify
end-user identity in each server-side entry point.

**References:**
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/
- CWE-863: https://cwe.mitre.org/data/definitions/863.html
- https://nextjs.org/docs/app/guides/authentication
