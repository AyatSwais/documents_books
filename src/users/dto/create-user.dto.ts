import {
  IsNotEmpty,
  IsString,
  IsEmail,
  MinLength,
  IsInt,
} from 'class-validator';

export class CreateUserDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsEmail()
  @IsNotEmpty()
  email: string;

  @MinLength(6)
  @IsString()
  @IsNotEmpty()
  password: string;

  @IsInt()
  usertypeId: number;

  @IsInt()
  warehouseId: number;
}
