import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { EMPLOYEE_SERVICE } from '../tokens';
import * as employeeServiceInterface from '../service/employee.service.interface';
import { Inject } from '@nestjs/common';
import { CreateEmployeeDto } from '../dto/create-employee.dto';

@Controller('employees')
export class EmployeeController {
  constructor(
    @Inject(EMPLOYEE_SERVICE)
    private readonly employeeService: employeeServiceInterface.IEmployeeService,
  ) {}

  @Post()
  async create(@Body() dto: CreateEmployeeDto) {
    const created = await this.employeeService.createEmployee({
      tenant_id: dto.tenant_id,
      employee_no: dto.employee_no,
      first_name: dto.first_name,
      last_name: dto.last_name ?? null,
      email: dto.email ?? null,
      hire_date: new Date(dto.hire_date),
    });
    return created; // for simplicity, return domain model (ideally map to response DTO)
  }

  @Get()
  async list(
    @Query('tenant_id') tenantId: string,
    @Query('page') page?: string,
    @Query('page_size') pageSize?: string,
  ) {
    const result = await this.employeeService.listEmployees({
      tenant_id: tenantId,
      page: page ? Number(page) : undefined,
      page_size: pageSize ? Number(pageSize) : undefined,
    });
    return result;
  }
}
