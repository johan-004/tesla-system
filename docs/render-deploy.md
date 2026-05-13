# Deploy Laravel API en Render (Docker)

Esta guía deja tu backend Laravel listo para producción en Render usando:

- `Language`: `Docker`
- `Dockerfile Path`: `./Dockerfile`

## 1. Crear el servicio en Render

1. Entra a Render y conecta tu repositorio de GitHub.
2. Crea un `Web Service`.
3. Selecciona:
   - `Language`: `Docker`
   - `Dockerfile Path`: `./Dockerfile`
4. Deploy inicial.

Render inyecta la variable `PORT` automáticamente y el contenedor ya está preparado para escuchar en ese puerto.

## 2. Variables de entorno en Render

En `Environment` agrega, como mínimo:

- `APP_NAME=Tesla-system`
- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_URL=https://TU-SERVICIO.onrender.com`
- `APP_KEY=base64:...` (générala con `php artisan key:generate --show`)
- `LOG_CHANNEL=stack`
- `LOG_LEVEL=info`
- `DB_CONNECTION=mysql`
- `DB_HOST=...`
- `DB_PORT=3306`
- `DB_DATABASE=...`
- `DB_USERNAME=...`
- `DB_PASSWORD=...`
- `SESSION_DRIVER=database`
- `SESSION_SECURE_COOKIE=true`
- `SECURITY_ALERT_RECIPIENTS=proyecciones.tesla@gmail.com`
- Variables de correo SMTP (`MAIL_*`) para recuperación de contraseña y alertas.

No subas `.env` al repositorio. Todo se configura en Render.

## 3. Ejecutar migraciones en producción

En Render, abre `Shell` del servicio y ejecuta:

```bash
php artisan migrate --force
```

## 4. Crear el administrador inicial

En el mismo Shell de Render:

```bash
php artisan app:create-initial-admin
```

## 5. Probar login inicial

Con la app Flutter apuntando a tu `APP_URL` de Render:

1. Inicia sesión con el admin inicial.
2. Verifica que puedes entrar al dashboard.
3. Crea una cotización.
4. Crea/emite una factura.
5. Prueba recuperación de contraseña y confirma que llega el correo.

Recomendación: cambia la contraseña inicial del admin inmediatamente después del primer login.
