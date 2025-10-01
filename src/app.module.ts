import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { CoreHrModule } from './modules/core-hr/core-hr.module';

@Module({
  imports: [CoreHrModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
