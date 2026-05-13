# Primer Acceso en Producción

Después de desplegar en un servidor nuevo, ejecuta:

```bash
php artisan migrate --force
php artisan app:create-initial-admin
```

Credenciales iniciales:

- Correo: `maldonadoolave2004@gmail.com`
- Contraseña: `jonatan2004`

El comando es idempotente:

- Si ya existe un administrador, no crea otro.
- Si ya existe ese correo, lo actualiza a administrador sin duplicar usuario.

Recomendación obligatoria:

- Cambiar la contraseña inicial después del primer login.
