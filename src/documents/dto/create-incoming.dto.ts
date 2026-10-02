import { IsInt , IsNotEmpty } from "class-validator";
export class CreateincomingDto{

    @IsInt()
    @IsNotEmpty()
    outgoingDocumentId: number;
}
