# Architecture & Modules

## Project Structure

Use feature-based (domain-based) organization. Each module encapsulates a complete business domain.

```
src/
├── common/                    # Shared across all modules
│   ├── decorators/            # Custom decorators (@CurrentUser, @Public, @Roles)
│   ├── filters/               # Global exception filters
│   ├── guards/                # Auth/role guards
│   ├── interceptors/          # Logging, transform, timeout interceptors
│   ├── pipes/                 # Custom validation pipes
│   └── interfaces/            # Shared interfaces/types
├── config/                    # Typed configuration namespaces
│   ├── app.config.ts
│   ├── database.config.ts
│   └── auth.config.ts
├── modules/
│   ├── users/
│   │   ├── dto/
│   │   │   ├── create-user.dto.ts
│   │   │   └── update-user.dto.ts
│   │   ├── entities/
│   │   │   └── user.entity.ts
│   │   ├── users.controller.ts
│   │   ├── users.service.ts
│   │   ├── users.repository.ts   # Optional: custom repository
│   │   ├── users.module.ts
│   │   ├── users.service.spec.ts
│   │   └── index.ts              # Barrel export
│   ├── auth/
│   ├── orders/
│   └── payments/
├── shared/                    # Shared NestJS modules (re-exported)
│   ├── database/
│   │   └── database.module.ts
│   └── mail/
│       └── mail.module.ts
├── app.module.ts
└── main.ts
```

### Anti-patterns to avoid

```
# BAD: Layer-based organization — obscures business intent
src/
├── controllers/
│   ├── users.controller.ts
│   ├── orders.controller.ts
├── services/
│   ├── users.service.ts
│   ├── orders.service.ts
├── entities/
├── dtos/
```

```
# BAD: One module per entity — too granular
src/modules/user/
src/modules/user-profile/
src/modules/user-settings/
# GOOD: Group related entities in one module
src/modules/users/   # contains User, UserProfile, UserSettings
```

## Module Design Rules

### Encapsulation

Every module should work as an independent unit. Communicate between modules only through
exported services — never import entities or repositories from another module directly.

```typescript
// GOOD: Export service facade
@Module({
  imports: [TypeOrmModule.forFeature([User, UserProfile])],
  providers: [UsersService, UserProfileService],
  exports: [UsersService], // Only expose what's needed
})
export class UsersModule {}

// BAD: Exporting TypeOrmModule.forFeature lets others bypass your service
@Module({
  exports: [TypeOrmModule.forFeature([User])], // Leaks internal implementation
})
```

### @Global() usage

Use `@Global()` only for services needed everywhere with zero configuration:

```typescript
// GOOD candidates for @Global()
@Global()
@Module({ providers: [PrismaService], exports: [PrismaService] })
export class PrismaModule {}

// BAD: Making feature modules global
@Global()
@Module({...})
export class UsersModule {} // Other modules should explicitly import this
```

### Dynamic modules

Use `forRoot()`/`forRootAsync()` for singleton configuration and `forFeature()` for
per-module registration:

```typescript
// Singleton config in AppModule
DatabaseModule.forRootAsync({
  imports: [ConfigModule],
  inject: [ConfigService],
  useFactory: (config: ConfigService) => ({
    host: config.get('DB_HOST'),
    port: config.get('DB_PORT'),
  }),
})

// Per-feature registration
TypeOrmModule.forFeature([User, UserProfile])
```

## API Versioning

```typescript
// main.ts — enable URI versioning
app.enableVersioning({
  type: VersioningType.URI,
  defaultVersion: VERSION_NEUTRAL, // Unversioned routes still work
});

// Controller-level version
@Controller({ path: 'users', version: '2' })
export class UsersV2Controller {}

// Method-level version
@Get()
@Version('2')
findAllV2() {}
```

## Barrel Exports

Every module directory should have an `index.ts`:

```typescript
// modules/users/index.ts
export * from './users.module';
export * from './users.service';
export * from './dto/create-user.dto';
export * from './dto/update-user.dto';
// Do NOT export entities — they're internal implementation
```
