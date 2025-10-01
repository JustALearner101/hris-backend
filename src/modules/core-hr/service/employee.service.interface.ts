import { Employee } from '../model/employee.model';

export interface IEmployeeService {
  createEmployee(input: {
    tenant_id: string;
    employee_no: string;
    first_name: string;
    last_name?: string | null;
    email?: string | null;
    hire_date: Date;
  }): Promise<Employee>;

  listEmployees(params: { tenant_id: string; page?: number; page_size?: number }): Promise<{
    data: Employee[];
    total: number;
    page: number;
    page_size: number;
  }>;

  getEmployeeById(id: string): Promise<Employee | null>;
}
