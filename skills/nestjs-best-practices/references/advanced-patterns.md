# Advanced Patterns

## Table of Contents

1. CQRS & Event Sourcing
2. Microservices
3. WebSockets
4. GraphQL
5. Queue Management (BullMQ)
6. Caching

---

## 1. CQRS & Event Sourcing

### Commands and Queries

```typescript
// commands/create-order.command.ts
export class CreateOrderCommand {
  constructor(
    public readonly userId: string,
    public readonly items: OrderItemDto[],
    public readonly shippingAddress: AddressDto,
  ) {}
}

// commands/handlers/create-order.handler.ts
@CommandHandler(CreateOrderCommand)
export class CreateOrderHandler implements ICommandHandler<CreateOrderCommand> {
  constructor(private readonly ordersRepo: Repository<Order>) {}

  async execute(command: CreateOrderCommand): Promise<Order> {
    const order = this.ordersRepo.create({
      userId: command.userId,
      items: command.items,
      status: OrderStatus.PENDING,
    });
    return this.ordersRepo.save(order);
  }
}

// queries/get-order.query.ts
export class GetOrderQuery {
  constructor(public readonly orderId: string) {}
}

@QueryHandler(GetOrderQuery)
export class GetOrderHandler implements IQueryHandler<GetOrderQuery> {
  async execute(query: GetOrderQuery): Promise<OrderResponseDto> {
    return this.ordersRepo.findOneOrFail({ where: { id: query.orderId } });
  }
}
```

### Events and Sagas

```typescript
// events/order-created.event.ts
export class OrderCreatedEvent {
  constructor(
    public readonly orderId: string,
    public readonly userId: string,
    public readonly total: number,
  ) {}
}

// In handler: this.eventBus.publish(new OrderCreatedEvent(order.id, order.userId, order.total));

// sagas/order.saga.ts
@Injectable()
export class OrderSaga {
  @Saga()
  orderCreated = (events$: Observable<any>): Observable<ICommand> => {
    return events$.pipe(
      ofType(OrderCreatedEvent),
      map((event) => new SendConfirmationEmailCommand(event.userId, event.orderId)),
    );
  };
}
```

### Module registration

```typescript
@Module({
  imports: [CqrsModule, TypeOrmModule.forFeature([Order])],
  providers: [
    CreateOrderHandler,
    GetOrderHandler,
    OrderCreatedEventHandler,
    OrderSaga,
  ],
})
export class OrdersModule {}
```

---

## 2. Microservices

### Transport selection

| Transport | Use Case |
|---|---|
| **TCP** | Simple inter-service, development |
| **Redis** | Pub/sub, real-time events |
| **NATS** | Lightweight fast messaging |
| **RabbitMQ** | Reliable commands, complex routing, DLQ |
| **Kafka** | High-throughput event streaming, analytics |
| **gRPC** | Low-latency strongly-typed RPC |

### Hybrid application (HTTP + microservice)

```typescript
// main.ts
const app = await NestFactory.create(AppModule);

// Add microservice transport alongside HTTP
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

### Message patterns

```typescript
// Request-response (synchronous messaging)
@MessagePattern({ cmd: 'get_user' })
async getUser(@Payload() data: { userId: string }) {
  return this.usersService.findOneOrFail(data.userId);
}

// Fire-and-forget (event-based)
@EventPattern('order_created')
async handleOrderCreated(@Payload() data: OrderCreatedEvent) {
  await this.notificationService.sendConfirmation(data);
}

