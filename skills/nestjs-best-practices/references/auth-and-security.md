# Auth & Security

## JWT Dual-Token Architecture

```
Access Token: Short-lived (15min), sent in Authorization header
Refresh Token: Long-lived (7 days), sent in HTTP-only cookie
```

### Auth module setup

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
  providers: [AuthService, JwtStrategy, JwtRefreshStrategy, LocalStrategy],
  controllers: [AuthController],
  exports: [AuthService],
})
export class AuthModule {}
```

### Token generation with separate secrets

```typescript
@Injectable()
export class AuthService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @InjectRepository(User) private readonly usersRepo: Repository<User>,
  ) {}

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

### JWT Strategy

```typescript
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get('JWT_ACCESS_SECRET'),
    });
  }

  validate(payload: JwtPayload) {
    return { id: payload.sub, email: payload.email, roles: payload.roles };
  }
}
```

### Set refresh token in HTTP-only cookie

```typescript
@Controller('auth')
export class AuthController {
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
}
```

## Role-Based Access Control (RBAC)

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
    if (!requiredRoles) return true; // No roles required
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
@Public() // Skip auth
healthCheck() { return 'ok'; }
```

## CASL for Fine-Grained Permissions

Use CASL when you need conditional permissions (e.g., "users can edit only their own posts"):

```typescript
// Define ability
type AppAbility = PureAbility<[string, Subjects]>;

export function defineAbilityFor(user: User) {
  const { can, cannot, build } = new AbilityBuilder<AppAbility>(createPrismaAbility);

  if (user.role === Role.ADMIN) {
    can('manage', 'all');
  } else {
    can('read', 'Post');
    can('update', 'Post', { authorId: user.id }); // Own posts only
    can('delete', 'Post', { authorId: user.id });
    cannot('update', 'Post', { published: true }); // Can't edit published
  }

  return build();
}
```

## Security Middleware

### Helmet

```typescript
import helmet from 'helmet';
app.use(helmet());
```

### Rate Limiting

```typescript
// app.module.ts
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

For multi-instance deployments, use Redis-backed throttler storage instead of default in-memory:

```typescript
ThrottlerModule.forRoot({
  throttlers: [{ ttl: 60000, limit: 60 }],
  storage: new ThrottlerStorageRedisService(redisClient),
})
```

### CORS

```typescript
app.enableCors({
  origin: configService.get<string>('ALLOWED_ORIGINS').split(','),
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  credentials: true,
  maxAge: 86400,
});
```
