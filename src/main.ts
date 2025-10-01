import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { exec } from 'node:child_process';

function openSwaggerInBrowser(url: string): void {
  try {
    const platform = process.platform;
    if (platform === 'win32') {
      // Use cmd's built-in 'start' to open the default browser
      exec(`cmd /c start "" "${url}"`);
    } else if (platform === 'darwin') {
      exec(`open "${url}"`);
    } else {
      exec(`xdg-open "${url}"`);
    }
  } catch {
    // ignore failures to open browser
  }
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.setGlobalPrefix('api/v1');

  const config = new DocumentBuilder()
    .setTitle('HRIS API')
    .setDescription('HRIS Backend API documentation')
    .setVersion('1.0.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        in: 'header',
        name: 'Authorization',
      },
      'bearer',
    )
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: { persistAuthorization: true },
  });

  await app.listen(process.env.PORT ?? 3000);

  // Auto-open Swagger UI in development by default (disable with AUTO_OPEN_SWAGGER=false)
  const shouldAutoOpen =
    (process.env.AUTO_OPEN_SWAGGER ?? 'true').toLowerCase() !== 'false' &&
    process.env.NODE_ENV !== 'production';
  if (shouldAutoOpen) {
    const baseUrl = (await app.getUrl()).replace(/\/$/, '');
    const docsUrl = `${baseUrl}/api/docs`;
    // Small delay to ensure the server is fully ready before opening
    setTimeout(() => openSwaggerInBrowser(docsUrl), 150);
    // Also log to console for visibility

    console.log(
      `Swagger UI: ${docsUrl} (auto-open ${shouldAutoOpen ? 'enabled' : 'disabled'})`,
    );
  }
}
bootstrap();
