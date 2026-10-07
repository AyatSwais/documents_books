import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class SuperAdminGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();

    const user = request.user;

    if (!user?.sub) {
      throw new UnauthorizedException('يجب تسجيل الدخول أولاً');
    }

    const currentUser = await this.prisma.users.findUnique({
      where: {
        user_id: Number(user.sub),
      },
      select: {
        user_type_id: true,
      },
    });

    if (!currentUser) {
      throw new UnauthorizedException('المستخدم غير موجود');
    }

    // SuperAdmin = user_type_id IS NULL
    if (currentUser.user_type_id !== null) {
      throw new ForbiddenException('فقط SuperAdmin يستطيع إنشاء المستخدمين');
    }

    return true;
  }
}
