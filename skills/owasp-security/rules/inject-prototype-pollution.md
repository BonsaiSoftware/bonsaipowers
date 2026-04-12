## Guard against prototype pollution in object merges

Attackers send `__proto__` or `constructor.prototype` keys in JSON to
inject properties on `Object.prototype`, affecting all objects in the
process. Leads to auth bypass, RCE, or DoS. CWE-1321.

**Incorrect (recursive merge without key filtering):**

```typescript
function merge(target: any, source: any) {
  for (const key in source) {
    if (typeof source[key] === 'object') {
      target[key] = merge(target[key] || {}, source[key]);
    } else {
      target[key] = source[key];
    }
  }
  return target;
}
// POST {"__proto__": {"isAdmin": true}} → all objects gain isAdmin
merge({}, req.body);
```

**Correct (reject dangerous keys, use Object.create(null), or freeze prototype):**

```typescript
const DANGEROUS_KEYS = new Set(['__proto__', 'constructor', 'prototype']);

function safeMerge(target: Record<string, unknown>, source: Record<string, unknown>) {
  for (const key of Object.keys(source)) {
    if (DANGEROUS_KEYS.has(key)) continue;
    const val = source[key];
    if (val && typeof val === 'object' && !Array.isArray(val)) {
      target[key] = safeMerge(
        (target[key] as Record<string, unknown>) ?? Object.create(null),
        val as Record<string, unknown>,
      );
    } else {
      target[key] = val;
    }
  }
  return target;
}

// Best: validate with Zod — strips unknown keys automatically
const configSchema = z.object({ theme: z.string(), lang: z.string() });
const config = configSchema.parse(req.body);
```

**Azure/Cloud:**

Azure API Management JSON validation policies reject payloads containing
`__proto__` keys. Add WAF custom rules to block prototype pollution
payloads.

**References:**
- https://owasp.org/Top10/2025/A05_2025-Injection/
- CWE-1321: https://cwe.mitre.org/data/definitions/1321.html
