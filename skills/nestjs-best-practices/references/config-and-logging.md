# Configuration & Logging

## ConfigModule Setup

```typescript
// app.module.ts
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,                    // Available everywhere without importing
      cache: true,                       // Cache process.env reads (perf improvement)
      envFilePath: ['.env.local', '.env'],
      load: [appConfig, databaseConfig, authConfig],
      validationSchema: envValidationSchema, // Joi schema
    }),
  ],
})
export class AppModule {}
```

## Typed Configuration Namespaces

```typescript
// config/database.config.ts
import { registerAs } from '@nestjs/config';

export const databaseConfig = registerAs('database', () => ({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 5432,
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  name: process.env.DB_NAME,
  ssl: process.env.DB_SSL === 'true',
}));

// config/auth.config.ts
export const authConfig = registerAs('auth', () => ({
  jwtAccessSecret: process.env.JWT_ACCESS_SECRET,
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET,
  accessTokenExpiry: process.env.ACCESS_TOKEN_EXPIRY || '15m',
  refreshTokenExpiry: process.env.REFRESH_TOKEN_EXPIRY || '7d',
}));
```

### Type-safe injection

```typescript
import { ConfigType } from '@nestjs/config';

@Injectable()
export class AuthService {
  constructor(
    @Inject(authConfig.KEY)
    private readonly config: ConfigType<typeof authConfig>,
  ) {}

  generateToken() {
    // Full autocomplete: this.config.jwtAccessSecret
    return this.jwtService.signAsync(payload, {
      secret: this.config.jwtAccessSecret,
      expiresIn: this.config.accessTokenExpiry,
    });
  }
}
```

## Environment Validation (CRITICAL)

Fail at startup, not at first request:

```typescript
// config/env.validation.ts
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
```

Alternative with class-validator:

```typescript
import { plainToInstance } from 'class-transformer';
import { IsNumber, IsString, validateSync } from 'class-validator';

class EnvironmentVariables {
  @IsString() DB_HOST: string;
  @IsNumber() DB_PORT: number;
  @IsString() JWT_ACCESS_SECRET: string;
}

export function validate(config: Record<string, unknown>) {
  const validated = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });
  const errors = validateSync(validated, { skipMissingProperties: false });
  if (errors.length > 0) throw new Error(errors.toString());
  return validated;
}

// ConfigModule.forRoot({ validate })
```

## .env File Management

- Commit `.env.example` with all required keys (empty values) to git
- Add `.env` and `.env.local` to `.gitignore`
- Never put secrets in `.env.example`

## Logging with Pino

```typescript
// main.ts
import { Logger } from 'nestjs-pino';

const app = await NestFactory.create(AppModule, { bufferLogs: true });
app.useLogger(app.get(Logger));

// app.module.ts
import { LoggerModule } from 'nestjs-pino';

@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp: {
        transport: process.env.NODE_ENV === 'development'
          ? { target: 'pino-pretty', options: { colorize: true } }
          : undefined, // JSON in production
        level: process.env.LOG_LEVEL || 'info',
        autoLogging: true, // Auto-log HTTP requests
        redact: ['req.headers.authorization', 'req.body.password'], // Redact sensitive data
      },
    }),
  ],
})
```

### Using logger in services

```typescript
import { Logger } from '@nestjs/common';

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

## Health Checks with Terminus

```typescript
// health/health.module.ts
@Module({
  imports: [TerminusModule],
  controllers: [HealthController],
})
export class HealthModule {}

// health/health.controller.ts
@Controller('health')
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    private readonly db: TypeOrmHealthIndicator,
    private readonly http: HttpHealthIndicator,
    private readonly memory: MemoryHealthIndicator,
    private readonly disk: DiskHealthIndicator,
  ) {}

  // Liveness: is the process running?
  @Get('liveness')
  @HealthCheck()
  liveness() {
    return this.health.check([
      () => this.memory.checkHeap('memory_heap', 300 * 1024 * 1024), // 300MB
    ]);
  }

  // Readiness: can it serve requests?
  @Get('readiness')
  @HealthCheck()
  readiness() {
    return this.health.check([
      () => this.db.pingCheck('database'),
      () => this.http.pingCheck('external-api', 'https://api.example.com/health'),
      () => this.disk.checkStorage('storage', { path: '/', thresholdPercent: 0.9 }),
    ]);
  }
}
```
