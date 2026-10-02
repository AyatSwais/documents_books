import { IsNotEmpty, IsString, IsEmail, MinLength, IsInt ,IsOptional } from 'class-validator';

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

  @IsOptional()
  @IsInt()
  warehouseId?:number;
}
