## Exclude sensitive data from statically generated pages

Static generation (ISR, `generateStaticParams`, static RSC) bakes HTML at build
time and serves it from CDN to every visitor. If server-side data fetching
includes sensitive fields (internal IDs, tokens, admin flags, PII), they are
embedded in the HTML source and the RSC payload — visible to anyone. CWE-200.

**Incorrect (sensitive data baked into static HTML):**

```typescript
// app/users/[id]/page.tsx — static generation with full user object
export async function generateStaticParams() {
  const users = await db.user.findMany();
  return users.map((u) => ({ id: u.id }));
}

export default async function UserPage({ params }: { params: { id: string } }) {
  const user = await db.user.findUnique({ where: { id: params.id } });

  // All fields serialized into static HTML — email, role, internalNotes
  // visible in page source to anyone
  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>        {/* PII in static HTML */}
      <p>{user.internalNotes}</p> {/* Internal data exposed */}
      <p>{user.role}</p>          {/* Auth info leaked */}
    </div>
  );
}
```

**Correct (select only public fields for static pages):**

```typescript
// app/users/[id]/page.tsx — only public data in static generation
export default async function UserPage({ params }: { params: { id: string } }) {
  // Fetch only public fields — never select *
  const user = await db.user.findUnique({
    where: { id: params.id },
    select: { name: true, bio: true, avatarUrl: true },
  });

  if (!user) return notFound();

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.bio}</p>
      <img src={user.avatarUrl} alt={user.name} />
    </div>
  );
}

// For pages that NEED sensitive data: use dynamic rendering
// app/dashboard/page.tsx
export const dynamic = 'force-dynamic'; // Never cache

export default async function Dashboard() {
  const session = await getSession();
  if (!session) redirect('/login');

  const user = await db.user.findUnique({
    where: { id: session.userId },
  });
  // Safe: dynamic, authenticated, per-request
  return <DashboardView user={user} />;
}
```

**Key rule:** If a page is statically generated or ISR-cached, treat its data
as public. Any field that shouldn't be visible to anonymous users must either
be excluded or the page must use `dynamic = 'force-dynamic'` with
authentication.

**Azure/Cloud:**

CDN-cached pages (Azure Front Door, Vercel Edge) amplify exposure — one
leaked field is served globally. Audit `generateStaticParams` and ISR pages
for data sensitivity. Use Azure Front Door access restrictions if static
pages should be limited to certain networks.

**References:**
- https://owasp.org/Top10/2025/A02_2025-Security_Misconfiguration/
- CWE-200: https://cwe.mitre.org/data/definitions/200.html
- https://nextjs.org/docs/app/building-your-application/rendering/server-components#static-rendering-default
