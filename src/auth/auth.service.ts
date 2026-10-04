import { Injectable ,UnauthorizedException } from '@nestjs/common';
import { RegisterDto } from './dto/register.dto.js';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service.js';
import { LoginDto } from './dto/login.dto.js';
import * as bcrypt from 'bcrypt';


@Injectable()
export class AuthService {

constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
) {}

async register(registerDto: RegisterDto) {
    const user = await this.usersService.create(registerDto);

    

    return {
    message: 'تم التسجيل بنجاح ',
    user: user,
    };
}

async login(loginDto: LoginDto) {

    const user = await this.usersService.findByEmail(loginDto.email);

if (!user) {
throw new UnauthorizedException('كلمة مرور او ايميل غير صحيحة ');
}

const isPasswordValid = await bcrypt.compare(loginDto.password, user.password,);

if (!isPasswordValid) {
throw new UnauthorizedException('كلمة مرور او ايميل غير صحيحة ');
}

    const payload = {
    sub: user.user_id,
    email: user.email,
    warehouse_id :user.warehouse_id,
    };

    const accessToken = this.jwtService.sign(payload);

    return {
    message: 'دخوول ناجح',
    accessToken,
    };
}

}
