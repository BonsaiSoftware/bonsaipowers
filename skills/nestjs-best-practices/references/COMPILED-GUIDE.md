# NestJS Best Practices — Production-Grade Patterns

Production-grade patterns for NestJS applications.
60+ rules across 10 categories, prioritized by impact: **CRITICAL**, **HIGH**, **MEDIUM**.

Each rule shows the **anti-pattern** to avoid and the **correct pattern** to apply.

---

## Architecture & Modules (CRITICAL)

### arch-feature-modules — Group by business domain, not by layer

Feature-based organization encapsulates complete business domains. Layer-based
organization (all controllers in `/controllers`) obscures intent, creates tight
coupling, and makes modules non-portable.

**Anti-pattern:**

```
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

**Correct pattern:**

```
src/
├── common/                    # Shared across all modules
│   ├── decorators/            # @CurrentUser, @Public, @Roles
│   ├── filters/               # Global exception filters
│   ├── guards/                # Auth/role guards
│   ├── interceptors/          # Logging, transform, timeout
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
│   │   ├── users.repository.ts
│   │   ├── users.module.ts
│   │   ├── users.service.spec.ts
│   │   └── index.ts              # Barrel export
│   ├── auth/
│   ├── orders/
│   └── payments/
├── shared/                    # Shared NestJS modules (re-exported)
│   ├── database/
│   └── mail/
├── app.module.ts
└── main.ts
```

---

### arch-no-circular-deps — Redesign instead of using forwardRef()

Circular dependencies indicate a design flaw. Extract shared logic into a third
module or use events for cross-module communication. Only use `forwardRef()` on
**both** sides as a last resort.

**Anti-pattern:** Circular import between UsersModule and OrdersModule with single-sided `forwardRef()`.

**Correct pattern:**

```typescript
// Option 1 (PREFERRED): Extract shared logic
@Module({
  providers: [UserOrderLinkService],
  exports: [UserOrderLinkService],
})
export class SharedModule {}

// Option 2 (PREFERRED): Use events for cross-module communication
// In OrdersService:
this.eventEmitter.emit('order.created', { orderId, userId });
// In UsersModule: listen for event without importing OrdersModule

// Option 3 (last resort): forwardRef on BOTH sides
@Module({ imports: [forwardRef(() => OrdersModule)] })
export class UsersModule {}

@Module({ imports: [forwardRef(() => UsersModule)] })
export class OrdersModule {}
```

---

### arch-module-encapsulation — Export services, never entities or repositories

Communicate between modules only through exported services. Never import entities
or repositories from another module directly.

**Anti-pattern:**

```typescript
@Module({
  exports: [TypeOrmModule.forFeature([User])], // Leaks internal implementation
})
```

**Correct pattern:**

```typescript
@Module({
  imports: [TypeOrmModule.forFeature([User, UserProfile])],
  providers: [UsersService, UserProfileService],
  exports: [UsersService], // Only expose what's needed
})
export class UsersModule {}
```

---

### arch-limit-global — Use @Global() only for truly universal services

**Good candidates:** ConfigModule, PrismaService, LoggerModule.
**Bad candidates:** Feature modules like UsersModule — other modules should explicitly import.

```typescript
// GOOD
@Global()
@Module({ providers: [PrismaService], exports: [PrismaService] })
export class PrismaModule {}

// BAD
@Global()
@Module({...})
export class UsersModule {} // Other modules should explicitly import this
```

---

### arch-barrel-exports — Use index.ts per module for clean imports

```typescript
// modules/users/index.ts
export * from './users.module';
export * from './users.service';
export * from './dto/create-user.dto';
export * from './dto/update-user.dto';
// Do NOT export entities — they're internal implementation
```

---

### arch-dynamic-modules — Use forRoot/forRootAsync for singleton config

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

---

### arch-api-versioning — Use URI versioning for APIs

```typescript
// main.ts
app.enableVersioning({
  type: VersioningType.URI,
  defaultVersion: VERSION_NEUTRAL,
});

// Controller-level version
@Controller({ path: 'users', version: '2' })
export class UsersV2Controller {}
```

---

## Providers & Dependency Injection (CRITICAL)

### di-singleton-scope — Default to singleton; REQUEST scope has ~15% overhead

REQUEST scope propagates up the injection chain. Only use it when you genuinely
need per-request data (current user, tenant).

**Anti-pattern:** `@Injectable({ scope: Scope.REQUEST })` "just in case."

**Correct pattern:**

```typescript
// DEFAULT (Singleton) — One instance for entire app. Always prefer this.
@Injectable() // scope: Scope.DEFAULT is implicit
export class UsersService {}

// REQUEST — Only when genuinely needed
@Injectable({ scope: Scope.REQUEST })
export class TenantService {
  constructor(@Inject(REQUEST) private request: Request) {}
}

