## Add Subresource Integrity hashes to all CDN script tags

A compromised CDN can serve modified scripts. SRI lets the browser verify that
fetched files match expected hashes. CWE-353 (Missing Support for Integrity Check).

**Incorrect (CDN script without integrity verification):**

```html
<script src="https://cdn.example.com/react.production.min.js"></script>
```

**Correct (SRI hash ensures integrity):**

```html
<script
  src="https://cdn.jsdelivr.net/npm/react@18.2.0/umd/react.production.min.js"
  integrity="sha384-o8TZjCnSoE0gnLLL1OGXnKPOLJXCAHKbC8g0UT3bDCyMkFj4EAP8IkfJjONbChX"
  crossorigin="anonymous">
</script>
```

**Azure/Cloud:**

Azure CDN and Azure Front Door serve content with integrity. For Azure Static
Web Apps, self-host dependencies or use SRI in the HTML.

**References:**
- https://owasp.org/Top10/2025/A08_2025-Software_and_Data_Integrity_Failures/
- https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity
