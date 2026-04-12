# Database

## ORM Selection Guide

| ORM | Best For | NestJS Integration |
|---|---|---|
| **Prisma** | Greenfield, DX-focused, type safety | `@prisma/client` + custom module |
| **TypeORM** | Enterprise, Java/Spring teams, Active Record | `@nestjs/typeorm` (first-class) |
| **MikroORM** | DDD, Unit of Work pattern | `@mikro-orm/nestjs` (first-class) |
| **Drizzle** | Performance-critical, minimal overhead | Manual integration |

## TypeORM Patterns

### Entity definition

```typescript
@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column({ select: false }) // Never loaded by default
  password: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @OneToMany(() => Order, (order) => order.user)
  orders: Order[];
}
```

### Module registration

```typescript
// app.module.ts — CRITICAL: synchronize: false in production
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
    synchronize: false, // ALWAYS false in production — use migrations
    logging: config.get('NODE_ENV') === 'development',
    extra: {
      max: 20,  // Connection pool max
      min: 5,   // Connection pool min
    },
  }),
})
```

### Transactions with QueryRunner

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

### Repository pattern

```typescript
// Prefer injecting Repository<Entity> with Data Mapper pattern
@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private readonly usersRepo: Repository<User>,
  ) {}

  findByEmail(email: string) {
    return this.usersRepo.findOne({
      where: { email },
      select: ['id', 'email', 'password'], // Explicitly select password
    });
  }
}
```

## Prisma Patterns

### PrismaService setup

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

// Mark as global — used everywhere
@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
```

### Prisma in services

```typescript
@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  findAll(query: PaginationQueryDto) {
    return this.prisma.user.findMany({
      skip: (query.page - 1) * query.limit,
      take: query.limit,
      select: { id: true, email: true, name: true }, // Explicit select
    });
  }

  // Interactive transaction
  async transfer(fromId: string, toId: string, amount: number) {
    return this.prisma.$transaction(async (tx) => {
      const sender = await tx.account.update({
        where: { id: fromId },
        data: { balance: { decrement: amount } },
      });
      if (sender.balance < 0) throw new Error('Insufficient funds');
      await tx.account.update({
        where: { id: toId },
        data: { balance: { increment: amount } },
      });
    });
  }
}
```

### Migrations

```bash
# Development: create and apply migration
npx prisma migrate dev --name add_user_roles

# Production: apply pending migrations only (NEVER use db push)
npx prisma migrate deploy

# Generate client after schema changes
npx prisma generate
```

## MikroORM Patterns

```typescript
@Injectable()
export class UsersService {
  constructor(private readonly em: EntityManager) {}

  async create(dto: CreateUserDto) {
    const user = this.em.create(User, dto); // Creates managed entity
    await this.em.flush(); // Batches all changes in single transaction
    return user;
  }

  async update(id: string, dto: UpdateUserDto) {
    const user = await this.em.findOneOrFail(User, id);
    wrap(user).assign(dto);
    await this.em.flush(); // Only changed fields are updated
    return user;
  }
}
```

## Common Anti-Patterns

```typescript
// BAD: N+1 query problem
const users = await usersRepo.find();
for (const user of users) {
  user.orders = await ordersRepo.find({ where: { userId: user.id } }); // N queries!
}

// GOOD: Eager load relations
const users = await usersRepo.find({ relations: ['orders'] }); // 1 JOIN query

// BAD: Loading everything when you need one field
const user = await usersRepo.findOne({ where: { id } });
return user.email;

// GOOD: Select only what you need
const user = await usersRepo.findOne({ where: { id }, select: ['email'] });
```