// TRANSIENT — New instance per injection point
@Injectable({ scope: Scope.TRANSIENT })
export class ContextLogger {
  constructor(@Inject(INQUIRER) private parentClass: object) {
    this.context = parentClass?.constructor?.name ?? 'Unknown';
  }
}
```

---

### di-module-registration — Register globals via APP_GUARD/APP_PIPE, not app.useGlobal*()

Module-based registration supports dependency injection. `app.useGlobal*()` does not.

**Anti-pattern:** `app.useGlobalGuards(new JwtAuthGuard())` — JwtAuthGuard can't inject ConfigService.

**Correct pattern:**

```typescript
@Module({
  providers: [
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_PIPE, useClass: ValidationPipe },
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
  ],
})
export class AppModule {}
```

---

### di-thin-controllers — Controllers handle HTTP concerns only

Controllers extract parameters, set status codes, and delegate to services.
Business logic, database access, and external calls belong in services.

**Anti-pattern:**

```typescript
@Controller('orders')
export class OrdersController {
  @Post()
  async create(@Body() dto: CreateOrderDto, @Req() req) {
    const user = await this.usersRepo.findOne(req.user.id);
    if (user.balance < dto.total) throw new BadRequestException('Insufficient balance');
    const order = this.ordersRepo.create({ ...dto, userId: user.id });
    await this.ordersRepo.save(order);
    await this.mailService.sendConfirmation(user.email, order);
    return order;
  }
}
```

**Correct pattern:**

```typescript
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(@Body() dto: CreateOrderDto, @CurrentUser() user: User) {
    return this.ordersService.create(dto, user.id);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.findOneOrFail(id);
  }
}
```

---

### di-specific-decorators — Prefer @Param/@Body/@Headers over @Req()

`@Req()` couples to Express, breaks platform independence, and bypasses automatic validation.

```typescript
// GOOD
@Get(':id')
findOne(@Param('id', ParseUUIDPipe) id: string) {}

@Post()
create(@Body() dto: CreateUserDto, @Headers('x-tenant-id') tenantId: string) {}

// BAD
@Get(':id')
findOne(@Req() req: Request) {
  const id = req.params.id; // No automatic validation
}
```

---

### di-custom-decorators — Extract common patterns into param decorators

```typescript
export const CurrentUser = createParamDecorator(
  (data: keyof User | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;
    return data ? user?.[data] : user;
  },
);

// Usage: @CurrentUser() user: User  or  @CurrentUser('id') userId: string
```

---

### di-provider-types — Use the right provider strategy

```typescript
// useClass — Standard (default) or swap by environment
{ provide: StorageService, useClass: process.env.NODE_ENV === 'test'
    ? MockStorageService : S3StorageService }

// useValue — Static values
{ provide: 'API_KEY', useValue: 'abc123' }

// useFactory — Dynamic/async creation
{
  provide: 'CACHE_CLIENT',
  useFactory: async (config: ConfigService) => {
    const client = new Redis(config.get('REDIS_URL'));
    await client.ping();
    return client;
  },
  inject: [ConfigService],
}

// useExisting — Alias to existing provider (same singleton)
{ provide: 'AliasedLogger', useExisting: LoggerService }
```

---

## Validation & DTOs (CRITICAL)

### val-global-pipe — Global ValidationPipe with whitelist is a security requirement

Without `whitelist: true`, clients can inject arbitrary fields (e.g., `{ "role": "admin" }`)
that pass through to your database layer.

**Anti-pattern:** `app.useGlobalPipes(new ValidationPipe())` with no options.

**Correct pattern:**

```typescript
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,              // Strip non-decorated properties
    forbidNonWhitelisted: true,   // 400 error on unknown properties
    transform: true,              // Auto-transform to DTO class instances
    transformOptions: {
      enableImplicitConversion: true, // Auto-convert string "5" → number 5
    },
  }),
);
```

---

### val-class-dtos — DTOs must be classes, not interfaces

Decorators only work on classes. Interfaces are erased at runtime and provide
zero validation.

**Anti-pattern:**

```typescript
interface CreateUserDto { name: string; email: string; } // No runtime validation
```

**Correct pattern:**

```typescript
export class CreateUserDto {
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  name: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsOptional()
  @IsString()
  bio?: string;
}
```

---

### val-nested-type — @ValidateNested() requires @Type() from class-transformer

`@ValidateNested()` alone does nothing. Both decorators are always required together.

**Anti-pattern:**

```typescript
@ValidateNested()
shippingAddress: AddressDto; // Validation silently skipped — @Type() is missing
```

**Correct pattern:**

```typescript
export class CreateOrderDto {
  // Single nested object
  @ValidateNested()
  @Type(() => AddressDto) // REQUIRED
  shippingAddress: AddressDto;

  // Array of nested objects
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];
}
```

---

### val-mapped-types — Use PartialType/PickType/OmitType to avoid DTO duplication

```typescript
import { PartialType, PickType, OmitType, IntersectionType } from '@nestjs/mapped-types';
// For Swagger support, import from @nestjs/swagger instead

export class UpdateUserDto extends PartialType(CreateUserDto) {}       // All optional
export class LoginDto extends PickType(CreateUserDto, ['email', 'password']) {}
export class PublicUserDto extends OmitType(CreateUserDto, ['password']) {}
export class CreateUserWithProfileDto extends IntersectionType(CreateUserDto, CreateProfileDto) {}
```

---

### val-separate-dtos — Never expose entities directly; use response DTOs

```typescript
// Response DTO — controls what clients see
export class UserResponseDto {
  id: string;
  name: string;
  email: string;
  createdAt: Date;
  // password is never exposed
}

// In service, map entity → response DTO
return plainToInstance(UserResponseDto, user, { excludeExtraneousValues: true });
```

---

### val-business-in-service — DTO validates format; service validates business rules

```typescript
// DTO: "Is this a valid email format?"
@IsEmail()
email: string;

// Service: "Is this email already taken?"
async create(dto: CreateUserDto) {
  const exists = await this.repo.findOne({ where: { email: dto.email } });
  if (exists) throw new ConflictException('Email already registered');
}
```

---

### val-pagination-dto — Reusable pagination DTO

```typescript
export class PaginationQueryDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}
```

---

### val-swagger-plugin — Use NestJS Swagger CLI plugin for auto-generated docs

```json
{
  "compilerOptions": {
    "plugins": [
      {
        "name": "@nestjs/swagger",
        "options": { "classValidatorShim": true, "introspectComments": true }
      }
    ]
  }
}
```

---

## Error Handling (CRITICAL)

### err-global-filter — Single AllExceptionsFilter registered via APP_FILTER

Register via module providers (not `app.useGlobalFilters()`) for dependency injection support.

**Anti-pattern:** No error-handling filter — NestJS sends raw stack traces. Or: `app.useGlobalFilters(new AllExceptionsFilter())`.

**Correct pattern:**

```typescript
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    const request = ctx.getRequest();

    const { status, message } = this.extractError(exception);

    const errorResponse = {
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
      method: request.method,
      message,
    };

    if (status >= 500) {
      this.logger.error(
        `${request.method} ${request.url} ${status}`,
        exception instanceof Error ? exception.stack : undefined,
      );
    }

    response.status(status).json(errorResponse);
  }

  private extractError(exception: unknown): { status: number; message: string } {
    if (exception instanceof HttpException) {
      const response = exception.getResponse();
      return {
        status: exception.getStatus(),
        message: typeof response === 'string'
          ? response
          : (response as any).message ?? exception.message,
      };
    }
    return { status: 500, message: 'Internal server error' };
  }
}

// Register in AppModule
@Module({
  providers: [
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
  ],
})
export class AppModule {}
```

---

### err-builtin-exceptions — Use NestJS built-in exceptions, not raw HttpException

```typescript
throw new BadRequestException('Invalid input');          // 400
throw new UnauthorizedException('Invalid credentials');  // 401
throw new ForbiddenException('Insufficient permissions');// 403
throw new NotFoundException('User not found');           // 404
throw new ConflictException('Email already exists');     // 409
throw new UnprocessableEntityException('Invalid data');  // 422
throw new InternalServerErrorException();                // 500
```

---

### err-domain-exceptions — Create structured business exceptions with error codes

```typescript
export class BusinessException extends HttpException {
  constructor(
    public readonly errorCode: string,
    message: string,
    statusCode: HttpStatus = HttpStatus.UNPROCESSABLE_ENTITY,
  ) {
    super({ errorCode, message, statusCode }, statusCode);
  }
}

export class InsufficientBalanceException extends BusinessException {
  constructor(required: number, available: number) {
    super('INSUFFICIENT_BALANCE', `Required ${required}, available ${available}`);
  }
}
```

---

### err-no-swallow — Never catch and swallow errors; let filters handle them

**Anti-pattern:**

```typescript
@Get(':id')
async findOne(@Param('id') id: string) {
  try {
    return await this.service.findOne(id);
  } catch (error) {
    throw new InternalServerErrorException(error.message); // Hides root cause
  }
}
```

**Correct pattern:**

```typescript
@Get(':id')
findOne(@Param('id', ParseUUIDPipe) id: string) {
  return this.service.findOneOrFail(id); // Throws NotFoundException in service
}
```

---

### err-consistent-shape — Maintain consistent error response format

```typescript
interface ErrorResponse {
  statusCode: number;
  timestamp: string;
  path: string;
  method: string;
  message: string | string[];
  errorCode?: string; // For business exceptions
}
```

---

## Auth & Security (CRITICAL)

### auth-dual-token — Short-lived access tokens (15min) with refresh token rotation

**Anti-pattern:** Single long-lived JWT (24hr+) with no refresh mechanism.

**Correct pattern:**

```typescript
@Injectable()
export class AuthService {
  async generateTokens(user: User) {
    const payload = { sub: user.id, email: user.email, roles: user.roles };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.configService.get('JWT_ACCESS_SECRET'),
        expiresIn: '15m',
      }),
      this.jwtService.signAsync(payload, {
        secret: this.configService.get('JWT_REFRESH_SECRET'), // DIFFERENT secret
        expiresIn: '7d',
      }),
    ]);

    // Store hashed refresh token — NEVER store plaintext
    const hashedRefreshToken = await argon2.hash(refreshToken);
    await this.usersRepo.update(user.id, { hashedRefreshToken });

    return { accessToken, refreshToken };
  }

  async refreshTokens(userId: string, refreshToken: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user?.hashedRefreshToken) throw new ForbiddenException('Access denied');

    const isValid = await argon2.verify(user.hashedRefreshToken, refreshToken);
    if (!isValid) throw new ForbiddenException('Access denied');

    // Token rotation: issue new pair, invalidate old
    return this.generateTokens(user);
  }

  async logout(userId: string) {
    await this.usersRepo.update(userId, { hashedRefreshToken: null });
  }
}
```

---

### auth-separate-secrets — Use different secrets for access and refresh tokens

```typescript
@Module({
  imports: [
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get('JWT_ACCESS_SECRET'),
        signOptions: { expiresIn: '15m' },
      }),
    }),
    PassportModule.register({ defaultStrategy: 'jwt' }),
  ],
})
export class AuthModule {}
```

---

### auth-httponly-cookie — Store refresh tokens in HTTP-only cookies

```typescript
@Post('login')
async login(@Body() dto: LoginDto, @Res({ passthrough: true }) res: Response) {
  const { accessToken, refreshToken } = await this.authService.login(dto);
  res.cookie('refresh_token', refreshToken, {
    httpOnly: true,
    secure: true,
    sameSite: 'strict',
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
    path: '/auth/refresh',
  });
  return { accessToken };
}
```

---

### auth-hash-passwords — Always hash passwords with bcrypt/argon2

Never store plaintext passwords.

---

### auth-rbac-guards — Register auth and role guards globally via APP_GUARD

```typescript
// common/decorators/roles.decorator.ts
export const ROLES_KEY = 'roles';
export const Roles = (...roles: Role[]) => SetMetadata(ROLES_KEY, roles);

// common/guards/roles.guard.ts
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!requiredRoles) return true;
    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.some((role) => user.roles?.includes(role));
  }
}

// common/decorators/public.decorator.ts
export const IS_PUBLIC_KEY = 'isPublic';
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);

// Register globally in AppModule
@Module({
  providers: [
    { provide: APP_GUARD, useClass: JwtAuthGuard },  // Auth first
    { provide: APP_GUARD, useClass: RolesGuard },     // Then roles
  ],
})
export class AppModule {}

// Usage
@Post()
@Roles(Role.ADMIN)
create(@Body() dto: CreateUserDto) {}

@Get('health')
@Public()
healthCheck() { return 'ok'; }
```

---

### auth-casl-permissions — Use CASL for fine-grained conditional permissions

Use when you need rules like "users can edit only their own posts":

```typescript
export function defineAbilityFor(user: User) {
  const { can, cannot, build } = new AbilityBuilder<AppAbility>(createPrismaAbility);

  if (user.role === Role.ADMIN) {
    can('manage', 'all');
  } else {
    can('read', 'Post');
    can('update', 'Post', { authorId: user.id });
    can('delete', 'Post', { authorId: user.id });
    cannot('update', 'Post', { published: true });
  }

  return build();
}
```

---

### auth-rate-limit — Rate-limit auth endpoints with @nestjs/throttler

**Anti-pattern:** No rate limiting — attacker brute-forces 10,000 passwords/minute.

**Correct pattern:**

```typescript
@Module({
  imports: [
    ThrottlerModule.forRoot([{
      ttl: 60000,   // 1 minute window
      limit: 60,    // 60 requests per window
    }]),
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
})

// Stricter limit on auth endpoints
@Controller('auth')
export class AuthController {
  @Post('login')
  @Throttle({ default: { ttl: 60000, limit: 5 } }) // 5 attempts per minute
  login() {}

  @Get('health')
  @SkipThrottle()
  health() {}
}
```

For multi-instance deployments, use Redis-backed throttler storage.

---

### auth-cors-strict — Never use origin: '*' in production

```typescript
app.enableCors({
  origin: configService.get<string>('ALLOWED_ORIGINS').split(','),
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  credentials: true,
  maxAge: 86400,
});
```

---

### auth-helmet — Enable Helmet security headers

```typescript
import helmet from 'helmet';
app.use(helmet());
```

---

## Database (CRITICAL)

### db-no-synchronize — Disable synchronize: true in production

`synchronize: true` can drop columns and lose data. Always use migrations.

**Anti-pattern:** `synchronize: true` in production config.

**Correct pattern:**

```typescript
TypeOrmModule.forRootAsync({
  imports: [ConfigModule],
  inject: [ConfigService],
  useFactory: (config: ConfigService) => ({
    type: 'postgres',
    host: config.get('DB_HOST'),
    port: config.get<number>('DB_PORT'),
    username: config.get('DB_USER'),
    password: config.get('DB_PASSWORD'),
    database: config.get('DB_NAME'),
    entities: [__dirname + '/**/*.entity{.ts,.js}'],
    synchronize: false, // ALWAYS false in production
    logging: config.get('NODE_ENV') === 'development',
    extra: {
      max: 20,  // Connection pool max
      min: 5,   // Connection pool min
    },
  }),
})
```

---

### db-release-queryrunner — Always release QueryRunner in finally block

Unreleased connections cause pool exhaustion and eventual application failure.

**Anti-pattern:** `queryRunner.release()` only in try block — skipped on error.

**Correct pattern:**

```typescript
async transferFunds(fromId: string, toId: string, amount: number) {
  const queryRunner = this.dataSource.createQueryRunner();
  await queryRunner.connect();
  await queryRunner.startTransaction();

  try {
    await queryRunner.manager.decrement(Account, { id: fromId }, 'balance', amount);
    await queryRunner.manager.increment(Account, { id: toId }, 'balance', amount);
    await queryRunner.commitTransaction();
  } catch (error) {
    await queryRunner.rollbackTransaction();
    throw error;
  } finally {
    await queryRunner.release(); // CRITICAL: Always release in finally
  }
}
```

---

### db-data-mapper — Use Data Mapper over Active Record for testability (TypeORM)

```typescript
@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private readonly usersRepo: Repository<User>,
  ) {}

  findByEmail(email: string) {
    return this.usersRepo.findOne({
      where: { email },
      select: ['id', 'email', 'password'],
    });
  }
}
```

---

### db-connection-pooling — Configure pool size based on expected concurrency

```typescript
// TypeORM
extra: { max: 20, min: 5 }

// Prisma — set in connection string
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=20&pool_timeout=10"
```

---

### db-prisma-migrate-deploy — Use prisma migrate deploy in production, never db push

```bash
# Development: create and apply migration
npx prisma migrate dev --name add_user_roles

# Production: apply pending migrations only
npx prisma migrate deploy

# Generate client after schema changes
npx prisma generate
```

---

### db-prisma-service — PrismaService with lifecycle hooks

```typescript
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}

@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
```

---

### db-no-n-plus-one — Avoid N+1 queries with eager loading or DataLoader

**Anti-pattern:**

```typescript
const users = await usersRepo.find();
for (const user of users) {
  user.orders = await ordersRepo.find({ where: { userId: user.id } }); // N queries!
}
```

**Correct pattern:**

```typescript
const users = await usersRepo.find({ relations: ['orders'] }); // 1 JOIN query
```

---

### db-select-fields — Select only needed fields, not full entities

**Anti-pattern:** Loading entire entity when you need one field.

**Correct pattern:**

```typescript
const user = await usersRepo.findOne({ where: { id }, select: ['email'] });
```

---

## Configuration & Logging (CRITICAL)

### config-validate-startup — Validate env vars at startup, not at first request

**Anti-pattern:** App starts successfully, then crashes on first request when `DB_HOST` is missing.

**Correct pattern:**

```typescript
import * as Joi from 'joi';

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string().valid('development', 'production', 'test').default('development'),
  PORT: Joi.number().default(3000),
  DB_HOST: Joi.string().required(),
  DB_PORT: Joi.number().default(5432),
  DB_USER: Joi.string().required(),
  DB_PASSWORD: Joi.string().required(),
  DB_NAME: Joi.string().required(),
  JWT_ACCESS_SECRET: Joi.string().min(32).required(),
  JWT_REFRESH_SECRET: Joi.string().min(32).required(),
  ALLOWED_ORIGINS: Joi.string().required(),
});

// app.module.ts
ConfigModule.forRoot({
  isGlobal: true,
  cache: true,
  envFilePath: ['.env.local', '.env'],
  load: [appConfig, databaseConfig, authConfig],
  validationSchema: envValidationSchema,
})
```

---

### config-no-process-env — Never access process.env directly; use ConfigService

**Anti-pattern:** `const secret = process.env.JWT_SECRET` scattered across services.

**Correct pattern:**

```typescript
// config/auth.config.ts
export const authConfig = registerAs('auth', () => ({
  jwtAccessSecret: process.env.JWT_ACCESS_SECRET,
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET,
  accessTokenExpiry: process.env.ACCESS_TOKEN_EXPIRY || '15m',
}));

// Type-safe injection
@Injectable()
export class AuthService {
  constructor(
    @Inject(authConfig.KEY)
    private readonly config: ConfigType<typeof authConfig>,
  ) {}

