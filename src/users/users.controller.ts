
import { CreateUserDto } from './dto/create-user.dto.js';
import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { UsersService } from './users.service.js';
import {SuperAdminGuard} from '../auth/super-admin.guard.js';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}


   @UseGuards(SuperAdminGuard)
   @Get()
  async findAll() {
    const users = await this.usersService.findAll();

    return users.map(({ password, ...user }) => user);
  }
  @UseGuards(SuperAdminGuard)
  @Get(':id')
  async findById(@Param('id', ParseIntPipe) id: number) {
    const user = await this.usersService.findById(id);

    const { password, ...safeUser } = user;

    return safeUser;
  }
  
  @UseGuards(SuperAdminGuard)
  @Post()
  create(@Body() userData: CreateUserDto) {
    return this.usersService.create(userData);
  }
}