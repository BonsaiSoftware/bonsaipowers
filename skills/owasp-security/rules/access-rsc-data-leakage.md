## Prevent sensitive data leakage across the RSC/client boundary

React Server Components serialize all props passed to client components into
the HTML response and RSC payload. If a server component passes a full database
object (with tokens, hashed passwords, internal flags) to a `'use client'`
component, those fields are visible in the browser. React's `taintObjectReference`
and `taintUniqueValue` APIs provide defense-in-depth by throwing if tainted
values cross the boundary. CWE-200.

**Incorrect (full user object crosses server/client boundary):**

```typescript
// app/page.tsx (Server Component)
export default async function Page() {
  const user = await db.user.findUnique({ where: { id: session.userId } });
  // user contains: { id, name, email, passwordHash, role, apiKey, internalNotes }

  return <ProfileCard user={user} />;
  // All fields serialized into HTML — passwordHash, apiKey visible in page source
}

// components/ProfileCard.tsx
'use client'
export function ProfileCard({ user }: { user: User }) {
  return <div>{user.name}</div>; // Only uses name, but ALL fields were sent
}
```

**Correct (select only needed fields + taint sensitive objects):**

```typescript
// lib/data.ts — taint sensitive objects at the data layer
import { experimental_taintObjectReference as taintObjectReference } from 'react';

export async function getUser(id: string) {
  const user = await db.user.findUnique({ where: { id } });
  if (user) {
    taintObjectReference(
      'Do not pass the full user object to client components. Select specific fields.',
      user
    );
  }
  return user;
}

// lib/auth.ts — taint sensitive values
import { experimental_taintUniqueValue as taintUniqueValue } from 'react';

export async function getSession() {
  const session = await getSessionFromCookie();
  if (session?.token) {
    taintUniqueValue(
      'Do not pass session tokens to client components.',
      session,
      session.token
    );
  }
  return session;
}

// app/page.tsx — pass only what the client needs
export default async function Page() {
  const user = await getUser(session.userId);

  // Trying to pass `user` directly would now throw at build/render time
  // return <ProfileCard user={user} />; // ERROR: tainted object

  // Correct: select specific safe fields
  return <ProfileCard name={user.name} avatarUrl={user.avatarUrl} />;
}

// components/ProfileCard.tsx
'use client'
export function ProfileCard({ name, avatarUrl }: { name: string; avatarUrl: string }) {
  return (
    <div>
      <img src={avatarUrl} alt={name} />
      <span>{name}</span>
    </div>
  );
}
```

**Even without taint APIs** — always select specific fields:

```typescript
// Data Transfer Object pattern
function toPublicUser(user: DbUser): PublicUser {
  return { name: user.name, avatarUrl: user.avatarUrl, bio: user.bio };
}

return <ProfileCard user={toPublicUser(user)} />;
```

**Azure/Cloud:**

The RSC payload is part of the HTTP response. WAF and CDN caches may store
and redistribute it. Fields like API keys or internal IDs in RSC payloads
can be harvested at scale. Audit server-to-client data flow in code reviews.

**References:**
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/
- CWE-200: https://cwe.mitre.org/data/definitions/200.html
- https://react.dev/reference/react/experimental_taintObjectReference
