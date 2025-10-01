import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma.service';
import { Employee } from '../model/employee.model';
import { IEmployeeRepository } from './employee.repository.interface';

@Injectable()
export class EmployeePrismaRepository implements IEmployeeRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(data: {
    tenant_id: string;
    employee_no: string;
    first_name: string;
    last_name?: string | null;
    email?: string | null;
    hire_date: Date;
  }): Promise<Employee> {
    const created = await (this.prisma as any).employee.create({
      data: {
        tenant_id: data.tenant_id,
        employee_no: data.employee_no,
        first_name: data.first_name,
        last_name: data.last_name ?? null,
        email: data.email ?? null,
        hire_date: data.hire_date,
      },
    });
    return mapToEmployee(created);
  }

  async findAll(params: { tenant_id: string; page?: number; page_size?: number }): Promise<{
    data: Employee[];
    total: number;
    page: number;
    page_size: number;
  }> {
    const page = Math.max(1, params.page ?? 1);
    const page_size = Math.min(200, Math.max(1, params.page_size ?? 50));
    const skip = (page - 1) * page_size;

    const prismaAny = this.prisma as any;
    const [rows, total] = await this.prisma.$transaction([
      prismaAny.employee.findMany({
        where: { tenant_id: params.tenant_id, deleted_at: null },
        orderBy: { created_at: 'desc' },
        skip,
        take: page_size,
      }),
      prismaAny.employee.count({ where: { tenant_id: params.tenant_id, deleted_at: null } }),
    ]);

    return {
      data: rows.map(mapToEmployee),
      total,
      page,
      page_size,
    };
  }

  async findById(id: string): Promise<Employee | null> {
    const row = await (this.prisma as any).employee.findUnique({ where: { id } });
    return row ? mapToEmployee(row) : null;
  }
}

function mapToEmployee(row: any): Employee {
  return new Employee({
    id: row.id,
    tenant_id: row.tenant_id,
    entity_id: row.entity_id,
    employee_no: row.employee_no,
    first_name: row.first_name,
    last_name: row.last_name,
    email: row.email,
    nik: row.nik,
    npwp: row.npwp,
    hire_date: row.hire_date,
    created_at: row.created_at,
    updated_at: row.updated_at,
    deleted_at: row.deleted_at,
    version: row.version,
  });
}
