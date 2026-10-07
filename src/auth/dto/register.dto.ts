import {
  IsEmail,
  IsNotEmpty,
  IsString,
  MinLength,
  IsInt,
  IsOptional,
} from 'class-validator';

export class RegisterDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  password: string;

  @IsInt()
  usertypeId: number;

  @IsInt()
  warehouseId: number;
}
