import {
  Controller,
  Post,
  Get,
  UseGuards,
  Body,
  Req,
} from '@nestjs/common';

import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { PermissionGuard } from '../auth/permission.guard.js';
import { Permissions } from '../auth/permissions.decorator.js';

import { DocumentsService } from './documents.service.js';
import { CreateOutgoingDto } from './dto/create-outgoing.dto.js';
import { CreateincomingDto } from './dto/create-incoming.dto.js';
import { CreateProductionDto } from './dto/create-production.dto.js';

@UseGuards(JwtAuthGuard, PermissionGuard)
@Controller('documents')
export class DocumentsController {


  constructor(
    private readonly documentsService: DocumentsService,
  ) {}

  @Permissions('CREATE_PRODUCTION')
  @Post('production')
  createBooks(
    @Body() dto: CreateProductionDto,
    @Req() req: any,
  ) {
    return this.documentsService.createbooks(req.user, dto);
  }

  @Permissions('CREATE_OUTGOING')
  @Post('outgoing')
  createOutgoing(
    @Body() dto: CreateOutgoingDto,
    @Req() req: any,
  ) {
    return this.documentsService.createoutgoing(req.user, dto);
  }

  @Permissions('CREATE_INCOMING')
  @Post('incoming')
  createIncoming(
    @Body() dto: CreateincomingDto,
    @Req() req: any,
  ) {
    return this.documentsService.createincoming(req.user, dto);
  }

  @Permissions('VIEW_MY_BALANCE')
  @Get('my-balance')
  getMyBalance(@Req() req: any) {
    return this.documentsService.getmy_balance(req.user);
  }

  @Permissions('VIEW_ALL_MOVEMENTS')
  @Get('movements')
  getMovements() {
    return this.documentsService.getmovementsbook();
  }
}


