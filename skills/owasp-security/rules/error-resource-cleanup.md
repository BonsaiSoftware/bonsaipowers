## Use try/finally to release resources on all code paths

File handles, database connections, streams, and locks must be released in a
`finally` block. CWE-404 (Improper Resource Shutdown or Release).

**Incorrect (resource leaks on exception):**

```typescript
async function processFile(path: string) {
  const handle = await fs.open(path, 'r');
  const data = await handle.readFile('utf-8');
  const result = await transform(data);
  await handle.close();
  return result;
}
```

**Correct (try/finally guarantees cleanup):**

```typescript
async function processFile(path: string) {
  const handle = await fs.open(path, 'r');
  try {
    const data = await handle.readFile('utf-8');
    return await transform(data);
  } finally {
    await handle.close();
  }
}

async function queryWithConnection() {
  const client = await pool.connect();
  try {
    return await client.query('SELECT ...');
  } finally {
    client.release();
  }
}
```

**Azure/Cloud:**

Azure SDK clients should be created once and reused. For Azure Functions, use
function-level bindings rather than manually managing connections.

**References:**
- https://owasp.org/Top10/2025/A10_2025-Mishandling_of_Exceptional_Conditions/
- CWE-404: https://cwe.mitre.org/data/definitions/404.html
