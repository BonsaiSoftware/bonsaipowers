# Testing

## Unit Testing

### Service test with mocked repository

```typescript
// users.service.spec.ts — co-located with source
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
            update: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get(UsersService);
    usersRepo = module.get(getRepositoryToken(User));
  });

  describe('findOneOrFail', () => {
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

    it('should throw NotFoundException when user not found', async () => {
      // Arrange
      usersRepo.findOne.mockResolvedValueOnce(null);

      // Act & Assert
      await expect(service.findOneOrFail('999')).rejects.toThrow(NotFoundException);
    });
  });

  describe('create', () => {
    it('should create and return user', async () => {
      // Arrange
      const dto: CreateUserDto = { email: 'new@test.com', name: 'New', password: 'pass123' };
      const created = { id: '2', ...dto } as User;
      usersRepo.findOne.mockResolvedValueOnce(null); // No existing user
      usersRepo.create.mockReturnValueOnce(created);
      usersRepo.save.mockResolvedValueOnce(created);

      // Act
      const result = await service.create(dto);

      // Assert
      expect(result.email).toBe(dto.email);
      expect(usersRepo.save).toHaveBeenCalled();
    });

    it('should throw ConflictException when email exists', async () => {
      // Arrange
      const existing = { id: '1', email: 'existing@test.com' } as User;
      usersRepo.findOne.mockResolvedValueOnce(existing);

      // Act & Assert
      await expect(
        service.create({ email: 'existing@test.com', name: 'X', password: 'pass' }),
      ).rejects.toThrow(ConflictException);
    });
  });
});
```

### Controller test

```typescript
describe('UsersController', () => {
  let controller: UsersController;
  let service: jest.Mocked<UsersService>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        {
          provide: UsersService,
          useValue: {
            create: jest.fn(),
            findOneOrFail: jest.fn(),
            findAll: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get(UsersController);
    service = module.get(UsersService);
  });

  it('should call service.create with dto', async () => {
    const dto: CreateUserDto = { email: 'a@b.com', name: 'A', password: 'x' };
    const expected = { id: '1', ...dto } as User;
    service.create.mockResolvedValueOnce(expected);

    const result = await controller.create(dto);
    expect(result).toEqual(expected);
    expect(service.create).toHaveBeenCalledWith(dto);
  });
});
```

### Guard test

```typescript
describe('RolesGuard', () => {
  let guard: RolesGuard;
  let reflector: Reflector;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [RolesGuard, Reflector],
    }).compile();

    guard = module.get(RolesGuard);
    reflector = module.get(Reflector);
  });

  it('should allow access when no roles required', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(undefined);
    const context = createMockExecutionContext({});
    expect(guard.canActivate(context)).toBe(true);
  });

  it('should deny access when user lacks required role', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([Role.ADMIN]);
    const context = createMockExecutionContext({ user: { roles: [Role.USER] } });
    expect(guard.canActivate(context)).toBe(false);
  });
});
```

## E2E Testing

```typescript
// test/users.e2e-spec.ts
describe('UsersController (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(DataSource) // Override real DB with test DB
      .useValue(testDataSource)
      .compile();

    app = moduleFixture.createNestApplication();
    // Apply same pipes as production
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /users', () => {
    it('should create a user', () => {
      return request(app.getHttpServer())
        .post('/users')
        .send({ email: 'test@test.com', name: 'Test', password: 'password123' })
        .expect(201)
        .expect((res) => {
          expect(res.body.email).toBe('test@test.com');
          expect(res.body.password).toBeUndefined(); // Not exposed
        });
    });

    it('should reject invalid input', () => {
      return request(app.getHttpServer())
        .post('/users')
        .send({ email: 'invalid' })
        .expect(400);
    });

    it('should reject unknown properties', () => {
      return request(app.getHttpServer())
        .post('/users')
        .send({ email: 'a@b.com', name: 'A', password: 'x', role: 'admin' })
        .expect(400); // forbidNonWhitelisted rejects 'role'
    });
  });
});
```

## TestContainers for Integration Tests

```typescript
import { PostgreSqlContainer, StartedPostgreSqlContainer } from '@testcontainers/postgresql';

describe('UsersService (integration)', () => {
  let container: StartedPostgreSqlContainer;
  let app: INestApplication;

  beforeAll(async () => {
    container = await new PostgreSqlContainer().start();

    const module = await Test.createTestingModule({
      imports: [
        TypeOrmModule.forRoot({
          type: 'postgres',
          host: container.getHost(),
          port: container.getMappedPort(5432),
          username: container.getUsername(),
          password: container.getPassword(),
          database: container.getDatabase(),
          entities: [User],
          synchronize: true, // OK for test containers
        }),
        UsersModule,
      ],
    }).compile();

    app = module.createNestApplication();
    await app.init();
  }, 60_000); // Container startup can be slow

  afterAll(async () => {
    await app.close();
    await container.stop();
  });

  // Tests with real PostgreSQL...
});
```

## What NOT to Test

- **Module definitions** — They're configuration, not logic.
- **Private methods** — Test through public API. If private logic is complex, extract to a
  separate service.
- **Framework behavior** — Don't test that `@Get()` maps to GET. Trust NestJS.
- **External libraries** — Don't test that bcrypt hashes correctly.

## Testing Conventions

- Unit tests: `*.spec.ts` co-located next to source file
- E2E tests: `*.e2e-spec.ts` in `/test` directory
- Use `describe`/`it` blocks with clear names describing behavior
- One assertion per test when possible (multiple for closely related checks)
- Use `mockResolvedValueOnce` over `mockResolvedValue` for explicit per-call control
