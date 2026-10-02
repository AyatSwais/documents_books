import { CreateOutgoingDto } from './dto/create-outgoing.dto.js'
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { RolesGuard } from '../auth/roles.guard.js';
import { Roles } from '../auth/roles.decorator.js';
import {DocumentsService} from './documents.service.js';
import {CreateincomingDto} from './dto/create-incoming.dto.js';
import {CreateProductionDto} from './dto/create-production.dto.js';

import {
    Controller ,
    Post,
    UseGuards ,
    Body,
    Req,
    Get } 
from '@nestjs/common';


@UseGuards(JwtAuthGuard)
@Controller('documents')
export class DocumentsController {
    constructor(private readonly documentsService:DocumentsService){}


  @Roles('PRINT_MANAGER', 'WH_MANAGER')
  @UseGuards(RolesGuard)
  @Post('outgoing')
  createout(@Body() dto: CreateOutgoingDto , @Req() req:any) {
    return this.documentsService.createoutgoing(req.user,dto);
  }


  @Roles('WH_MANAGER')
  @UseGuards(RolesGuard)
  @Post('incoming')
  createin(@Body() dto: CreateincomingDto ,@Req() req:any) {
    return this.documentsService.createincoming(req.user,dto);
  }
  
  @Roles('PRINT_MANAGER')
  @UseGuards(RolesGuard)
  @Post('productbooks')
  creatbooks(@Body() dto: CreateProductionDto , @Req() req:any) {
    return this.documentsService.createbooks(req.user , dto);
  }





  //============================================


//عرض جميع حركات الكتب من الادمن 
  @Roles('SUPER_ADMIN')
  @UseGuards(RolesGuard)
  @Get('movements')
  getMovementswarehouses () {
    return this.documentsService.getmovementsbook();
  }


  @Roles('WH_MANAGER','PRINT_MANAGER')
  @UseGuards(RolesGuard)
  @Get('mybalance')
  get_my_balance(@Req() req:any) {
    return this.documentsService.getmy_balance(req.user);
  }


}
