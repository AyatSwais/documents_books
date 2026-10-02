import {
  ConflictException,
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateUserDto } from './dto/create-user.dto.js';
import * as bcrypt from 'bcrypt';


@Injectable()
export class UsersService {
    constructor(private readonly prisma:PrismaService){}

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

    let role: string;
  let warehouseId: number | null = null;

     //...............
     // إذا تم إرسال warehouseId
  if (userData.warehouseId !== undefined) {
    const warehouse = await this.prisma.warehouses.findUnique({
      where: {
        warehouse_id: userData.warehouseId,
      },
    });

    if (!warehouse) {
      throw new NotFoundException('المستودع غير موجود');
    }

    if (warehouse.name === 'المطبعة') {
      role = 'PRINT_MANAGER';
    } else if (
      warehouse.name === 'المستودع المركزي' ||
      warehouse.name === 'المستودع الرئيسي'
    ) {
      role = 'WH_MANAGER';
    } else {
      throw new BadRequestException(
        'لا يمكن إنشاء مستخدم لهذا المستودع',
      );
    }

      warehouseId = userData.warehouseId;
  } else {
    //  نعطي الدور مبدأيا نحن عند التسجيل العادي بدون مستودع
      role = 'PRINT_MANAGER';
  
  }
  //...................................

 const user = await this.prisma.users.create({
      data: {
        name: userData.name,
        email: userData.email,
        password: hashedPassword,
        role: role,
        warehouse_id:userData.warehouseId,
      },
    });
    const {password , ... safeUser} =user;
    return safeUser;
  }
}
