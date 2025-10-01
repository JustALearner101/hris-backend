// Domain model for Employee (immutable-ish)
export class Employee {
  readonly id: string;
  readonly tenant_id: string;
  readonly entity_id?: string | null;
  readonly employee_no: string;
  readonly first_name: string;
  readonly last_name?: string | null;
  readonly email?: string | null;
  readonly nik?: string | null;
  readonly npwp?: string | null;
  readonly hire_date: Date;
  readonly created_at: Date;
  readonly updated_at: Date;
  readonly deleted_at?: Date | null;
  readonly version: number;

  constructor(props: {
    id: string;
    tenant_id: string;
    entity_id?: string | null;
    employee_no: string;
    first_name: string;
    last_name?: string | null;
    email?: string | null;
    nik?: string | null;
    npwp?: string | null;
    hire_date: Date;
    created_at: Date;
    updated_at: Date;
    deleted_at?: Date | null;
    version: number;
  }) {
    this.id = props.id;
    this.tenant_id = props.tenant_id;
    this.entity_id = props.entity_id ?? null;
    this.employee_no = props.employee_no;
    this.first_name = props.first_name;
    this.last_name = props.last_name ?? null;
    this.email = props.email ?? null;
    this.nik = props.nik ?? null;
    this.npwp = props.npwp ?? null;
    this.hire_date = props.hire_date;
    this.created_at = props.created_at;
    this.updated_at = props.updated_at;
    this.deleted_at = props.deleted_at ?? null;
    this.version = props.version;
  }
}
