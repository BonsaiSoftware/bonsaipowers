---
name: nestjs-best-practices
description: Comprehensive NestJS best practices for building production-grade backend applications. Use when Claude needs to write, review, scaffold, or refactor NestJS code. Triggers on any mention of "NestJS", "Nest.js", "@nestjs/", NestJS decorators (@Controller, @Injectable, @Module, @Guard, @Interceptor), NestJS CLI commands (nest new, nest generate), or requests involving NestJS modules, providers, controllers, services, DTOs, guards, interceptors, pipes, middleware, exception filters, ConfigModule, TypeORM/Prisma/MikroORM with NestJS, Passport/JWT auth in NestJS, @nestjs/swagger, @nestjs/cqrs, @nestjs/microservices, @nestjs/websockets, @nestjs/graphql, @nestjs/bullmq, @nestjs/terminus, @nestjs/throttler, or NestJS testing with Jest. Also triggers for NestJS project structure decisions, NestJS Docker/deployment, and NestJS performance optimization.
---

# NestJS Best Practices

Production-grade patterns for NestJS applications (2024–2025). Rules are organized by domain
and rated by impact: **CRITICAL** (causes bugs/vulnerabilities if ignored), **HIGH** (significant
quality impact), **MEDIUM** (recommended convention).

## Rule Categories by Priority

| Category | CRITICAL | HIGH | MEDIUM | Reference |
|---|---|---|---|---|
| Architecture & Modules | 2 | 3 | 2 | [architecture.md](references/architecture.md) |
| Providers & DI | 2 | 2 | 2 | [providers-and-di.md](references/providers-and-di.md) |
| Validation & DTOs | 3 | 2 | 1 | [validation-and-dtos.md](references/validation-and-dtos.md) |
| Error Handling | 2 | 2 | 1 | [error-handling.md](references/error-handling.md) |
| Auth & Security | 4 | 3 | 1 | [auth-and-security.md](references/auth-and-security.md) |
| Database | 2 | 3 | 2 | [database.md](references/database.md) |
| Config & Logging | 2 | 2 | 2 | [config-and-logging.md](references/config-and-logging.md) |
| Testing | 1 | 3 | 2 | [testing.md](references/testing.md) |
| Advanced Patterns | 1 | 4 | 3 | [advanced-patterns.md](references/advanced-patterns.md) |
| Deployment & Perf | 2 | 3 | 2 | [deployment.md](references/deployment.md) |

## Quick Reference — CRITICAL Rules

These rules must always be followed. Violating them causes security vulnerabilities, data loss,
or production failures.

### Architecture

1. **Feature-based module organization** — Group by business domain, not by layer. Each module
   owns its controllers, services, DTOs, entities. Never put all controllers in `/controllers`.
2. **No circular dependencies** — Redesign with a shared service or events instead of
   `forwardRef()`. If unavoidable, use `forwardRef()` on both sides.

### Validation

3. **Global ValidationPipe with whitelist** — Always set `whitelist: true` and
   `forbidNonWhitelisted: true`. Without this, clients can inject arbitrary properties.
4. **DTOs must be classes, not interfaces** — Decorators only work on classes. Interfaces are
   erased at runtime and provide zero validation.
5. **Nested validation requires @Type** — `@ValidateNested()` alone does nothing without
   `@Type(() => NestedDto)` from class-transformer.

### Security

6. **Never use `origin: '*'` for CORS in production** — Specify allowed origins explicitly.
7. **Always hash passwords with bcrypt/argon2** — Never store plaintext passwords.
8. **Short-lived access tokens (≤15min)** — Use refresh token rotation for session persistence.
9. **Rate-limit authentication endpoints** — Use stricter `@Throttle()` on login/register.

### Database

10. **Disable `synchronize: true` in production** — Use migrations. Synchronize can drop columns
    and lose data.
11. **Always release QueryRunner in finally block** — Unreleased connections cause pool exhaustion.

### Config

12. **Validate env vars at startup** — Use Joi or class-validator schema. Fail fast, not at
    first request.
13. **Never access `process.env` directly** — Use ConfigService or typed namespace injection.

### Deployment

14. **Use `CMD ["node", "dist/main.js"]` not `npm start`** — npm doesn't forward SIGTERM,
    preventing graceful shutdown.
15. **Enable shutdown hooks** — Call `app.enableShutdownHooks()` and implement
    `OnApplicationShutdown` for connection cleanup.

## Quick Reference — HIGH Rules

### Architecture

