# Mantenimiento Seguro: Archivo Histórico (Facturas y Cotizaciones)

Este proyecto incluye el comando:

`php artisan maintenance:archive-business-data`

## Qué hace

- Busca facturas y cotizaciones antiguas (por defecto, mayores a 5 años).
- Genera archivos `.ndjson` recuperables por tabla en `storage/app/archives/...`.
- Si se ejecuta con `--execute`, después del archivo limpia esos registros en producción.

Tablas incluidas:

- `facturas`
- `factura_items`
- `cotizaciones`
- `cotizacion_detalles`

## Regla de seguridad

Por defecto es **simulación** (no borra nada).  
Solo limpia datos si agregas `--execute`.

## Uso recomendado

### 1) Simulación (obligatoria)

```bash
php artisan maintenance:archive-business-data --years=5
```

Esto solo muestra cuántos registros movería.

### 2) Ejecución real (cuando ya validaste)

```bash
php artisan maintenance:archive-business-data --years=5 --execute
```

Esto:

1. Exporta históricos a `storage/app/archives/archive_YYYYMMDD_HHMMSS/`
2. Limpia los registros ya archivados.

## Recomendación operativa

Antes de ejecutar en producción:

1. Realiza backup completo de base de datos.
2. Ejecuta simulación y revisa conteos.
3. Ejecuta con `--execute`.
4. Verifica dashboard/comparativos.
