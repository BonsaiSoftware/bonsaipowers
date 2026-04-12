## Authenticate revalidation calls to prevent cache poisoning

`revalidatePath()` and `revalidateTag()` purge Next.js cached pages and data.
If Server Actions or Route Handlers that call these functions lack
authentication, attackers can trigger mass cache invalidation (DoS) or force
revalidation while injecting poisoned upstream data. On-Demand Revalidation
endpoints using secret tokens must validate the token before purging.
CWE-862.

**Incorrect (unauthenticated revalidation):**

```typescript
// app/actions.ts — anyone can trigger cache purge
'use server'
import { revalidatePath } from 'next/cache';

export async function refreshHomepage() {
  revalidatePath('/'); // No auth check — bot can spam this
}

// app/api/revalidate/route.ts — webhook with no token validation
export async function POST() {
  revalidatePath('/blog');
  return Response.json({ revalidated: true });
}
```

**Correct (authenticated revalidation at every entry point):**

```typescript
// app/actions.ts — Server Action with auth + rate awareness
'use server'
import { revalidatePath } from 'next/cache';
import { verifySession } from '@/lib/auth';

export async function publishPost(postId: string) {
  const session = await verifySession();
  if (!session) throw new Error('Unauthorized');

  // Verify the user owns this post
  const post = await db.post.findUnique({ where: { id: postId } });
  if (!post || post.authorId !== session.userId) {
    throw new Error('Forbidden');
  }

  await db.post.update({
    where: { id: postId },
    data: { status: 'published' },
  });

  // Revalidate only after authenticated, authorized mutation
  revalidatePath(`/blog/${post.slug}`);
  revalidatePath('/blog');
}

// app/api/revalidate/route.ts — webhook with secret token validation
import { NextRequest } from 'next/server';
import { revalidateTag } from 'next/cache';

export async function POST(request: NextRequest) {
  const token = request.headers.get('x-revalidation-token');

  // Constant-time comparison to prevent timing attacks
  const expected = process.env.REVALIDATION_SECRET;
  if (
    !token ||
    !expected ||
    token.length !== expected.length ||
    !crypto.timingSafeEqual(
      Buffer.from(token),
      Buffer.from(expected)
    )
  ) {
    return Response.json({ error: 'Invalid token' }, { status: 401 });
  }

  const body = await request.json();
  const tag = body.tag;
  if (typeof tag !== 'string' || tag.length > 100) {
    return Response.json({ error: 'Invalid tag' }, { status: 400 });
  }

  revalidateTag(tag);
  return Response.json({ revalidated: true, tag });
}
```

**Key principle:** Treat `revalidatePath` and `revalidateTag` as privileged
operations. They should only execute after the calling user is authenticated,
authorized, and has performed a legitimate mutation.

**Azure/Cloud:**

Store the revalidation secret in Azure Key Vault. For CMS webhooks (Sanity,
Contentful), configure webhook secrets and validate HMAC signatures. On
Vercel, On-Demand ISR uses a secret token — never expose it in client code.
Monitor revalidation frequency in logs to detect abuse.

**References:**
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/
- CWE-862: https://cwe.mitre.org/data/definitions/862.html
- https://nextjs.org/docs/app/building-your-application/data-fetching/incremental-static-regeneration
