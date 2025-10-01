import { IsDateString, IsEmail, IsOptional, IsString, Length } from 'class-validator';

export class CreateEmployeeDto {
  @IsString()
  tenant_id!: string;

  @IsString()
  @Length(1, 64)
  employee_no!: string;

  @IsString()
  @Length(1, 100)
  first_name!: string;

  @IsOptional()
  @IsString()
  @Length(0, 100)
  last_name?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsDateString()
  hire_date!: string; // ISO date string
}
