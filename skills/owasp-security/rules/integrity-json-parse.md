## Use JSON.parse() — never eval() for deserialization

`eval()` and `new Function()` execute arbitrary JavaScript. `JSON.parse()` only
produces data structures. CWE-502 (Deserialization of Untrusted Data).

**Incorrect (eval-based deserialization):**

```typescript
function parseData(raw: string) {
  return eval(`(${raw})`);
}
```

**Correct (JSON.parse for data, validated schemas for structure):**

```typescript
import { z } from 'zod';

function parseData(raw: string): unknown {
  try {
    return JSON.parse(raw);
  } catch {
    throw new Error('Invalid JSON');
  }
}

const messageSchema = z.object({
  type: z.enum(['created', 'updated', 'deleted']),
  payload: z.record(z.unknown()),
  timestamp: z.string().datetime(),
});
const message = messageSchema.parse(JSON.parse(rawMessage));
```

**Azure/Cloud:**

Azure Service Bus and Event Grid messages should always be parsed with
`JSON.parse()`. Never use `eval()` in Azure Function code.

**References:**
- https://owasp.org/Top10/2025/A08_2025-Software_and_Data_Integrity_Failures/
- CWE-502: https://cwe.mitre.org/data/definitions/502.html
