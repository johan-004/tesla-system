<x-app-layout>

<div class="max-w-7xl mx-auto p-6">

    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold">Cotizaciones</h1>

        <a href="{{ route('cotizaciones.create') }}"
           class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded">
            Nueva Cotización
        </a>
    </div>

    @if(session('success'))
        <div class="bg-green-100 text-green-700 p-3 rounded mb-4">
            {{ session('success') }}
        </div>
    @endif

    <div class="bg-white shadow rounded-lg overflow-hidden">
        <table class="w-full text-left">
            <thead class="bg-gray-100">
                <tr>
                    <th class="p-3">Item</th>
                    <th class="p-3">Obra</th>
                    <th class="p-3">Fecha</th>
                    <th class="p-3">Total</th>
                    <th class="p-3">Acciones</th>
                </tr>
            </thead>

            <tbody>
                @forelse($cotizaciones as $cotizacion)
                <tr class="border-t">
                    <td class="p-3">{{ $cotizacion->item }}</td>
                    <td class="p-3">{{ $cotizacion->obra }}</td>
                    <td class="p-3">{{ $cotizacion->fecha }}</td>
                    <td class="p-3">${{ number_format($cotizacion->total_costo_unitario, 2) }}</td>

                    <td class="p-3">
                        <a href="{{ route('cotizaciones.show', $cotizacion->id) }}"
                           class="bg-green-500 text-white px-3 py-1 rounded">
                           Ver
                        </a>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="5" class="text-center p-4">
                        No hay cotizaciones registradas
                    </td>
                </tr>
                @endforelse
            </tbody>

        </table>
    </div>

</div>

</x-app-layout>