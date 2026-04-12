## Configure sessions with secure, httpOnly, sameSite cookies

Session cookies must set: `secure` (HTTPS only), `httpOnly` (no JS access),
and `sameSite` (prevents CSRF). CWE-614.

**Incorrect (default session config):**

```typescript
app.use(session({
  secret: 'keyboard cat',
  cookie: {},
  resave: true,
  saveUninitialized: true,
}));
```

**Correct (hardened session configuration):**

```typescript
import session from 'express-session';
import RedisStore from 'connect-redis';

app.set('trust proxy', 1);

app.use(session({
  secret: process.env.SESSION_SECRET!,
  name: '__Host-sid',
  cookie: {
    secure: true,
    httpOnly: true,
    sameSite: 'strict',
    maxAge: 30 * 60 * 1000,
    path: '/',
  },
  store: new RedisStore({ client: redisClient }),
  resave: false,
  saveUninitialized: false,
  rolling: true,
}));
```

**Azure/Cloud:**

Use Azure Cache for Redis as the session store. For Azure Functions (stateless),
use JWT tokens instead of server-side sessions.

**References:**
- https://owasp.org/Top10/2025/A07_2025-Authentication_Failures/
- CWE-614: https://cwe.mitre.org/data/definitions/614.html
