import { IsInt , IsArray ,IsNotEmpty ,IsPositive,ValidateNested} from "class-validator";
import { Type } from "class-transformer";
export class OutgoingItemDto
{
    @IsInt()
    @IsPositive()
    bookId :number;

    @IsInt()
    @IsPositive()
    quantity :number;

}

export class CreateOutgoingDto{
@IsInt()
@IsPositive()
toWarehouseId :number;

@IsArray()
@IsNotEmpty()
@ValidateNested({each :true})
@Type(() => OutgoingItemDto) 
items:OutgoingItemDto[];

}