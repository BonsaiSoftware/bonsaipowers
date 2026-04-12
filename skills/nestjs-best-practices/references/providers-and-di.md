# Providers & Dependency Injection

## Provider Registration Strategies

```typescript
// useClass — Standard class provider (default)
{ provide: UsersService, useClass: UsersService }
// Shorthand: just list UsersService in providers array

// useClass — Swap implementation by environment
{
  provide: StorageService,
  useClass: process.env.NODE_ENV === 'test' ? MockStorageService : S3StorageService,
}

// useValue — Static/pre-existing values
{ provide: 'API_KEY', useValue: 'abc123' }
{ provide: UsersService, useValue: mockUsersService } // Testing

// useFactory — Dynamic/async provider creation
{
  provide: 'CACHE_CLIENT',
  useFactory: async (config: ConfigService) => {
    const client = new Redis(config.get('REDIS_URL'));
    await client.ping();
    return client;
  },
  inject: [ConfigService], // Dependencies for factory
}

// useExisting — Alias token to existing provider (same singleton)
{ provide: 'AliasedLogger', useExisting: LoggerService }
```

## Injection Scopes

```typescript
// DEFAULT (Singleton) — One instance for entire app. Always prefer this.
@Injectable() // scope: Scope.DEFAULT is implicit
export class UsersService {}

// REQUEST — New instance per request. ~15% performance overhead.
// WARNING: Propagates up — if UsersService is REQUEST-scoped, any service
// that injects it also becomes REQUEST-scoped.
@Injectable({ scope: Scope.REQUEST })
export class TenantService {
  constructor(@Inject(REQUEST) private request: Request) {}
}

// TRANSIENT — New instance per injection point. Use for stateful-per-consumer services.
@Injectable({ scope: Scope.TRANSIENT })
export class ContextLogger {
  private context: string;
  constructor(@Inject(INQUIRER) private parentClass: object) {
    this.context = parentClass?.constructor?.name ?? 'Unknown';
  }
}
```

**Rule**: Only use REQUEST scope when you genuinely need per-request data (current user, tenant).
Never use it "just in case."

## Controllers — Keep Them Thin

Controllers handle HTTP concerns only: parameter extraction, status codes, response headers.

```typescript
// GOOD: Thin controller
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

  @Get()
  findAll(@Query() query: PaginationQueryDto) {
    return this.ordersService.findAll(query);
  }
}

// BAD: Fat controller with business logic
@Controller('orders')
export class OrdersController {
  @Post()
  async create(@Body() dto: CreateOrderDto, @Req() req) {
    // BAD: Business logic in controller
    const user = await this.usersRepo.findOne(req.user.id);
    if (user.balance < dto.total) throw new BadRequestException('Insufficient balance');
    const order = this.ordersRepo.create({ ...dto, userId: user.id });
    await this.ordersRepo.save(order);
    await this.mailService.sendConfirmation(user.email, order);
    return order;
  }
}
```

### Parameter decorators

Prefer specific decorators over `@Req()` for testability and platform independence:

```typescript
// GOOD
@Get(':id')
findOne(@Param('id', ParseUUIDPipe) id: string) {}

@Post()
create(@Body() dto: CreateUserDto, @Headers('x-tenant-id') tenantId: string) {}

// BAD — couples to Express, harder to test
@Get(':id')
findOne(@Req() req: Request) {
  const id = req.params.id; // No automatic validation
}
```

**Avoid `@Res()` directly** — it breaks NestJS standard response handling and interceptors.
Use only when you need to stream responses or set cookies.

## Service Design

```typescript
@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private readonly usersRepo: Repository<User>,
    private readonly configService: ConfigService,
  ) {}

  async findOneOrFail(id: string): Promise<User> {
    const user = await this.usersRepo.findOne({ where: { id } });
    if (!user) throw new NotFoundException(`User ${id} not found`);
    return user;
  }

  async create(dto: CreateUserDto): Promise<User> {
    const exists = await this.usersRepo.findOne({ where: { email: dto.email } });
    if (exists) throw new ConflictException('Email already registered');
    const user = this.usersRepo.create(dto);
    return this.usersRepo.save(user);
  }
}
```

## Resolving Circular Dependencies

```typescript
// Option 1: forwardRef (last resort — use on BOTH sides)
@Module({
  imports: [forwardRef(() => OrdersModule)],
})
export class UsersModule {}

@Module({
  imports: [forwardRef(() => UsersModule)],
})
export class OrdersModule {}

// Option 2 (PREFERRED): Extract shared logic into a third module
@Module({
  providers: [UserOrderLinkService],
  exports: [UserOrderLinkService],
})
export class SharedModule {}

// Option 3 (PREFERRED): Use events for cross-module communication
// In OrdersService:
this.eventEmitter.emit('order.created', { orderId, userId });
// In UsersModule: listen for event without importing OrdersModule
```

## Custom Decorators

```typescript
// Extract current user from request
export const CurrentUser = createParamDecorator(
  (data: keyof User | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;
    return data ? user?.[data] : user;
  },
);

// Usage: @CurrentUser() user: User  or  @CurrentUser('id') userId: string
```
