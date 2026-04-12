## Handle unhandledRejection and uncaughtException globally

Node.js terminates on unhandled promise rejections. Without global handlers,
crashes produce no useful logs. CWE-248 (Uncaught Exception).

**Incorrect (no global handlers):**

```typescript
async function backgroundTask() {
  const data = await fetchExternalApi();
  await processData(data);
}
backgroundTask();
```

**Correct (global handlers with logging and graceful shutdown):**

```typescript
process.on('unhandledRejection', (reason: unknown) => {
  logger.error({
    event: 'UNHANDLED_REJECTION',
    reason: reason instanceof Error ? reason.message : String(reason),
    stack: reason instanceof Error ? reason.stack : undefined,
  });
});

process.on('uncaughtException', (error: Error) => {
  logger.error({
    event: 'UNCAUGHT_EXCEPTION',
    error: error.message,
    stack: error.stack,
  });
  gracefulShutdown(1);
});

async function gracefulShutdown(exitCode: number) {
  logger.info({ event: 'GRACEFUL_SHUTDOWN', exitCode });
  try {
    server.close();
    await pool.end();
    await redisClient.quit();
  } catch (e) {
    logger.error({ event: 'SHUTDOWN_ERROR', error: e.message });
  }
  process.exit(exitCode);
}

process.on('SIGTERM', () => gracefulShutdown(0));
process.on('SIGINT', () => gracefulShutdown(0));
```

**Azure/Cloud:**

Azure App Service and Azure Functions automatically restart crashed processes.
Azure Container Apps and AKS use health probes — graceful shutdown prevents
killing in-flight requests.

**References:**
- https://owasp.org/Top10/2025/A10_2025-Mishandling_of_Exceptional_Conditions/
- CWE-248: https://cwe.mitre.org/data/definitions/248.html