16. Keep controllers thin — HTTP concerns only, delegate logic to services.
17. Use barrel exports (`index.ts`) per module for clean imports.
18. Limit `@Global()` to truly universal services (config, logging).

### Providers & DI

19. Default to singleton scope — REQUEST scope has ~15% overhead and propagates.
20. Register guards/pipes/filters via module providers (`APP_GUARD`, `APP_PIPE`, `APP_FILTER`)
    not `app.useGlobal*()` — module registration supports dependency injection.

### Error Handling

21. Use a single global `AllExceptionsFilter` for consistent error shape.
22. Prefer NestJS built-in exceptions (`NotFoundException`, `ConflictException`) over raw
    `HttpException`.

### Auth

23. Separate access and refresh token secrets.
24. Store refresh tokens hashed (argon2/bcrypt) in database.
25. Use HTTP-only cookies for refresh tokens to mitigate XSS.

### Database

26. Use Data Mapper pattern over Active Record for testability (TypeORM).
27. Configure connection pooling (`extra: { max: 20, min: 5 }`).
28. Use `prisma migrate deploy` in production, never `prisma db push`.

### Testing

29. Follow Arrange-Act-Assert structure for all tests.
30. Co-locate unit tests (`*.spec.ts`) with source files; E2E in `/test`.
31. Use `Test.createTestingModule` with mocked providers — don't import real modules.

### Config & Logging

32. Use Pino (`nestjs-pino`) for production logging — fastest Node.js logger.
33. Implement separate liveness and readiness health endpoints with `@nestjs/terminus`.

### Performance

34. Use Fastify adapter for throughput-critical services (~2x over Express).
35. Lazy-load infrequently used modules with `LazyModuleLoader`.
36. Use `cache: true` on ConfigModule — `process.env` access is slow.

## When to Read Reference Files

**IMPORTANT: Do NOT read the compiled guide. Read only the 1-2 reference files relevant to the current task.**

1. Identify the domain from the mapping below
2. Read only the matching file(s) from `references/`
3. Typically 1-2 reference files are relevant per task

| Task | Read |
|---|---|
| Creating/scaffolding project or module | `references/architecture.md` |
| Writing services, providers, DI issues | `references/providers-and-di.md` |
| Creating DTOs, validation, pipes | `references/validation-and-dtos.md` |
| Error handling or exception filters | `references/error-handling.md` |
| Auth, authorization, security | `references/auth-and-security.md` |
| Database, ORM, queries | `references/database.md` |
| Environment config, logging, health checks | `references/config-and-logging.md` |
| Writing or improving tests | `references/testing.md` |
| CQRS, microservices, WebSockets, GraphQL, queues, caching | `references/advanced-patterns.md` |
| Dockerizing, deploying, performance | `references/deployment.md` |

## Essential Code Patterns

### Correct main.ts bootstrap

```typescript
import { NestFactory } from '@nestjs/core';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    bufferLogs: true,
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
  app.enableCors({ origin: process.env.ALLOWED_ORIGINS?.split(',') });
  app.enableShutdownHooks();

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
```

### Correct module structure

```typescript
// users/users.module.ts
@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService], // only export what other modules need
})
export class UsersModule {}
```

### Correct controller pattern (thin)

```typescript
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(@Body() dto: CreateUserDto) {
    return this.usersService.create(dto);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.findOneOrFail(id);
  }
}
```

### Naming conventions

| Element | Convention | Example |
|---|---|---|
| Files | `kebab-case.<type>.ts` | `create-user.dto.ts` |
| Classes | `PascalCase` + type suffix | `CreateUserDto`, `AuthGuard` |
| Modules | `<Feature>Module` | `UsersModule` |
| Services | `<Feature>Service` | `UsersService` |
| Controllers | `<Feature>Controller` | `UsersController` |
| Entities | singular `PascalCase` | `User`, `OrderItem` |
| Test files | `*.spec.ts` (unit), `*.e2e-spec.ts` (E2E) | `users.service.spec.ts` |

## NestJS Request Lifecycle

```
Request → Middleware → Guards → Interceptors (pre) → Pipes → Handler → Interceptors (post) → Filters (on error)
```

Use this to decide where logic belongs:
- **Middleware**: Logging, CORS, request ID — no access to handler context.
- **Guards**: Auth, RBAC — have `ExecutionContext`, block before interceptors.
- **Interceptors**: Response transform, timing, caching — wrap handler with RxJS.
- **Pipes**: Per-parameter validation and transformation.
- **Filters**: Error formatting — catch exceptions from any layer above.