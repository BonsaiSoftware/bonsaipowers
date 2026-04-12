# Deployment & Performance

## Production Dockerfile (Multi-Stage)

```dockerfile
# Stage 1: Install dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production && cp -R node_modules /prod_modules
RUN npm ci

# Stage 2: Build
FROM node:20-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Stage 3: Production image
FROM node:20-alpine AS production
WORKDIR /app

# Security: Run as non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S nestjs -u 1001
USER nestjs

COPY --from=deps --chown=nestjs:nodejs /prod_modules ./node_modules
COPY --from=build --chown=nestjs:nodejs /app/dist ./dist
COPY --chown=nestjs:nodejs package.json ./

# CRITICAL: Use node directly, NOT npm start
# npm doesn't forward SIGTERM → prevents graceful shutdown
CMD ["node", "dist/main.js"]

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD wget -qO- http://localhost:3000/health/liveness || exit 1
```

### .dockerignore

```
node_modules
dist
.git
.env
*.md
test
coverage
```

## Graceful Shutdown

```typescript
// main.ts
app.enableShutdownHooks();

// In any service that holds connections
@Injectable()
export class DatabaseService implements OnApplicationShutdown, BeforeApplicationShutdown {
  // Called first — stop accepting new work
  async beforeApplicationShutdown(signal?: string) {
    this.logger.log(`Shutdown signal received: ${signal}`);
    // Stop processing new jobs, drain queues
  }

  // Called second — clean up connections
  async onApplicationShutdown(signal?: string) {
    await this.connection.close();
    this.logger.log('Database connection closed');
  }
}
```

## Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      terminationGracePeriodSeconds: 30 # Match your shutdown timeout
      containers:
        - name: api
          image: myapp:latest
          ports:
            - containerPort: 3000
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          readinessProbe:
            httpGet:
              path: /health/readiness
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health/liveness
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 20
```

## Performance Optimization

### Fastify adapter (~2x throughput over Express)

```typescript
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';

const app = await NestFactory.create<NestFastifyApplication>(
  AppModule,
  new FastifyAdapter({ logger: false }), // Use Pino via nestjs-pino instead
);

// Listen on 0.0.0.0 for Docker
await app.listen(3000, '0.0.0.0');
```

**Caveat**: Some Express-specific middleware (e.g., `multer`, `passport` Express strategies)
needs Fastify equivalents. Check compatibility before switching.

### Lazy-loading modules

```typescript
@Injectable()
export class ReportService {
  constructor(private readonly lazyLoader: LazyModuleLoader) {}

  async generateReport() {
    // ReportModule is only loaded when this method is called
    const moduleRef = await this.lazyLoader.load(() => ReportModule);
    const reportGenerator = moduleRef.get(ReportGeneratorService);
    return reportGenerator.generate();
  }
}
```

### Compression

```typescript
import compression from 'compression';
app.use(compression()); // Express

// Or for Fastify:
import { fastifyCompress } from '@fastify/compress';
await app.register(fastifyCompress);
```

### Connection pooling

Always configure pool size based on expected concurrency:

```typescript
// TypeORM
extra: { max: 20, min: 5 }

// Prisma — set in connection string
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=20&pool_timeout=10"
```

### Clustering

```typescript
// cluster.ts — for multi-core utilization
import * as cluster from 'node:cluster';
import { cpus } from 'node:os';

if (cluster.isPrimary) {
  const numWorkers = cpus().length;
  for (let i = 0; i < numWorkers; i++) {
    cluster.fork();
  }
  cluster.on('exit', (worker) => {
    console.log(`Worker ${worker.process.pid} died, restarting...`);
    cluster.fork();
  });
} else {
  import('./main'); // Each worker runs the NestJS app
}
```

In Docker, prefer Node.js cluster module directly over PM2 — PM2 adds unnecessary overhead
in containerized environments where the orchestrator handles process management.

## Monorepo with Nx

For large projects with multiple apps sharing code:

```
apps/
├── api/           # Main HTTP API
├── worker/        # Background job processor
└── admin-api/     # Admin dashboard API
packages/
├── shared-models/ # DTOs, interfaces shared across apps
├── database/      # Shared database module
└── utils/         # Common utilities
```

```bash
# Only build/test affected projects
npx nx affected:build
npx nx affected:test

# Enforce module boundaries in nx.json
# Tag apps and libs, then add lint rules preventing unauthorized imports
```

## Production Checklist

- [ ] `ValidationPipe` with `whitelist: true` and `forbidNonWhitelisted: true`
- [ ] Environment validation at startup (Joi or class-validator)
- [ ] Global `AllExceptionsFilter` with sanitized error responses
- [ ] Helmet security headers enabled
- [ ] Rate limiting with `@nestjs/throttler`
- [ ] CORS configured with explicit origins
- [ ] `synchronize: false` for TypeORM / `prisma migrate deploy` for Prisma
- [ ] Connection pooling configured
- [ ] Structured JSON logging (Pino)
- [ ] Health check endpoints (liveness + readiness)
- [ ] `app.enableShutdownHooks()` with cleanup lifecycle hooks
- [ ] Multi-stage Docker build running as non-root
- [ ] `CMD ["node", "dist/main.js"]` (not `npm start`)
- [ ] Swagger docs behind auth or disabled in production
- [ ] Secrets in environment variables, never hardcoded
