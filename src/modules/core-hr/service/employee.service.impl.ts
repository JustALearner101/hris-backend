import { Inject, Injectable } from '@nestjs/common';
import { Employee } from '../model/employee.model';
import * as employeeRepositoryInterface from '../repo/employee.repository.interface';
import { EMPLOYEE_REPOSITORY } from '../tokens';
import { IEmployeeService } from './employee.service.interface';

@Injectable()
export class EmployeeServiceImpl implements IEmployeeService {
  constructor(
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly repo: employeeRepositoryInterface.IEmployeeRepository,
  ) {}

  async createEmployee(input: {
    tenant_id: string;
    employee_no: string;
    first_name: string;
    last_name?: string | null;
    email?: string | null;
    hire_date: Date;
  }): Promise<Employee> {
    // example: could add business rules here (ensure unique, etc.)
    return this.repo.create(input);
  }

  async listEmployees(params: {
    tenant_id: string;
    page?: number | undefined;
    page_size?: number | undefined;
  }): Promise<{
    data: Employee[];
    total: number;
    page: number;
    page_size: number;
  }> {
    return this.repo.findAll(params);
  }

  async getEmployeeById(id: string): Promise<Employee | null> {
    return this.repo.findById(id);
  }
}
