# Alertas automáticas de seguridad

La API envía alertas cuando detecta comportamiento sospechoso:

- Múltiples logins fallidos desde la misma IP en 10 minutos.
- Exceso de intentos bloqueados por `throttle` en login/recuperación.

## Configuración

En `.env` de producción define:

```env
SECURITY_ALERT_RECIPIENTS=duena@empresa.com,tu-correo@dominio.com
TELEGRAM_BOT_TOKEN=123456789:ABCDEF...
TELEGRAM_CHAT_IDS=123456789,987654321
LOG_SECURITY_LEVEL=info
LOG_SECURITY_DAYS=30
```

Nota para Telegram:

- Crea el bot con `@BotFather` y copia el `TELEGRAM_BOT_TOKEN`.
- Escribe al bot al menos una vez desde tu Telegram.
- Obtén tu `chat_id` con:
  `https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/getUpdates`
- Puedes poner varios `chat_id` separados por coma.

## Dónde se registran

- Archivo: `storage/logs/security-YYYY-MM-DD.log` (canal `security`).

## Qué hacer al recibir alerta

1. Revisar IP y ruta reportadas.
2. Bloquear IP en firewall si es ataque.
3. Revocar sesiones/tokens de usuario comprometido.
4. Forzar cambio de contraseña para cuentas sensibles.
