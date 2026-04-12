## Use React auto-escaping — avoid dangerouslySetInnerHTML

React automatically escapes JSX expressions, preventing XSS. This protection is
bypassed by `dangerouslySetInnerHTML` and `href="javascript:..."`. CWE-79.

**Incorrect (bypassing React's escaping):**

```tsx
function Comment({ body }: { body: string }) {
  return <div dangerouslySetInnerHTML={{ __html: body }} />;
}

function Link({ url }: { url: string }) {
  return <a href={url}>Click here</a>;
}
```

**Correct (React auto-escaping and URL validation):**

```tsx
function Comment({ body }: { body: string }) {
  return <div>{body}</div>;
}

function SafeLink({ url }: { url: string }) {
  const safeUrl = url.startsWith('https://') || url.startsWith('http://')
    ? url : '#';
  return <a href={safeUrl}>{safeUrl}</a>;
}

import DOMPurify from 'dompurify';
function RichContent({ html }: { html: string }) {
  const clean = DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br'],
    ALLOWED_ATTR: ['href'],
  });
  return <div dangerouslySetInnerHTML={{ __html: clean }} />;
}
```

**Azure/Cloud:**

Set Content-Security-Policy headers via helmet. Azure Front Door WAF includes
XSS detection rules.

**References:**
- https://owasp.org/Top10/2025/A05_2025-Injection/
- CWE-79: https://cwe.mitre.org/data/definitions/79.html
