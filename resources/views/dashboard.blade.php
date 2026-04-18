<x-app-layout>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 text-gray-900">
                    <h1 class="text-2xl font-bold mb-4">Bienvenido al sistema</h1>
                    <p class="mb-6">Selecciona una sección:</p>

                    <div class="space-y-4">
                        <a href="{{ route('web.productos.index') }}" 
                           class="block px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700">
                           Productos
                        </a>

                        <a href="{{ route('cotizaciones.index') }}" 
                           class="block px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700">
                           Cotizaciones
                        </a>

                        <a href="{{ route('profile.edit') }}" 
                           class="block px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700">
                           Perfil
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
