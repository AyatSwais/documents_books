import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';

import { Reflector } from '@nestjs/core';
import { PrismaService } from '../prisma/prisma.service.js';
import { PERMISSIONS_KEY } from './permissions.decorator.js';

@Injectable()
export class PermissionGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredPermissions =
      this.reflector.getAllAndOverride<string[]>(
        PERMISSIONS_KEY,
        [context.getHandler(), context.getClass()],
      );

    if (!requiredPermissions || requiredPermissions.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user?.sub) {
      throw new UnauthorizedException('يجب تسجيل الدخول أولاً');
    }

    // جلب المستخدم ودوره الحالي من قاعدة البيانات
    const currentUser = await this.prisma.users.findUnique({
      where: {
        user_id: Number(user.sub),
      },
      select: {
        user_id: true,
        user_type_id: true,
      },
    });

    if (!currentUser) {
      throw new UnauthorizedException('المستخدم غير موجود');
    }

    // إذا لم يكن لديه دور، نعتبره SuperAdmin
    if (currentUser.user_type_id === null) {
      return true;
    }

    // جلب الصلاحيات المرتبطة بدور المستخدم
    const result = await this.prisma.$queryRaw<
      { permission_name: string }[]
    >`
      SELECT DISTINCT p.name AS permission_name
      FROM role_permissions rp
      JOIN permissions p
        ON p.permission_id = rp.permission_id
      WHERE rp.user_type_id = ${currentUser.user_type_id}`
    ;

    const userPermissions = result.map(
      (item) => item.permission_name,
    );

    const hasAllPermissions = requiredPermissions.every(
      (permission) => userPermissions.includes(permission),
    );

    if (!hasAllPermissions) {
      throw new ForbiddenException(
        'ليس لديك الصلاحيات اللازمة لتنفيذ هذا الإجراء',
      );
    }

    return true;
  }
}