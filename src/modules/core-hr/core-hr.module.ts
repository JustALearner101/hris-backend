import { Module } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma.service';
import { EmployeeController } from './controller/employee.controller';
import { EmployeePrismaRepository } from './repo/employee.prisma.repository';
import { EmployeeServiceImpl } from './service/employee.service.impl';
import { EMPLOYEE_REPOSITORY, EMPLOYEE_SERVICE } from './tokens';

@Module({
  controllers: [EmployeeController],
  providers: [
    PrismaService,
    { provide: EMPLOYEE_REPOSITORY, useClass: EmployeePrismaRepository },
    { provide: EMPLOYEE_SERVICE, useClass: EmployeeServiceImpl },
  ],
  exports: [EMPLOYEE_SERVICE],
})
export class CoreHrModule {}