  generateToken() {
    return this.jwtService.signAsync(payload, {
      secret: this.config.jwtAccessSecret,        // Full autocomplete
      expiresIn: this.config.accessTokenExpiry,
    });
  }
}
```

---

### config-cache-true — Enable cache on ConfigModule for performance

`process.env` access is slow. Cache it.

```typescript
ConfigModule.forRoot({ cache: true })
```

---

### config-env-example — Commit .env.example with placeholders; gitignore .env

- Commit `.env.example` with all required keys (empty values)
- Add `.env` and `.env.local` to `.gitignore`
- Never put secrets in `.env.example`

---

### log-pino — Use Pino (nestjs-pino) for production logging

Pino is the fastest Node.js logger. Use `pino-pretty` in development, raw JSON in production.

```typescript
// main.ts
const app = await NestFactory.create(AppModule, { bufferLogs: true });
app.useLogger(app.get(Logger));

// app.module.ts
LoggerModule.forRoot({
  pinoHttp: {
    transport: process.env.NODE_ENV === 'development'
      ? { target: 'pino-pretty', options: { colorize: true } }
      : undefined,
    level: process.env.LOG_LEVEL || 'info',
    autoLogging: true,
    redact: ['req.headers.authorization', 'req.body.password'],
  },
})
```

---

### log-context — Use Logger with class context in services

```typescript
@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  async create(dto: CreateUserDto) {
    this.logger.log(`Creating user: ${dto.email}`);
    try {
      const user = await this.usersRepo.save(dto);
      this.logger.log(`User created: ${user.id}`);
      return user;
    } catch (error) {
      this.logger.error(`Failed to create user: ${dto.email}`, error.stack);
      throw error;
    }
  }
}
```

---

### health-endpoints — Separate liveness and readiness health checks with @nestjs/terminus

```typescript
@Controller('health')
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    private readonly db: TypeOrmHealthIndicator,
    private readonly memory: MemoryHealthIndicator,
    private readonly disk: DiskHealthIndicator,
  ) {}

  // Liveness: is the process running?
  @Get('liveness')
  @HealthCheck()
  liveness() {
    return this.health.check([
      () => this.memory.checkHeap('memory_heap', 300 * 1024 * 1024),
    ]);
  }

  // Readiness: can it serve requests?
  @Get('readiness')
  @HealthCheck()
  readiness() {
    return this.health.check([
      () => this.db.pingCheck('database'),
      () => this.disk.checkStorage('storage', { path: '/', thresholdPercent: 0.9 }),
    ]);
  }
}
```

---

## Testing (HIGH)

### test-aaa — Follow Arrange-Act-Assert structure

```typescript
it('should return user when found', async () => {
  // Arrange
  const mockUser = { id: '1', email: 'test@test.com' } as User;
  usersRepo.findOne.mockResolvedValueOnce(mockUser);

  // Act
  const result = await service.findOneOrFail('1');

  // Assert
  expect(result).toEqual(mockUser);
  expect(usersRepo.findOne).toHaveBeenCalledWith({ where: { id: '1' } });
});
```

---

### test-colocate — Co-locate unit tests; E2E in /test

- Unit tests: `*.spec.ts` next to source file
- E2E tests: `*.e2e-spec.ts` in `/test` directory

---

### test-mock-providers — Use Test.createTestingModule with mocked providers

Don't import real modules in unit tests.

```typescript
describe('UsersService', () => {
  let service: UsersService;
  let usersRepo: jest.Mocked<Repository<User>>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: getRepositoryToken(User),
          useValue: {
            findOne: jest.fn(),
            create: jest.fn(),
            save: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get(UsersService);
    usersRepo = module.get(getRepositoryToken(User));
  });

  it('should throw NotFoundException when user not found', async () => {
    usersRepo.findOne.mockResolvedValueOnce(null);
    await expect(service.findOneOrFail('999')).rejects.toThrow(NotFoundException);
  });
});
```

---

### test-e2e-production-pipes — Apply same pipes in E2E tests as production

```typescript
beforeAll(async () => {
  const moduleFixture = await Test.createTestingModule({
    imports: [AppModule],
  })
    .overrideProvider(DataSource)
    .useValue(testDataSource)
    .compile();

  app = moduleFixture.createNestApplication();
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  await app.init();
});
```

---

### test-containers — Use TestContainers for integration tests with real databases

```typescript
import { PostgreSqlContainer } from '@testcontainers/postgresql';

