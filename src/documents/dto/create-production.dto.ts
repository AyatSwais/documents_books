import {
  IsInt,
  IsArray,
  IsNotEmpty,
  IsPositive,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
export class ProductionItemDto {
  @IsInt()
  @IsPositive()
  bookId: number;

  @IsInt()
  @IsPositive()
  quantity: number;
}

export class CreateProductionDto {
  @IsArray()
  @IsNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => ProductionItemDto)
  items: ProductionItemDto[];
}