// Client-side call
const user = await firstValueFrom(
  this.usersClient.send({ cmd: 'get_user' }, { userId: '123' }),
);
```

---

## 3. WebSockets

### Gateway setup

```typescript
@WebSocketGateway({
  cors: { origin: process.env.ALLOWED_ORIGINS?.split(',') },
  namespace: '/chat',
})
export class ChatGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer() server: Server;
  private readonly logger = new Logger(ChatGateway.name);

  afterInit() {
    this.logger.log('WebSocket gateway initialized');
  }

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('joinRoom')
  handleJoinRoom(client: Socket, roomId: string) {
    client.join(roomId);
    client.to(roomId).emit('userJoined', { userId: client.data.userId });
  }

  @SubscribeMessage('message')
  handleMessage(client: Socket, payload: { roomId: string; content: string }) {
    this.server.to(payload.roomId).emit('message', {
      userId: client.data.userId,
      content: payload.content,
      timestamp: new Date(),
    });
  }
}
```

### WebSocket authentication

```typescript
// adapters/authenticated-socket.adapter.ts
export class AuthenticatedSocketAdapter extends IoAdapter {
  constructor(private app: INestApplication) {
    super(app);
  }

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

For scaling across instances, use `@socket.io/redis-adapter`.

---

## 4. GraphQL

### Code-first approach (recommended)

```typescript
// GraphQL module setup
GraphQLModule.forRoot<ApolloDriverConfig>({
  driver: ApolloDriver,
  autoSchemaFile: join(process.cwd(), 'src/schema.gql'),
  sortSchema: true,
  playground: process.env.NODE_ENV === 'development',
})

// Object types
@ObjectType()
export class UserType {
  @Field(() => ID)
  id: string;

  @Field()
  name: string;

  @Field()
  email: string;

  @Field(() => [OrderType], { nullable: true })
  orders?: OrderType[];
}

// Resolver
@Resolver(() => UserType)
export class UsersResolver {
  constructor(private readonly usersService: UsersService) {}

  @Query(() => UserType)
  user(@Args('id', { type: () => ID }) id: string) {
    return this.usersService.findOneOrFail(id);
  }

  @Mutation(() => UserType)
  createUser(@Args('input') input: CreateUserInput) {
    return this.usersService.create(input);
  }
}
```

### DataLoader for N+1 prevention (CRITICAL for GraphQL)

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

// In resolver
@ResolveField(() => [OrderType])
orders(@Parent() user: UserType) {
  return this.ordersLoader.batchByUserId.load(user.id);
}
```

### Security: Use `graphql-armor` for query depth/cost limiting.

---

## 5. Queue Management (BullMQ)

### Setup

```typescript
@Module({
  imports: [
    BullModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        connection: { host: config.get('REDIS_HOST'), port: config.get('REDIS_PORT') },
      }),
    }),
    BullModule.registerQueue({ name: 'emails' }),
  ],
})
export class EmailModule {}
```

### Producer

```typescript
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
```

### Consumer

```typescript
@Processor('emails')
export class EmailProcessor extends WorkerHost {
  private readonly logger = new Logger(EmailProcessor.name);

  async process(job: Job<{ userId: string }>) {
    this.logger.log(`Processing ${job.name} for user ${job.data.userId}`);
    switch (job.name) {
      case 'welcome':
        await this.sendWelcomeEmail(job.data.userId);
        break;
      default:
        this.logger.warn(`Unknown job type: ${job.name}`);
    }
  }

  @OnWorkerEvent('completed')
  onCompleted(job: Job) {
    this.logger.log(`Job ${job.id} completed`);
  }

  @OnWorkerEvent('failed')
  onFailed(job: Job, error: Error) {
    this.logger.error(`Job ${job.id} failed: ${error.message}`, error.stack);
  }
}
```

---

## 6. Caching

### Redis-backed cache (production)

```typescript
import { CacheModule } from '@nestjs/cache-manager';
import KeyvRedis from '@keyv/redis';

@Module({
  imports: [
    CacheModule.registerAsync({
      isGlobal: true,
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        stores: [new KeyvRedis(config.get('REDIS_URL'))],
        ttl: 60_000, // 60 seconds default (cache-manager v5 uses ms!)
      }),
    }),
  ],
})
export class AppModule {}
```

### Auto-caching GET routes

```typescript
@Controller('products')
@UseInterceptors(CacheInterceptor) // Auto-cache all GET endpoints
export class ProductsController {
  @Get()
  @CacheTTL(300_000) // 5 minutes for this route
  findAll() { return this.productsService.findAll(); }

  @Get(':id')
  @CacheKey('product') // Custom cache key
  @CacheTTL(600_000) // 10 minutes
  findOne(@Param('id') id: string) { return this.productsService.findOne(id); }
}
```

### Manual cache management

```typescript
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

### TTL Guidelines

| Data Type | TTL | Example |
|---|---|---|
| Rapidly changing | 5–30 seconds | Stock prices, live scores |
| Moderately changing | 1–10 minutes | User profiles, product listings |
| Slowly changing | 30min – 24hr | Configuration, categories |
| Static | 24hr+ | Country lists, translations |

**Pitfall**: cache-manager v5 uses **milliseconds** (not seconds like v4). `ttl: 60` = 60ms, not 60s.