beforeAll(async () => {
  container = await new PostgreSqlContainer().start();
  const module = await Test.createTestingModule({
    imports: [
      TypeOrmModule.forRoot({
        type: 'postgres',
        host: container.getHost(),
        port: container.getMappedPort(5432),
        entities: [User],
        synchronize: true, // OK for test containers
      }),
      UsersModule,
    ],
  }).compile();
}, 60_000);
```

---

### test-what-not — Don't test module definitions, private methods, or framework behavior

- Module definitions are configuration, not logic
- Private methods — test through public API
- Don't test that `@Get()` maps to GET — trust NestJS
- Don't test that bcrypt hashes correctly — trust the library

---

## Advanced Patterns (HIGH)

### cqrs-commands-queries — Separate commands (writes) from queries (reads)

```typescript
// commands/create-order.command.ts
export class CreateOrderCommand {
  constructor(
    public readonly userId: string,
    public readonly items: OrderItemDto[],
  ) {}
}

@CommandHandler(CreateOrderCommand)
export class CreateOrderHandler implements ICommandHandler<CreateOrderCommand> {
  async execute(command: CreateOrderCommand): Promise<Order> {
    const order = this.ordersRepo.create({
      userId: command.userId,
      items: command.items,
      status: OrderStatus.PENDING,
    });
    return this.ordersRepo.save(order);
  }
}

// Module
@Module({
  imports: [CqrsModule, TypeOrmModule.forFeature([Order])],
  providers: [CreateOrderHandler, GetOrderHandler, OrderSaga],
})
export class OrdersModule {}
```

---

### micro-hybrid — Run HTTP + microservice transports in hybrid mode

```typescript
const app = await NestFactory.create(AppModule);

app.connectMicroservice<MicroserviceOptions>({
  transport: Transport.RMQ,
  options: {
    urls: [process.env.RABBITMQ_URL],
    queue: 'orders_queue',
    queueOptions: { durable: true },
  },
});

await app.startAllMicroservices();
await app.listen(3000);
```

---

### micro-patterns — Use @MessagePattern for request-response, @EventPattern for fire-and-forget

```typescript
// Request-response
@MessagePattern({ cmd: 'get_user' })
async getUser(@Payload() data: { userId: string }) {
  return this.usersService.findOneOrFail(data.userId);
}

// Fire-and-forget
@EventPattern('order_created')
async handleOrderCreated(@Payload() data: OrderCreatedEvent) {
  await this.notificationService.sendConfirmation(data);
}
```

---

### ws-auth — Authenticate WebSocket connections via middleware adapter

```typescript
export class AuthenticatedSocketAdapter extends IoAdapter {
  createIOServer(port: number, options?: ServerOptions) {
    const server = super.createIOServer(port, options);
    const jwtService = this.app.get(JwtService);

    server.use(async (socket: Socket, next) => {
      const token = socket.handshake.auth?.token
        || socket.handshake.headers?.authorization?.split(' ')[1];
      if (!token) return next(new Error('Authentication required'));

      try {
        const payload = await jwtService.verifyAsync(token);
        socket.data.userId = payload.sub;
        next();
      } catch {
        next(new Error('Invalid token'));
      }
    });

    return server;
  }
}

// main.ts
app.useWebSocketAdapter(new AuthenticatedSocketAdapter(app));
```

---

### gql-dataloader — Use DataLoader to prevent N+1 in GraphQL (CRITICAL for GraphQL)

```typescript
@Injectable({ scope: Scope.REQUEST })
export class OrdersLoader {
  constructor(private readonly prisma: PrismaService) {}

  readonly batchByUserId = new DataLoader<string, Order[]>(async (userIds) => {
    const orders = await this.prisma.order.findMany({
      where: { userId: { in: [...userIds] } },
    });
    const map = new Map<string, Order[]>();
    orders.forEach((order) => {
      const existing = map.get(order.userId) ?? [];
      existing.push(order);
      map.set(order.userId, existing);
    });
    return userIds.map((id) => map.get(id) ?? []);
  });
}
```

---

### queue-bullmq — Use BullMQ with retry and backoff for async jobs

```typescript
// Producer
@Injectable()
export class EmailService {
  constructor(@InjectQueue('emails') private readonly emailQueue: Queue) {}

  async sendWelcomeEmail(userId: string) {
    await this.emailQueue.add('welcome', { userId }, {
      priority: 1,
      attempts: 3,
      backoff: { type: 'exponential', delay: 1000 },
      removeOnComplete: { count: 1000 },
      removeOnFail: { count: 5000 },
    });
  }
}

// Consumer
@Processor('emails')
export class EmailProcessor extends WorkerHost {
  async process(job: Job<{ userId: string }>) {
    switch (job.name) {
      case 'welcome':
        await this.sendWelcomeEmail(job.data.userId);
        break;
    }
  }
}
```

---

### cache-redis — Use Redis-backed cache with correct TTL units

**Pitfall**: cache-manager v5 uses **milliseconds** (not seconds like v4). `ttl: 60` = 60ms.

```typescript
CacheModule.registerAsync({
  isGlobal: true,
  imports: [ConfigModule],
  inject: [ConfigService],
  useFactory: (config: ConfigService) => ({
    stores: [new KeyvRedis(config.get('REDIS_URL'))],
    ttl: 60_000, // 60 seconds (milliseconds!)
  }),
})

