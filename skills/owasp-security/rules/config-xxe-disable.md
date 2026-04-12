## Disable XML external entity processing

XXE allows attackers to read server files, perform SSRF, or cause DoS via
entity expansion ("billion laughs"). Disable DTD and external entities in
all XML parsers. CWE-611.

**Incorrect (default xml2js config allows entity expansion):**

```typescript
import { parseString } from 'xml2js';
parseString(userInput, (err, result) => {
  // <!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
  // <data>&xxe;</data> → leaks file contents
});
```

**Correct (disable entities and DTD processing):**

```typescript
import { XMLParser } from 'fast-xml-parser';

const parser = new XMLParser({
  allowBooleanAttributes: true,
  processEntities: false,     // Disable entity expansion
  htmlEntities: false,
});
const result = parser.parse(userInput);

// Prefer JSON APIs over XML when possible
// If XML is required, validate against a strict XSD schema
```

**Azure/Cloud:**

Azure API Management can validate XML payloads and strip DTD declarations
via policy. Azure WAF has XXE detection rules.

**References:**
- https://owasp.org/Top10/2025/A02_2025-Security_Misconfiguration/
- CWE-611: https://cwe.mitre.org/data/definitions/611.html
