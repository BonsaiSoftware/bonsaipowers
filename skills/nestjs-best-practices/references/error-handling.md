# Error Handling

## Global Exception Filter

Register via module providers for proper dependency injection support:

```typescript
// common/filters/all-exceptions.filter.ts
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

    // Log full error in development, sanitized in production
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
    // Hide internal errors from clients
    return { status: 500, message: 'Internal server error' };
  }
}

// Register in AppModule — NOT with app.useGlobalFilters()
@Module({
  providers: [
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
  ],
})
export class AppModule {}
```

## Built-in HTTP Exceptions

Use these instead of raw `new HttpException()`:

```typescript
throw new BadRequestException('Invalid input');          // 400
throw new UnauthorizedException('Invalid credentials');  // 401
throw new ForbiddenException('Insufficient permissions');// 403
throw new NotFoundException('User not found');           // 404
throw new ConflictException('Email already exists');     // 409
throw new UnprocessableEntityException('Invalid data');  // 422
throw new InternalServerErrorException();                // 500
```

## Domain-Specific Exceptions

For business logic errors with structured error codes:

```typescript
// common/exceptions/business.exception.ts
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
    super(
      'INSUFFICIENT_BALANCE',
      `Required ${required}, available ${available}`,
      HttpStatus.UNPROCESSABLE_ENTITY,
    );
  }
}

// Usage in service
throw new InsufficientBalanceException(order.total, user.balance);
```

## Anti-patterns

```typescript
// BAD: Wrapping every method in try-catch — let filters handle it
@Get(':id')
async findOne(@Param('id') id: string) {
  try {
    return await this.service.findOne(id);
  } catch (error) {
    throw new InternalServerErrorException(error.message);
  }
}

// GOOD: Throw specific exceptions in service, let filter catch the rest
@Get(':id')
findOne(@Param('id', ParseUUIDPipe) id: string) {
  return this.service.findOneOrFail(id);
}

// BAD: Exposing stack traces or internal details
throw new HttpException(error.stack, 500);

// BAD: Catching and swallowing errors silently
try { await dangerous(); } catch {} // Never do this
```

## Error Response Shape

Maintain a consistent shape across all endpoints:

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

ValidationPipe already returns `message` as an array of validation errors. Match this format
in your custom filter for consistency.