// Manual cache with invalidation
@Injectable()
export class ProductsService {
  constructor(@Inject(CACHE_MANAGER) private readonly cacheManager: Cache) {}

  async findOne(id: string): Promise<Product> {
    const cached = await this.cacheManager.get<Product>(`product:${id}`);
    if (cached) return cached;

    const product = await this.productsRepo.findOneOrFail({ where: { id } });
    await this.cacheManager.set(`product:${id}`, product, 600_000);
    return product;
  }

  async update(id: string, dto: UpdateProductDto) {
    const product = await this.productsRepo.save({ id, ...dto });
    await this.cacheManager.del(`product:${id}`); // Invalidate
    return product;
  }
}
```

---

## Deployment & Performance (CRITICAL)

### deploy-node-cmd — Use CMD ["node", "dist/main.js"], not npm start

npm doesn't forward SIGTERM, preventing graceful shutdown in containers.

**Anti-pattern:** `CMD ["npm", "start"]`

**Correct pattern:**

```dockerfile
# Multi-stage build
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production && cp -R node_modules /prod_modules
RUN npm ci

FROM node:20-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-alpine AS production
WORKDIR /app
RUN addgroup -g 1001 -S nodejs && adduser -S nestjs -u 1001
USER nestjs
COPY --from=deps --chown=nestjs:nodejs /prod_modules ./node_modules
COPY --from=build --chown=nestjs:nodejs /app/dist ./dist
COPY --chown=nestjs:nodejs package.json ./

CMD ["node", "dist/main.js"]
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD wget -qO- http://localhost:3000/health/liveness || exit 1
```

---

### deploy-shutdown-hooks — Enable shutdown hooks and implement OnApplicationShutdown

```typescript
// main.ts
app.enableShutdownHooks();

// In any service that holds connections
@Injectable()
export class DatabaseService implements OnApplicationShutdown, BeforeApplicationShutdown {
  async beforeApplicationShutdown(signal?: string) {
    this.logger.log(`Shutdown signal received: ${signal}`);
    // Stop processing new jobs, drain queues
  }

  async onApplicationShutdown(signal?: string) {
    await this.connection.close();
    this.logger.log('Database connection closed');
  }
}
```

---

### deploy-fastify — Use Fastify adapter for throughput-critical services (~2x over Express)

```typescript
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';

const app = await NestFactory.create<NestFastifyApplication>(
  AppModule,
  new FastifyAdapter({ logger: false }),
);

await app.listen(3000, '0.0.0.0'); // Listen on 0.0.0.0 for Docker
```

**Caveat**: Some Express-specific middleware (`multer`, Passport Express strategies) needs Fastify equivalents.

---

### deploy-lazy-load — Lazy-load infrequently used modules

```typescript
@Injectable()
export class ReportService {
  constructor(private readonly lazyLoader: LazyModuleLoader) {}

  async generateReport() {
    const moduleRef = await this.lazyLoader.load(() => ReportModule);
    const reportGenerator = moduleRef.get(ReportGeneratorService);
    return reportGenerator.generate();
  }
}
```

---

### deploy-compression — Enable response compression

```typescript
import compression from 'compression';
app.use(compression()); // Express

// Or for Fastify:
import { fastifyCompress } from '@fastify/compress';
await app.register(fastifyCompress);
```

---

### deploy-cluster — Use Node.js cluster for multi-core utilization

```typescript
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
  import('./main');
}
```

In Docker, prefer Node.js cluster directly over PM2 — PM2 adds unnecessary overhead.

---

### deploy-k8s-probes — Configure readiness and liveness probes in Kubernetes

```yaml
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

---

## Bootstrap Template

### Correct main.ts

```typescript
import { NestFactory } from '@nestjs/core';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });

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

---

## Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Files | `kebab-case.<type>.ts` | `create-user.dto.ts` |
| Classes | `PascalCase` + type suffix | `CreateUserDto`, `AuthGuard` |
| Modules | `<Feature>Module` | `UsersModule` |
| Services | `<Feature>Service` | `UsersService` |
| Controllers | `<Feature>Controller` | `UsersController` |
| Entities | singular `PascalCase` | `User`, `OrderItem` |
| Test files | `*.spec.ts` (unit), `*.e2e-spec.ts` (E2E) | `users.service.spec.ts` |

---

## Request Lifecycle

```
Request → Middleware → Guards → Interceptors (pre) → Pipes → Handler → Interceptors (post) → Filters (on error)
```

- **Middleware**: Logging, CORS, request ID — no access to handler context
- **Guards**: Auth, RBAC — have `ExecutionContext`, block before interceptors
- **Interceptors**: Response transform, timing, caching — wrap handler with RxJS
- **Pipes**: Per-parameter validation and transformation
- **Filters**: Error formatting — catch exceptions from any layer above

---

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
