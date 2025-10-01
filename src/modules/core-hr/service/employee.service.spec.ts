import { Test, TestingModule } from '@nestjs/testing';
import { EMPLOYEE_REPOSITORY, EMPLOYEE_SERVICE } from '../tokens';
import { IEmployeeRepository } from '../repo/employee.repository.interface';
import { EmployeeServiceImpl } from './employee.service.impl';

describe('EmployeeServiceImpl', () => {
  let service: EmployeeServiceImpl;
  let repo: IEmployeeRepository;

  beforeEach(async () => {
    const repoMock: IEmployeeRepository = {
      async create(data) {
        return {
          id: 'e1',
          tenant_id: data.tenant_id,
          entity_id: null,
          employee_no: data.employee_no,
          first_name: data.first_name,
          last_name: data.last_name ?? null,
          email: data.email ?? null,
          nik: null,
          npwp: null,
          hire_date: data.hire_date,
          created_at: new Date(),
          updated_at: new Date(),
          deleted_at: null,
          version: 1,
        } as any;
      },
      async findAll({ tenant_id }) {
        return { data: [], total: 0, page: 1, page_size: 50 };
      },
      async findById() {
        return null;
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        { provide: EMPLOYEE_REPOSITORY, useValue: repoMock },
        { provide: EMPLOYEE_SERVICE, useClass: EmployeeServiceImpl },
      ],
    }).compile();

    service = module.get(EMPLOYEE_SERVICE);
    repo = module.get(EMPLOYEE_REPOSITORY);
  });

  it('should create employee via repo', async () => {
    const created = await service.createEmployee({
      tenant_id: 't1',
      employee_no: 'E-001',
      first_name: 'Jane',
      hire_date: new Date('2024-01-01'),
    });
    expect(created).toBeDefined();
    expect(created.employee_no).toBe('E-001');
  });

  it('should list employees', async () => {
    const result = await service.listEmployees({ tenant_id: 't1' });
    expect(result).toBeDefined();
    expect(result.page).toBe(1);
  });
});
