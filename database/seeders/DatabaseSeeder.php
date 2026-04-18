<?php

namespace Database\Seeders;

use App\Models\CategoriaServicio;
use App\Models\Cliente;
use App\Models\Cotizacion;
use App\Models\Producto;
use App\Models\Servicio;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $admin = User::query()
            ->where('email', 'admin@tesla-system.test')
            ->first();

        Producto::updateOrCreate(
            ['codigo' => 'MAT-001'],
            [
                'nombre' => 'Cable de cobre',
                'descripcion' => 'Material reutilizado como base del módulo de productos.',
                'precio_compra' => 12000,
                'precio_venta' => 18500,
                'stock' => 25,
                'unidad_medida' => 'metro',
                'activo' => true,
            ]
        );

        $catalogoProductos = [
            ['codigo' => 'MAT-002', 'nombre' => 'Conector industrial', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-003', 'nombre' => 'Breaker termico', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-004', 'nombre' => 'Canaleta PVC', 'unidad_medida' => 'metro'],
            ['codigo' => 'MAT-005', 'nombre' => 'Toma corriente doble', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-006', 'nombre' => 'Interruptor sencillo', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-007', 'nombre' => 'Tablero de distribucion', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-008', 'nombre' => 'Tuberia EMT 1/2', 'unidad_medida' => 'metro'],
            ['codigo' => 'MAT-009', 'nombre' => 'Curva EMT 1/2', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-010', 'nombre' => 'Caja metalica 2x4', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-011', 'nombre' => 'Bombillo led 12W', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-012', 'nombre' => 'Reflector led exterior', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-013', 'nombre' => 'Sensor de movimiento', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-014', 'nombre' => 'Cable encauchetado', 'unidad_medida' => 'metro'],
            ['codigo' => 'MAT-015', 'nombre' => 'Terminal ojo', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-016', 'nombre' => 'Prensaestopa', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-017', 'nombre' => 'Tomacorriente industrial', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-018', 'nombre' => 'Contactor 220V', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-019', 'nombre' => 'Rele termico', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-020', 'nombre' => 'Riel DIN', 'unidad_medida' => 'metro'],
            ['codigo' => 'MAT-021', 'nombre' => 'Bornera paso', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-022', 'nombre' => 'Etiquetas de cableado', 'unidad_medida' => 'set'],
            ['codigo' => 'MAT-023', 'nombre' => 'Abrazadera metalica', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-024', 'nombre' => 'Cinta aislante', 'unidad_medida' => 'unidad'],
            ['codigo' => 'MAT-025', 'nombre' => 'Canaleta ranurada', 'unidad_medida' => 'metro'],
        ];

        foreach ($catalogoProductos as $index => $producto) {
            Producto::updateOrCreate(
                ['codigo' => $producto['codigo']],
                [
                    'nombre' => $producto['nombre'],
                    'descripcion' => 'Producto de prueba para búsquedas, paginación y estados.',
                    'precio_compra' => 5000 + (($index + 1) * 1200),
                    'precio_venta' => 8000 + (($index + 1) * 1800),
                    'stock' => ($index % 6 === 0) ? 3 : 8 + $index,
                    'unidad_medida' => $producto['unidad_medida'],
                    'activo' => $index % 5 !== 0,
                ]
            );
        }

        Cliente::updateOrCreate(
            ['documento' => '900100200'],
            [
                'nombre' => 'Cliente Demo SAS',
                'telefono' => '3000000000',
                'email' => 'cliente@demo.test',
                'direccion' => 'Calle 123 #45-67',
                'notas' => 'Cliente base para pruebas.',
                'activo' => true,
                'created_by' => $admin?->id,
            ]
        );

        Cotizacion::updateOrCreate(
            ['numero' => 'COT-2026-000001'],
            [
                'codigo' => 'COT-2026-000001',
                'item' => 1,
                'obra' => 'Obra demo',
                'descripcion' => 'Cotizacion demo inicial',
                'unidad' => 'unidad',
                'fecha' => now()->toDateString(),
                'ciudad' => 'Villavicencio',
                'cliente_nombre' => 'Cliente Demo',
                'cliente_nit' => '123456789',
                'cliente_contacto' => 'Juan Perez',
                'cliente_cargo' => 'Administrador',
                'cliente_direccion' => 'Dirección demo',
                'referencia' => 'Cotización demo inicial',
                'subtotal' => 0,
                'total' => 0,
                'impuestos' => 0,
                'estado' => 'pendiente',
                'created_by' => $admin?->id,
                'updated_by' => $admin?->id,
                'user_id' => $admin?->id,
            ]
        );

        $categoriasServicio = [
            'residencial',
            'comercial',
            'industrial',
            'mantenimiento y emergencias',
        ];

        $categoriaIds = [];
        foreach ($categoriasServicio as $nombreCategoria) {
            $categoria = CategoriaServicio::updateOrCreate(
                ['nombre' => $nombreCategoria],
                [
                    'descripcion' => 'Categoría operativa del catálogo de servicios.',
                    'activo' => true,
                ]
            );

            $categoriaIds[$nombreCategoria] = $categoria->id;
        }

        $categoriaResidencialId = $categoriaIds['residencial'];
        $categoriaInstalaciones = CategoriaServicio::query()
            ->whereRaw('LOWER(TRIM(nombre)) = ?', ['instalaciones'])
            ->first();

        Servicio::query()
            ->whereRaw('LOWER(TRIM(categoria)) = ?', ['instalaciones'])
            ->update([
                'categoria' => 'residencial',
                'categoria_servicio_id' => $categoriaResidencialId,
            ]);

        if ($categoriaInstalaciones !== null) {
            Servicio::query()
                ->where('categoria_servicio_id', $categoriaInstalaciones->id)
                ->update([
                    'categoria' => 'residencial',
                    'categoria_servicio_id' => $categoriaResidencialId,
                ]);

            $categoriaInstalaciones->delete();
        }

        $catalogoServicios = [
            [
                'codigo' => 'RE-001',
                'descripcion' => 'Instalación de tomacorriente sencillo (monofásico)',
                'categoria' => 'residencial',
                'unidad' => 'Punto',
                'precio_unitario' => 85000,
                'iva' => 16150,
                'precio_con_iva' => 101150,
                'observaciones' => '',
            ],
            [
                'codigo' => 'RE-002',
                'descripcion' => 'Instalación de tomacorriente doble (monofásico)',
                'categoria' => 'residencial',
                'unidad' => 'Punto',
                'precio_unitario' => 120000,
                'iva' => 22800,
                'precio_con_iva' => 142800,
                'observaciones' => '',
            ],
            [
                'codigo' => 'RE-003',
                'descripcion' => 'Instalación de tomacorriente GFCI (protección humedad)',
                'categoria' => 'residencial',
                'unidad' => 'Punto',
                'precio_unitario' => 145000,
                'iva' => 27550,
                'precio_con_iva' => 172550,
                'observaciones' => '',
            ],
            [
                'codigo' => 'RE-004',
                'descripcion' => 'Instalación de interruptor sencillo',
                'categoria' => 'residencial',
                'unidad' => 'Punto',
                'precio_unitario' => 75000,
                'iva' => 14250,
                'precio_con_iva' => 89250,
                'observaciones' => '',
            ],
            [
                'codigo' => 'RE-005',
                'descripcion' => 'Instalación de interruptor conmutado (3 vías)',
                'categoria' => 'residencial',
                'unidad' => 'Punto',
                'precio_unitario' => 110000,
                'iva' => 20900,
                'precio_con_iva' => 130900,
                'observaciones' => '',
            ],
            [
                'codigo' => 'RE-006',
                'descripcion' => 'Instalación de punto de iluminación (cableado + caja)',
                'categoria' => 'residencial',
                'unidad' => 'Punto',
                'precio_unitario' => 130000,
                'iva' => 24700,
                'precio_con_iva' => 154700,
                'observaciones' => '',
            ],
            [
                'codigo' => 'RE-007',
                'descripcion' => 'Instalación de tablero de distribución 4-8 circuitos',
                'categoria' => 'residencial',
                'unidad' => 'Unidad',
                'precio_unitario' => 650000,
                'iva' => 123500,
                'precio_con_iva' => 773500,
                'observaciones' => 'Incluye mano de obra, sin materiales',
            ],
            [
                'codigo' => 'RE-008',
                'descripcion' => 'Canalización eléctrica en tubería PVC (por metro)',
                'categoria' => 'residencial',
                'unidad' => 'Metro',
                'precio_unitario' => 35000,
                'iva' => 6650,
                'precio_con_iva' => 41650,
                'observaciones' => '',
            ],
            [
                'codigo' => 'RE-009',
                'descripcion' => 'Puesta a tierra residencial (varilla + cable)',
                'categoria' => 'residencial',
                'unidad' => 'Global',
                'precio_unitario' => 480000,
                'iva' => 91200,
                'precio_con_iva' => 571200,
                'observaciones' => 'Incluye varilla copperweld 5/8"',
            ],
            [
                'codigo' => 'RE-010',
                'descripcion' => 'Revisión y certificación instalación eléctrica residencial',
                'categoria' => 'residencial',
                'unidad' => 'Global',
                'precio_unitario' => 350000,
                'iva' => 66500,
                'precio_con_iva' => 416500,
                'observaciones' => '',
            ],
            [
                'codigo' => 'CO-001',
                'descripcion' => 'Instalación de tomacorriente trifásico industrial',
                'categoria' => 'comercial',
                'unidad' => 'Punto',
                'precio_unitario' => 220000,
                'iva' => 41800,
                'precio_con_iva' => 261800,
                'observaciones' => '',
            ],
            [
                'codigo' => 'CO-002',
                'descripcion' => 'Instalación de tablero bifásico/trifásico 12-24 circuitos',
                'categoria' => 'comercial',
                'unidad' => 'Unidad',
                'precio_unitario' => 1350000,
                'iva' => 256500,
                'precio_con_iva' => 1606500,
                'observaciones' => '',
            ],
            [
                'codigo' => 'CO-003',
                'descripcion' => 'Instalación de sistema de iluminación LED comercial',
                'categoria' => 'comercial',
                'unidad' => 'Punto',
                'precio_unitario' => 180000,
                'iva' => 34200,
                'precio_con_iva' => 214200,
                'observaciones' => '',
            ],
            [
                'codigo' => 'CO-004',
                'descripcion' => 'Cableado estructurado eléctrico por bandeja portacable',
                'categoria' => 'comercial',
                'unidad' => 'Metro',
                'precio_unitario' => 55000,
                'iva' => 10450,
                'precio_con_iva' => 65450,
                'observaciones' => '',
            ],
            [
                'codigo' => 'CO-005',
                'descripcion' => 'Instalación de UPS / sistema de respaldo eléctrico',
                'categoria' => 'comercial',
                'unidad' => 'Unidad',
                'precio_unitario' => 850000,
                'iva' => 161500,
                'precio_con_iva' => 1011500,
                'observaciones' => '',
            ],
            [
                'codigo' => 'CO-006',
                'descripcion' => 'Instalación de planta eléctrica (hasta 25 kVA)',
                'categoria' => 'comercial',
                'unidad' => 'Global',
                'precio_unitario' => 2800000,
                'iva' => 532000,
                'precio_con_iva' => 3332000,
                'observaciones' => 'Instalación sin incluir planta',
            ],
            [
                'codigo' => 'CO-007',
                'descripcion' => 'Mantenimiento preventivo tablero eléctrico comercial',
                'categoria' => 'comercial',
                'unidad' => 'Global',
                'precio_unitario' => 480000,
                'iva' => 91200,
                'precio_con_iva' => 571200,
                'observaciones' => '',
            ],
            [
                'codigo' => 'CO-008',
                'descripcion' => 'Diagnóstico termográfico de instalaciones eléctricas',
                'categoria' => 'comercial',
                'unidad' => 'Global',
                'precio_unitario' => 950000,
                'iva' => 180500,
                'precio_con_iva' => 1130500,
                'observaciones' => 'Incluye informe termográfico PDF',
            ],
            [
                'codigo' => 'CO-009',
                'descripcion' => 'Instalación sistema de protección contra descargas (DPS)',
                'categoria' => 'comercial',
                'unidad' => 'Global',
                'precio_unitario' => 780000,
                'iva' => 148200,
                'precio_con_iva' => 928200,
                'observaciones' => '',
            ],
            [
                'codigo' => 'IN-001',
                'descripcion' => 'Instalación de motor eléctrico trifásico (hasta 25 HP)',
                'categoria' => 'industrial',
                'unidad' => 'Unidad',
                'precio_unitario' => 1200000,
                'iva' => 228000,
                'precio_con_iva' => 1428000,
                'observaciones' => '',
            ],
            [
                'codigo' => 'IN-002',
                'descripcion' => 'Instalación de variador de frecuencia (VFD)',
                'categoria' => 'industrial',
                'unidad' => 'Unidad',
                'precio_unitario' => 1800000,
                'iva' => 342000,
                'precio_con_iva' => 2142000,
                'observaciones' => '',
            ],
            [
                'codigo' => 'IN-003',
                'descripcion' => 'Instalación de arrancador suave',
                'categoria' => 'industrial',
                'unidad' => 'Unidad',
                'precio_unitario' => 1500000,
                'iva' => 285000,
                'precio_con_iva' => 1785000,
                'observaciones' => '',
            ],
            [
                'codigo' => 'IN-004',
                'descripcion' => 'Montaje de tablero de control y fuerza',
                'categoria' => 'industrial',
                'unidad' => 'Unidad',
                'precio_unitario' => 3500000,
                'iva' => 665000,
                'precio_con_iva' => 4165000,
                'observaciones' => '',
            ],
            [
                'codigo' => 'IN-005',
                'descripcion' => 'Instalación de transformador (hasta 150 kVA)',
                'categoria' => 'industrial',
                'unidad' => 'Unidad',
                'precio_unitario' => 4200000,
                'iva' => 798000,
                'precio_con_iva' => 4998000,
                'observaciones' => 'Incluye pruebas de puesta en marcha',
            ],
            [
                'codigo' => 'IN-006',
                'descripcion' => 'Tendido de cable de media tensión (por metro)',
                'categoria' => 'industrial',
                'unidad' => 'Metro',
                'precio_unitario' => 125000,
                'iva' => 23750,
                'precio_con_iva' => 148750,
                'observaciones' => '',
            ],
            [
                'codigo' => 'IN-007',
                'descripcion' => 'Mantenimiento preventivo sistema eléctrico industrial',
                'categoria' => 'industrial',
                'unidad' => 'Global',
                'precio_unitario' => 2200000,
                'iva' => 418000,
                'precio_con_iva' => 2618000,
                'observaciones' => '',
            ],
            [
                'codigo' => 'IN-008',
                'descripcion' => 'Puesta a tierra industrial (red equipotencial)',
                'categoria' => 'industrial',
                'unidad' => 'Global',
                'precio_unitario' => 1650000,
                'iva' => 313500,
                'precio_con_iva' => 1963500,
                'observaciones' => '',
            ],
            [
                'codigo' => 'IN-009',
                'descripcion' => 'Instalación iluminación industrial LED alta bahía',
                'categoria' => 'industrial',
                'unidad' => 'Punto',
                'precio_unitario' => 420000,
                'iva' => 79800,
                'precio_con_iva' => 499800,
                'observaciones' => '',
            ],
            [
                'codigo' => 'IN-010',
                'descripcion' => 'Automatización básica PLC (programación + cableado)',
                'categoria' => 'industrial',
                'unidad' => 'Global',
                'precio_unitario' => 5500000,
                'iva' => 1045000,
                'precio_con_iva' => 6545000,
                'observaciones' => 'Hasta 10 entradas/salidas digitales',
            ],
            [
                'codigo' => 'MT-001',
                'descripcion' => 'Visita técnica de diagnóstico eléctrico',
                'categoria' => 'mantenimiento y emergencias',
                'unidad' => 'Visita',
                'precio_unitario' => 180000,
                'iva' => 34200,
                'precio_con_iva' => 214200,
                'observaciones' => '',
            ],
            [
                'codigo' => 'MT-002',
                'descripcion' => 'Mantenimiento preventivo instalación residencial',
                'categoria' => 'mantenimiento y emergencias',
                'unidad' => 'Global',
                'precio_unitario' => 280000,
                'iva' => 53200,
                'precio_con_iva' => 333200,
                'observaciones' => '',
            ],
            [
                'codigo' => 'MT-003',
                'descripcion' => 'Servicio de emergencia 24/7 (recargo nocturno incluido)',
                'categoria' => 'mantenimiento y emergencias',
                'unidad' => 'Hora',
                'precio_unitario' => 220000,
                'iva' => 41800,
                'precio_con_iva' => 261800,
                'observaciones' => 'Hora mínima 2 horas',
            ],
            [
                'codigo' => 'MT-004',
                'descripcion' => 'Identificación y corrección de fallas eléctricas',
                'categoria' => 'mantenimiento y emergencias',
                'unidad' => 'Global',
                'precio_unitario' => 320000,
                'iva' => 60800,
                'precio_con_iva' => 380800,
                'observaciones' => '',
            ],
            [
                'codigo' => 'MT-005',
                'descripcion' => 'Reemplazo de breakers / interruptores termomagnéticos',
                'categoria' => 'mantenimiento y emergencias',
                'unidad' => 'Unidad',
                'precio_unitario' => 95000,
                'iva' => 18050,
                'precio_con_iva' => 113050,
                'observaciones' => '',
            ],
            [
                'codigo' => 'MT-006',
                'descripcion' => 'Medición de aislamiento (megger) y reporte',
                'categoria' => 'mantenimiento y emergencias',
                'unidad' => 'Global',
                'precio_unitario' => 350000,
                'iva' => 66500,
                'precio_con_iva' => 416500,
                'observaciones' => '',
            ],
            [
                'codigo' => 'MT-007',
                'descripcion' => 'Análisis de calidad de energía (armónicos, THD)',
                'categoria' => 'mantenimiento y emergencias',
                'unidad' => 'Global',
                'precio_unitario' => 1200000,
                'iva' => 228000,
                'precio_con_iva' => 1428000,
                'observaciones' => 'Incluye analizador portátil y reporte',
            ],
        ];

        Servicio::query()->where('codigo', 'SER-001')->delete();

        foreach ($catalogoServicios as $servicio) {
            Servicio::updateOrCreate(
                ['codigo' => $servicio['codigo']],
                [
                    'categoria_servicio_id' => $categoriaIds[$servicio['categoria']],
                    'categoria' => $servicio['categoria'],
                    'nombre' => $servicio['descripcion'],
                    'descripcion' => $servicio['descripcion'],
                    'unidad' => $servicio['unidad'],
                    'precio_unitario' => $servicio['precio_unitario'],
                    'iva' => $servicio['iva'],
                    'precio_con_iva' => $servicio['precio_con_iva'],
                    'observaciones' => $servicio['observaciones'],
                    'precio_base' => $servicio['precio_unitario'],
                    'activo' => true,
                ]
            );
        }
    }
}
