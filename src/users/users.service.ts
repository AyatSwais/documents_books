import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateUserDto } from './dto/create-user.dto.js';
import * as bcrypt from 'bcrypt';


@Injectable()
export class UsersService {
    constructor(private readonly prisma:PrismaService){}

  findAll() {
    return this.prisma.users.findMany();
  }
  
  async findById(id: number) {
    const user = await this.prisma.users.findUnique({
    where: {user_id: id },
    });

    if (!user) {
    throw new NotFoundException(`User with id ${id} not found`);
    }

    return user;
}
    findByEmail(email: string) {
    return this.prisma.users.findUnique({
    where: { email },
    });
  }


  async create(userData: CreateUserDto) {
    const existingUser = await this.findByEmail(userData.email);

    if (existingUser) {
      throw new ConflictException('الايميل موجود مسبقا');
    }
    const hashedPassword = await bcrypt.hash(userData.password, 10);  
    
  const user = await this.prisma.users.create({
      data: {
        name: userData.name,
        email: userData.email,
        password: hashedPassword,
        user_type_id:userData.usertypeId,
        warehouse_id:userData.warehouseId,
      },
    });
    const {password , ... safeUser} =user;
    return safeUser;
  }  
}


