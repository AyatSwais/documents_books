import { Injectable ,ForbiddenException ,NotFoundException ,BadRequestException} from '@nestjs/common';
import {CreateincomingDto} from './dto/create-incoming.dto.js';
import { CreateOutgoingDto } from './dto/create-outgoing.dto.js';
import { PrismaService } from '../prisma/prisma.service.js';
import {CreateProductionDto} from './dto/create-production.dto.js';

@Injectable()
export class DocumentsService {
    constructor(private readonly prisma :PrismaService ){}

// انشاء الصااااااااادرة ================================================

    async createoutgoing(user:any ,dto:CreateOutgoingDto){

  const fromwarehouseId=user.warehouse_id;
  const towarehouseId=dto.toWarehouseId;
  const items=dto.items;
    const warehouse = await this.prisma.warehouses.findUnique({
            where: {
                warehouse_id: towarehouseId,
    },
  });

  if (!warehouse) {
    throw new NotFoundException(
      'المستودع الهدف غير موجود',
    );
  } 
  try{ 
    const result =await this.prisma.$queryRaw<{document_id :bigint}[]>`
    SELECT create_outgoing_document(
      ${fromwarehouseId},
      ${towarehouseId},
      ${JSON.stringify(items)}:: jsonb
    ) AS document_id`;

  return { message:'تم انشاء مذكرة الصادر بنجاح',
          documentId:Number(result[0].document_id),
  };}
  catch(error:any){
    throw new BadRequestException(
      error?.meta?.driverAdapterErroe?.cause?.originalMessage??error?.message??'فشل انشاء مذكرة الصادر',
    );
  }
  
    }



// انشاء الوارد =================================================================

    async createincoming(user:any ,dto:CreateincomingDto){
    const towarehouseId=user.warehouse_id;
    
    const outgoingDocumentId =dto.outgoingDocumentId;
    try{
    const result =await this.prisma.$queryRaw<{incomingdocument_id :bigint}[]>`
    SELECT create_incoming_document(
      ${outgoingDocumentId},
      ${towarehouseId}
    ) AS incomingdocument_id
    `;
    return { message:'تم انشاء مذكرة الوارد بنجاح',
          documentId:Number(result[0].incomingdocument_id),
  };

}catch(error:any){
    throw new BadRequestException(
      error?.meta?.driverAdapterErroe?.cause?.originalMessage??error?.message??'فشل انشاء مذكرة الصادر',
    );
  }
}

//انشاء - انتاج كتب =================================================================
async createbooks(user:any ,dto:CreateProductionDto){
    const fromwarehouseId=user.warehouse_id;
    
    const items =dto.items;
    const result =await this.prisma.$queryRaw<{document_id :bigint}[]>`
    SELECT create_production(
      ${fromwarehouseId},
      ${JSON.stringify(items)}:: jsonb
      
    ) AS document_id
    `;
    return { message:' تم انتاج الكتب بالكميات المطلوبة ',
          documentId:Number(result[0].document_id),
  };
}


//============================================================

async getmovementsbook() {
  const result = await this.prisma.$queryRaw<
    {
      document_id: bigint;
      document_type: string;
      book_id: number;
      title: string;
      quantity: number;
      from_warehouse_id: number;
      from_warehouse_name: string;
      to_warehouse_id: number | null;
      to_warehouse_name: string | null;
      related_document_id: bigint | null;
      created_at: Date;
    }[]
  >` 
    SELECT *
    FROM get_movements_warehouses()`
  ;

  return {
    message: 'حركات الكتب جميعها',
    data: result.map((item) => ({
      ...item,
      document_id: item.document_id.toString(),
      related_document_id: item.related_document_id?.toString() ?? null,
    })),
  };
}
//=========================================

async getmy_balance(user: any) {
  const warehouseId = user.warehouse_id;

  if (warehouseId == null) {
    throw new ForbiddenException(
      'هذا المستخدم غير مرتبط بمستودع',
    );
  }

  const result = await this.prisma.$queryRaw<
    {
      book_id: number;
      title: string;
      quantity: bigint;
    }[]
  >`
    SELECT *
    FROM get_warehouse_book_balance(${warehouseId});`
  ;

  return {
    message: 'أرصدة الكتب في مستودعك',
    data: result.map((item) => ({
      ...item,
      quantity: item.quantity.toString(),
    })),
  };
}
}