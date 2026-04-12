# Validation & DTOs

## Global ValidationPipe Setup (CRITICAL)

```typescript
// main.ts — always configure this
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

**`whitelist: true` is a security requirement.** Without it, clients can inject arbitrary fields
(e.g., `{ "role": "admin" }`) that pass straight through to your database layer.

## DTO Patterns

### Basic DTO with validation

```typescript
import { IsString, IsEmail, IsOptional, MinLength, MaxLength } from 'class-validator';

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

### Mapped types — avoid DTO duplication

```typescript
import { PartialType, PickType, OmitType, IntersectionType } from '@nestjs/mapped-types';
// For Swagger support, import from @nestjs/swagger instead

// All fields optional
export class UpdateUserDto extends PartialType(CreateUserDto) {}

// Only selected fields
export class LoginDto extends PickType(CreateUserDto, ['email', 'password']) {}

// All fields except some
export class PublicUserDto extends OmitType(CreateUserDto, ['password']) {}

// Combine two DTOs
export class CreateUserWithProfileDto extends IntersectionType(
  CreateUserDto,
  CreateProfileDto,
) {}
```

### Nested object validation (CRITICAL)

`@ValidateNested()` does nothing without `@Type()`. Both are always required together.

```typescript
import { ValidateNested, IsArray } from 'class-validator';
import { Type } from 'class-transformer';

export class AddressDto {
  @IsString()
  street: string;

  @IsString()
  city: string;
}

export class CreateOrderDto {
  // Single nested object
  @ValidateNested()
  @Type(() => AddressDto) // REQUIRED — without this, validation is silently skipped
  shippingAddress: AddressDto;

  // Array of nested objects
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];
}
```

### Enum validation

```typescript
import { IsEnum } from 'class-validator';

export enum OrderStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  SHIPPED = 'shipped',
}

export class UpdateOrderStatusDto {
  @IsEnum(OrderStatus)
  status: OrderStatus;
}
```

### Pagination DTO (reusable)

```typescript
import { IsOptional, IsInt, Min, Max } from 'class-validator';

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

## Separation of Concerns

DTOs handle structural/format validation only. Business validation belongs in services:

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

## Separate Request and Response DTOs

Never expose entities directly. Create dedicated response DTOs:

```typescript
// response DTO — controls what clients see
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

## Custom Validation Decorators

```typescript
import { registerDecorator, ValidationOptions, ValidationArguments } from 'class-validator';

export function IsStrongPassword(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      name: 'isStrongPassword',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: {
        validate(value: any) {
          return typeof value === 'string' &&
            value.length >= 8 &&
            /[A-Z]/.test(value) &&
            /[0-9]/.test(value) &&
            /[^A-Za-z0-9]/.test(value);
        },
        defaultMessage(args: ValidationArguments) {
          return `${args.property} must include uppercase, number, and special character`;
        },
      },
    });
  };
}
```

## Swagger Integration

Use the NestJS Swagger CLI Plugin in `nest-cli.json` to auto-generate `@ApiProperty()`:

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

For fields that need explicit Swagger metadata:

```typescript
export class CreateUserDto {
  @ApiProperty({ example: 'john@example.com', description: 'User email address' })
  @IsEmail()
  email: string;

  @ApiPropertyOptional({ enum: UserRole, default: UserRole.USER })
  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole = UserRole.USER;
}
```
